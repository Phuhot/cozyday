import { useEffect, useRef, useState } from 'react'
import { GC, rgb, Color, pt } from '../../art/gc'
import * as T from '../../art/town'
import { paintPet } from '../../art'
import { fitCanvas, petPoseAt, useFrame, useReducedMotion } from '../anim'
import { NATURAL_FUR, SPECIES, SPECIES_BLURB, SPECIES_NAME, type PetAppearance, type PetSpecies } from '../../content/pet'
import { useGame } from '../../app/game'
import { RoomCanvas } from '../RoomCanvas'
import { PetCanvas, PetThumb } from '../PetCanvas'
import { sfx, unlockAudio } from '../../app/sound'
import { Icon } from '../kit'

const SCENE_TEXT: string[] = [
  'Một sáng nọ có lá thư gửi tới: «Thị trấn Cozii đang sáng đèn trở lại. Ghé chơi nhé.»',
  'Ở cuối con đường, một bạn nhỏ đang đợi, tay ôm chiếc chìa khóa.',
  'Căn nhà còn trống trơn, bụi lấp lánh trong nắng. Nhưng giờ đã có hai đứa mình.',
  'Bạn nhỏ đưa bạn một cây nến thơm. Đặt nó lên chỗ đèn trong phòng nhé.',
]
const SCENE_SECONDS = [9, 7, 8, 0]

function readScene(): number {
  try {
    return Math.max(0, Math.min(3, Number(localStorage.getItem('cozii:storyScene') ?? 0) || 0))
  } catch {
    return 0
  }
}
function saveScene(n: number) {
  try {
    localStorage.setItem('cozii:storyScene', String(n))
  } catch {
    /* bỏ qua */
  }
}

/**
 * Cốt truyện mở đầu (khoảng 30–45 giây nếu xem hết). `replay` = xem lại từ Cài đặt (không thao tác dữ liệu).
 * Lần đầu: cảnh 2 là chọn bạn nhỏ + đặt tên (bắt buộc để chơi), cảnh 4 là đặt món quà đầu tiên (thao tác thật).
 */
