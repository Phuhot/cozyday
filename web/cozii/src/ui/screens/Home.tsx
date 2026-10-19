import { useEffect, useMemo, useRef, useState } from 'react'
import { useGame } from '../../app/game'
import { go } from '../../app/router'
import { ROOMS, room as roomDef, type RoomId } from '../../content/catalog'
import { ECONOMY } from '../../content/economy'
import { FOODS, food as foodDef } from '../../content/farm'
import { CLEAN_LINES, CUDDLE_DONE, FED_LINES, PETTED_LINES, talkLines } from '../../content/dialogue'
import { needsAt } from '../../core/engine'
import { petStage, rankOf, readyAt } from '../../core/state'
import type { PetAppearance, PetMood } from '../../content/pet'
import { RoomCanvas, type Dirt } from '../RoomCanvas'
import { Icon, ItemThumb, Sheet, Empty } from '../kit'
import { sfx } from '../../app/sound'
import { useTutorial } from '../../app/tutorial'
import { CHAPTERS } from '../../content/town'
import { DailyCard } from './Hall'
import { MailSheet } from './Mail'

export function petAppearance(s: ReturnType<typeof useGame>['state']): PetAppearance {
  return { species: s.pet.species, fur: s.pet.fur, stage: petStage(s.pet.affection), ...s.pet.wear }
}

function lastRoom(): RoomId {
  try {
    const v = localStorage.getItem('cozii:room') as RoomId | null
    return v && ROOMS.some(r => r.id === v) ? v : 'study'
  } catch {
    return 'study'
  }
}