export function Story({ replay, onDone }: { replay?: boolean; onDone: () => void }) {
  const { state, act } = useGame()
  const onboarded = state.profile.onboarded
  const [scene, setScene] = useState(() => (replay ? 0 : onboarded ? Math.max(2, readScene()) : Math.min(1, readScene())))
  const [choosing, setChoosing] = useState(false)
  const [species, setSpecies] = useState<PetSpecies>('capybara')
  const [placed, setPlaced] = useState(false)
  const start = useRef(performance.now())

  useEffect(() => {
    start.current = performance.now()
    if (!replay) saveScene(scene)
  }, [scene, replay])

  const appearance: PetAppearance = onboarded
    ? { species: state.pet.species, fur: state.pet.fur, stage: 'little', ...state.pet.wear }
    : { species, fur: NATURAL_FUR[species], stage: 'little' }

  const next = () => {
    sfx('tap')
    if (scene === 1 && !onboarded && !replay) {
      setChoosing(true)
      return
    }
    if (scene >= 3 || (replay && scene >= 3)) {
      finish()
      return
    }
    setScene(s => s + 1)
  }

  const finish = () => {
    if (!replay) {
      saveScene(0)
      void act({ type: 'storySeen' }, { quiet: true })
    }
    onDone()
  }

  const skip = () => {
    unlockAudio()
    if (!onboarded && !replay) {
      // Phải chọn bạn nhỏ để bắt đầu — bỏ qua phần kể chuyện, vào thẳng bước chọn.
      setScene(1)
      setChoosing(true)
      return
    }
    finish()
  }

  // Tự chuyển cảnh khi xem (trừ cảnh cần thao tác).
  useEffect(() => {
    const secs = SCENE_SECONDS[scene]
    if (!secs || choosing) return
    const id = setTimeout(() => {
      if (scene === 1 && !onboarded && !replay) setChoosing(true)
      else if (scene < 3) setScene(scene + 1)
    }, secs * 1000)
    return () => clearTimeout(id)
  }, [scene, choosing, onboarded, replay])

  return (
    <div className="story" onClick={() => unlockAudio()}>
      {scene <= 1 && <StoryCanvas scene={scene} appearance={appearance} />}
      {scene >= 2 && (
        <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', padding: 16, background: scene === 2 ? '#3a3350' : '#f6e8d6' }}>
          <div style={{ width: 'min(100%, 520px)', position: 'relative' }}>
            <RoomCanvas
              room="study"
              state={state.home.rooms.study!}
              appearance={appearance}
              mood={placed ? 'happy' : 'idle'}
              petName={state.pet.name || 'Bạn nhỏ'}
              mode={scene === 3 && !placed && !replay ? 'decorate' : 'static'}
              activeSlot={scene === 3 && !placed ? 'lamp' : null}
              preview={replay && scene === 3 ? { slot: 'lamp', placed: { item: 'lamp.candle', flip: false, dx: 0 } } : null}
              onSlotTap={async slot => {
                if (slot !== 'lamp') return
                const r = await act({ type: 'place', room: 'study', slot: 'lamp', item: 'lamp.candle' })
                if (r) {
                  sfx('good')
                  setPlaced(true)
                }
              }}
            />
            <div
              aria-hidden
              style={{
                position: 'absolute', inset: 0, borderRadius: 28, pointerEvents: 'none', transition: 'background 1.6s ease',
                background: scene === 2 ? 'rgba(40,32,60,0.42)' : placed || (replay && scene === 3) ? 'radial-gradient(circle at 78% 48%, rgba(255,214,107,0.32), rgba(255,214,107,0) 60%)' : 'rgba(40,32,60,0.18)',
              }}
            />
          </div>
        </div>
      )}

      <div className="story-skip">
        <button className="btn small" onClick={e => { e.stopPropagation(); skip() }}>Bỏ qua</button>
      </div>

      {!choosing && (
        <div className="story-text" onClick={e => { e.stopPropagation(); if (scene !== 3 || placed || replay) next() }}>
          <p>{scene === 3 && placed ? 'Căn phòng ấm lên một chút. Chào mừng về nhà.' : SCENE_TEXT[scene]}</p>
          <div className="row" style={{ marginTop: 12 }}>
            <div className="story-dots">{[0, 1, 2, 3].map(i => <i key={i} className={i === scene ? 'on' : ''} />)}</div>
            <span className="spacer" />
            {(scene !== 3 || placed || replay) && (
              <button className="btn small" style={{ background: '#fff' }} onClick={e => { e.stopPropagation(); next() }}>
                {scene === 3 ? 'Vào nhà' : 'Tiếp'} <Icon.right />
              </button>
            )}
          </div>
        </div>
      )}

      {choosing && <ChoosePet species={species} setSpecies={setSpecies} onDone={() => { setChoosing(false); setScene(2) }} />}
    </div>
  )
}