export function Home() {
  const { state, act, serverNow, toast } = useGame()
  const rank = rankOf(state)
  const [roomId, setRoomId] = useState<RoomId>(() => {
    const r = lastRoom()
    return roomDef(r).rank <= rankOf(state) ? r : 'study'
  })
  const [bubble, setBubble] = useState<string | null>(null)
  const [sheet, setSheet] = useState<null | 'feed' | 'mail'>(null)
  const [cleaning, setCleaning] = useState<Dirt[] | null>(null)
  const taps = useRef(0)
  const petTaps = useRef(0)
  const cuddle = useRef({ acc: 0, last: 0, said: 0 })
  const bubbleTimer = useRef<number | null>(null)
  const { step } = useTutorial()

  useEffect(() => {
    try {
      localStorage.setItem('cozii:room', roomId)
    } catch { /* bỏ qua */ }
  }, [roomId])

  const now = serverNow()
  const needs = needsAt(state.pet.needs, now)
  const c = ECONOMY.care
  const mood: PetMood = needs.fullness < c.needsCareBelow || needs.happiness < c.needsCareBelow || needs.cleanliness < c.needsCareBelow ? 'low' : needs.happiness >= 80 ? 'happy' : 'idle'
  const appearance = petAppearance(state)
  const readyCrops = state.farm.plots.filter(p => p.crop && now >= readyAt(p)).length
  const growing = state.farm.plots.filter(p => p.crop && now < readyAt(p)).length

  const say = (text: string, ms = 2800) => {
    setBubble(text)
    if (bubbleTimer.current) clearTimeout(bubbleTimer.current)
    bubbleTimer.current = window.setTimeout(() => setBubble(null), ms)
  }

  const lines = useMemo(() => talkLines({
    hour: new Date().getHours(), playerName: state.profile.name,
    hungry: needs.fullness < c.needsCareBelow, dirty: needs.cleanliness < c.needsCareBelow, bored: needs.happiness < c.needsCareBelow,
    readyCrops, growing,
  }, state.pet.species), [state.profile.name, state.pet.species, needs.fullness, needs.cleanliness, needs.happiness, readyCrops, growing, c.needsCareBelow])

  const onPetTap = () => {
    say(lines[taps.current % lines.length])
    taps.current += 1
  }

  const onStroke = () => {
    const t = performance.now() / 1000
    const cu = cuddle.current
    const gap = t - cu.last
    cu.last = t
    if (gap < 0.25) cu.acc += gap
    if (t - cu.said > 1.6) {
      cu.said = t
      say(PETTED_LINES[petTaps.current++ % PETTED_LINES.length], 1600)
    }
    if (cu.acc >= c.cuddleSeconds) {
      cu.acc = 0
      void act({ type: 'cuddle' }).then(r => {
        if (!r) return
        const rw = (r as { reward?: { coins: number; affection: number } }).reward
        say(CUDDLE_DONE[Math.floor(Math.random() * CUDDLE_DONE.length)])
        sfx('good')
        if (rw && (rw.coins || rw.affection)) toast(`Nựng xong! ${rw.affection ? `+${rw.affection} thân thiết` : ''}${rw.coins ? ` · +${rw.coins} xu` : ''}`, 'good')
      })
    }
  }

  const startCleaning = () => {
    if (needs.cleanliness >= c.cleanEnough) {
      say('Nhà đang sạch bong rồi nè!')
      return
    }
    const n = Math.max(3, Math.min(10, Math.round((100 - needs.cleanliness) / 8)))
    const kinds: Dirt['kind'][] = ['dust', 'leaf', 'paper', 'web', 'mud']
    const spots: Dirt[] = []
    for (let i = 0; i < n; i++) {
      const kind = kinds[(i * 7 + roomId.length) % kinds.length]
      const y = kind === 'web' ? 6 + ((i * 13) % 20) : 66 + ((i * 17) % 28)
      spots.push({ id: i, x: 8 + ((i * 37 + 11) % 108), y, kind, hp: 60 })
    }
    setCleaning(spots)
    say('Chà vào vết bẩn để dọn nhé!')
  }

  const onScrub = (id: number, amount: number) => {
    setCleaning(prev => {
      if (!prev) return prev
      const next = prev.map(d => (d.id === id ? { ...d, hp: d.hp - amount } : d)).filter(d => d.hp > 0)
      if (next.length < prev.length) sfx('swish')
      if (next.length === 0) {
        void act({ type: 'clean' }).then(r => {
          if (!r) return
          const rw = (r as { reward?: { coins: number; affection: number } }).reward
          sfx('good')
          say(CLEAN_LINES[Math.floor(Math.random() * CLEAN_LINES.length)])
          if (rw && (rw.coins || rw.affection)) toast(`Dọn xong!${rw.affection ? ` +${rw.affection} thân thiết` : ''}${rw.coins ? ` · +${rw.coins} xu` : ''}`, 'good')
        })
        return null
      }
      return next
    })
  }

  const tutorialHint = (id: string) => step?.id === id
  const roomState = state.home.rooms[roomId]!

  return (
    <div className="wide-2">
      <div className="stack">
        <div className="pill-tabs" role="tablist" aria-label="Các phòng">
          {ROOMS.map(r => {
            const locked = r.rank > rank
            return (
              <button
                key={r.id}
                className="pill"
                role="tab"
                aria-pressed={r.id === roomId}
                aria-selected={r.id === roomId}
                onClick={() => {
                  sfx('tap')
                  if (locked) {
                    const ch = CHAPTERS[r.rank - 2]
                    toast(`${r.name} mở khi đóng dấu chương “${ch?.name ?? ''}” trong hộ chiếu.`)
                    return
                  }
                  setCleaning(null)
                  setRoomId(r.id)
                }}
              >
                {r.name}{locked && <span className="lock">🔒</span>}
              </button>
            )
          })}
        </div>
        <RoomCanvas
          room={roomId}
          state={roomState}
          appearance={appearance}
          mood={cleaning ? 'idle' : mood}
          petName={state.pet.name}
          mode={cleaning ? 'clean' : 'live'}
          bubble={bubble}
          onPetTap={onPetTap}
          onStroke={onStroke}
          dirt={cleaning ?? undefined}
          onScrub={onScrub}
        />
        {cleaning ? (
          <div className="card row">
            <Icon.broom />
            <span className="bold small" style={{ flex: 1 }}>Còn {cleaning.length} vết bẩn. Chà ngón tay (hoặc kéo chuột) qua từng vết.</span>
            <button className="btn small" onClick={() => setCleaning(null)}>Thôi</button>
          </div>
        ) : (
          <p className="muted tiny center">Chạm {state.pet.name} để trò chuyện · vuốt qua lại để nựng · giữ rồi kéo để đổi chỗ</p>
        )}
      </div>

      <div className="stack">
        <Needs needs={needs} />
        <div className="dock">
          <button className={'dock-btn' + (tutorialHint('feed') ? ' hint' : '')} onClick={() => { sfx('tap'); setSheet('feed') }}><Icon.food />Cho ăn</button>
          <button className="dock-btn" onClick={() => { sfx('tap'); startCleaning() }}><Icon.broom />Dọn nhà</button>
          <button className={'dock-btn' + (tutorialHint('place') ? ' hint' : '')} onClick={() => { sfx('tap'); go(`home/decorate/${roomId}`) }}><Icon.brush />Trang trí</button>
          <button className="dock-btn" onClick={() => { sfx('tap'); go('home/wardrobe') }}><Icon.shirt />Tủ đồ</button>
          <button className={'dock-btn' + (tutorialHint('plant') || tutorialHint('harvest') ? ' hint' : '')} onClick={() => { sfx('tap'); go('farm') }}>
            <Icon.sprout />Vườn rau{readyCrops > 0 && <span className="badge honey">{readyCrops} chín</span>}
          </button>
          <button className="dock-btn" onClick={() => { sfx('tap'); go(`photo/${roomId}`) }}><Icon.camera />Chụp ảnh</button>
          <button className="dock-btn" onClick={() => { sfx('tap'); setSheet('mail') }}><Icon.mail />Hộp thư</button>
          <button className="dock-btn" onClick={() => { sfx('tap'); go('place/hall') }}><Icon.book />Hộ chiếu</button>
        </div>
        <DailyCard compact />
      </div>

      {sheet === 'feed' && <FeedSheet onClose={() => setSheet(null)} onFed={line => { say(line); setSheet(null) }} hungry={needs.fullness < c.needsCareBelow} full={needs.fullness >= c.fullEnough} />}
      {sheet === 'mail' && <MailSheet onClose={() => setSheet(null)} />}
    </div>
  )
}