function ChoosePet({ species, setSpecies, onDone }: { species: PetSpecies; setSpecies: (s: PetSpecies) => void; onDone: () => void }) {
  const { act } = useGame()
  const [player, setPlayer] = useState('')
  const [petName, setPetName] = useState('')
  const [busy, setBusy] = useState(false)
  const suggestions = ['Bông', 'Mochi', 'Đậu', 'Mây', 'Bơ', 'Kem', 'Sữa', 'Tròn']
  const submit = async () => {
    setBusy(true)
    const r = await act({ type: 'onboard', playerName: player.trim() || 'Bạn', petName: petName.trim() || suggestions[0], species, fur: NATURAL_FUR[species] })
    setBusy(false)
    if (r) {
      sfx('good')
      onDone()
    }
  }
  return (
    <div className="sheet-backdrop" style={{ zIndex: 85 }}>
      <div className="sheet" role="dialog" aria-label="Chọn bạn đồng hành">
        <div className="sheet-handle" />
        <h2 style={{ fontSize: 21, fontWeight: 900, marginBottom: 4 }}>Chọn bạn đồng hành</h2>
        <p className="muted small" style={{ marginBottom: 10 }}>Loài nào cũng miễn phí và không có lợi thế điểm số. Sau này đổi ngoại hình ở Tiệm May.</p>
        <div className="row" style={{ justifyContent: 'center', gap: 14 }}>
          <PetCanvas appearance={{ species, fur: NATURAL_FUR[species], stage: 'little' }} size={132} mood="happy" interactive label={SPECIES_NAME[species]} />
          <div style={{ maxWidth: 190 }}>
            <div className="bold" style={{ fontSize: 18 }}>{SPECIES_NAME[species]}</div>
            <div className="muted small">{SPECIES_BLURB[species]}</div>
          </div>
        </div>
        <div className="grid" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(64px, 1fr))', gap: 6, margin: '10px 0' }}>
          {SPECIES.map(s => (
            <button key={s} className="tile" style={{ minHeight: 84, padding: 4 }} aria-pressed={s === species} onClick={() => { sfx('tap'); setSpecies(s) }}>
              <PetThumb appearance={{ species: s, fur: NATURAL_FUR[s], stage: 'little' }} size={52} label={SPECIES_NAME[s]} />
              <span className="name" style={{ fontSize: 11.5 }}>{SPECIES_NAME[s]}</span>
            </button>
          ))}
        </div>
        <div className="stack" style={{ gap: 8 }}>
          <label className="small bold">Tên của bạn
            <input className="input" value={player} maxLength={20} placeholder="Ví dụ: Mai" onChange={e => setPlayer(e.target.value)} autoComplete="nickname" />
          </label>
          <label className="small bold">Tên bạn nhỏ
            <input className="input" value={petName} maxLength={16} placeholder="Ví dụ: Bông" onChange={e => setPetName(e.target.value)} />
          </label>
          <div className="row wrap">{suggestions.map(s => <button key={s} className="pill" style={{ minHeight: 32, padding: '4px 10px' }} onClick={() => setPetName(s)}>{s}</button>)}</div>
          <button className="btn primary block" disabled={busy} onClick={submit}>Đi cùng nhau</button>
        </div>
      </div>
    </div>
  )
}

function StoryCanvas({ scene, appearance }: { scene: number; appearance: PetAppearance }) {
  const ref = useRef<HTMLCanvasElement>(null)
  const reduce = useReducedMotion()
  const t0 = useRef(performance.now())
  useEffect(() => {
    t0.current = performance.now()
  }, [scene])
  const draw = () => {
    const cv = ref.current
    if (!cv) return
    const w = cv.clientWidth, h = cv.clientHeight
    const c = fitCanvas(cv, w, h)
    const t = reduce ? 6 : (performance.now() - t0.current) / 1000
    const g = new GC(c)
    // Thế giới rộng 100 đơn vị, căn giữa.
    const u = Math.min(w / 100, h / 150)
    if (scene === 0) drawLetter(g, w, h, u, t)
    else drawMeet(g, w, h, u, t, appearance, reduce)
  }
  useFrame(draw, true, reduce ? 4 : 30)
  return <canvas ref={ref} aria-hidden />
}