function Needs({ needs }: { needs: { fullness: number; cleanliness: number; happiness: number } }) {
  const items = [
    { key: 'fullness', label: 'No bụng', v: needs.fullness, color: '#e59a7a', icon: <Icon.food /> },
    { key: 'cleanliness', label: 'Nhà sạch', v: needs.cleanliness, color: '#6fb3c9', icon: <Icon.sparkle /> },
    { key: 'happiness', label: 'Vui vẻ', v: needs.happiness, color: '#d9667a', icon: <Icon.heart /> },
  ]
  return (
    <div className="needs" aria-label="Nhu cầu của bạn nhỏ">
      {items.map(n => (
        <div key={n.key} className="need" title={`${n.label}: ${Math.round(n.v)}/100`}>
          <span style={{ color: n.color }}>{n.icon}</span>
          <div style={{ flex: 1 }}>
            <div className="tiny bold muted">{n.label}</div>
            <div className="bar"><i style={{ width: `${n.v}%`, background: n.color }} /></div>
          </div>
          <span className="sr-only">{Math.round(n.v)} trên 100</span>
        </div>
      ))}
    </div>
  )
}

function FeedSheet({ onClose, onFed, hungry, full }: { onClose: () => void; onFed: (line: string) => void; hungry: boolean; full: boolean }) {
  const { state, act, toast } = useGame()
  const foods = FOODS.filter(f => (state.stock[f.id] ?? 0) > 0)
  const feed = async (id: string) => {
    const r = await act({ type: 'feed', food: id })
    if (!r) return
    sfx('good')
    const rw = (r as { reward?: { coins: number; affection: number } }).reward
    if (rw && (rw.coins || rw.affection)) toast(`${foodDef(id)?.name}!${rw.affection ? ` +${rw.affection} thân thiết` : ''}${rw.coins ? ` · +${rw.coins} xu` : ''}`, 'good')
    onFed(FED_LINES[Math.floor(Math.random() * FED_LINES.length)])
  }
  return (
    <Sheet title="Cho ăn" onClose={onClose}>
      <div className="stack">
        {full && <div className="card small">{state.pet.name} đang no. Đồ ăn chỉ bị dùng khi bạn nhỏ còn chỗ trong bụng.</div>}
        {foods.length === 0 ? (
          <Empty>Hết đồ ăn rồi. Mua ở Tiệm Bánh, hoặc nấu từ nông sản nhà trồng.</Empty>
        ) : (
          <div className="grid">
            {foods.map(f => (
              <button key={f.id} className="tile" onClick={() => void feed(f.id)} disabled={full}>
                <ItemThumb id={f.id} size={60} label={f.name} />
                <span className="name">{f.name}</span>
                <span className="muted tiny">+{f.fullness} no{f.happiness ? ` · +${f.happiness} vui` : ''}</span>
                <span className="tag badge gray">×{state.stock[f.id]}</span>
              </button>
            ))}
          </div>
        )}
        {hungry && (
          <button className="btn sage block" onClick={async () => {
            const r = await act({ type: 'freeMeal' })
            if (r) onFed('Bữa cơ bản cũng ngon lắm, cảm ơn nha!')
          }}>Bữa cơ bản miễn phí</button>
        )}
        <button className="btn block" onClick={() => { onClose(); go('place/bakery') }}>Tới Tiệm Bánh</button>
      </div>
    </Sheet>
  )
}