function drawLetter(g: GC, w: number, h: number, u: number, t: number) {
  const dawn = Math.min(1, t / 6)
  T.sky(g, w, h, rgb(0x2f3260).mix(rgb(0xa9c8ef), dawn), rgb(0x6a5f9e).mix(rgb(0xfcdcc0), dawn))
  for (let i = 0; i < 24; i++) {
    const x = ((i * 37.7) % 100) / 100 * w, y = ((i * 23.3) % 45) / 100 * h
    g.circle(x, y, i % 3 ? 1 : 1.6, Color.white.opacity(0.7 * (1 - dawn)))
  }
  const cx = w / 2
  const horizon = h * 0.52
  g.circle(cx + 28 * u, horizon - 6 * u, 9 * u, rgb(0xffd66b).opacity(dawn))
  T.hill(g, -w * 0.2, w * 0.7, horizon + 4 * u, horizon - 12 * u, rgb(0x9ec49a).mix(rgb(0x5f7a72), 1 - dawn))
  T.hill(g, w * 0.3, w * 1.2, horizon + 6 * u, horizon - 8 * u, rgb(0xb6d6a8).mix(rgb(0x6b8580), 1 - dawn))
  g.rect(0, horizon + 4 * u, w, h, rgb(0xb8e0a2).mix(rgb(0x5d7d6a), 1 - dawn))
  // Thị trấn nhỏ ở chân trời, đèn sáng dần.
  for (let i = 0; i < 5; i++) {
    const x = cx - 22 * u + i * 11 * u
    const lit = Math.max(0, Math.min(1, (t - 2 - i * 0.6) / 0.8))
    T.house(g, x, horizon + 2 * u, 9 * u, { wall: rgb([0xfbefe0, 0xf3e9f7, 0xe4efe2, 0xfbe7de, 0xf8edd3][i]), roof: rgb([0xd9667a, 0x8d78cf, 0x6f9a72, 0xe59a7a, 0xd9a441][i]), door: rgb(0xa07448), lit })
  }
  // Con đường uốn tới thị trấn.
  T.road(g, [[cx, h], [cx - 18 * u, h * 0.82], [cx + 10 * u, h * 0.66], [cx, horizon + 4 * u]], 9 * u)
  for (let i = 0; i < 6; i++) T.bush(g, cx + (i % 2 ? 26 : -30) * u + i * 2 * u, h * (0.62 + i * 0.06), 1.4 * u)
  // Lá thư bay tới rồi mở ra.
  const fly = Math.min(1, t / 2)
  const ex = cx + (1 - fly) * 40 * u, ey = h * 0.3 - (1 - fly) * 30 * u + Math.sin(t * 2) * 1.5 * u
  const open = Math.max(0, Math.min(1, (t - 2.2) / 1.2))
  T.envelope(g, ex, ey, 34 * u, open)
  if (open > 0.6) T.sparkle(g, ex + 20 * u, ey - 18 * u, 6 * u, rgb(0xffe08a).opacity(open))
}

function drawMeet(g: GC, w: number, h: number, u: number, t: number, a: PetAppearance, reduce: boolean) {
  T.sky(g, w, h, rgb(0xbfe0f5), rgb(0xfdebdd))
  T.cloud(g, w * 0.1, h * 0.1, 1.6 * u, Color.white.opacity(0.9))
  T.cloud(g, w * 0.62, h * 0.16, 1.2 * u, Color.white.opacity(0.85))
  const cx = w / 2
  const ground = h * Math.min(0.66, 0.42 + (w / h) * 0.3)
  T.hill(g, -w * 0.3, w * 0.8, ground, ground - 22 * u, rgb(0xb9ddb0))
  T.hill(g, w * 0.2, w * 1.3, ground, ground - 14 * u, rgb(0xa3d19c))
  g.rect(0, ground, w, h, rgb(0xb8e0a2))
  T.road(g, [[cx, h], [cx + 6 * u, ground + 18 * u], [cx, ground + 2 * u]], 14 * u)
  T.house(g, cx + 26 * u, ground + 2 * u, 22 * u, { wall: rgb(0xfdf6ec), roof: rgb(0xa58bd9), door: rgb(0xc89b6d), lit: 0 })
  T.tree(g, cx - 32 * u, ground + 6 * u, 1.8 * u)
  T.lamp(g, cx - 12 * u, ground + 8 * u, 1.6 * u, 0.4)
  // Bạn nhỏ cầm chìa khóa.
  const size = 46 * u
  const enter = reduce ? 1 : Math.min(1, t / 1.4)
  const px = cx - size / 2 - (1 - enter) * 30 * u
  const py = ground + 26 * u - size
  const pose = petPoseAt(t, 'happy', { hopAt: 1.6, heartsAt: 2.4, walking: enter < 1 }, reduce)
  paintPet(g.ctx, px, py, size, a, 'happy', pose)
  T.key(g, px + size * 0.78, py + size * 0.62, 1.4 * u, -20 + Math.sin(t * 3) * 6)
  if (t > 2) T.sparkle(g, px + size * 0.95, py + size * 0.45, 7 * u, rgb(0xf0c26a).opacity(Math.min(1, t - 2)))
  void pt
}
