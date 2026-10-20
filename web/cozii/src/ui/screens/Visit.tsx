import { useEffect, useMemo, useRef, useState } from 'react'
import { useGame } from '../../app/game'
import { back } from '../../app/router'
import { NPC_HOMES, STICKERS, REPORT_REASONS, npc } from '../../content/town'
import { item as catalogItem, ROOMS, type RoomId } from '../../content/catalog'
import { crop as cropDef } from '../../content/farm'
import type { HomeSnapshot } from '../../core/snapshot'
import type { VisitResult } from '../../backend/types'
import { VISIT_LOCAL_LINES, PETTED_LINES } from '../../content/dialogue'
import { RoomCanvas } from '../RoomCanvas'
import { drawCrop, Empty, Icon, ItemThumb, ScreenHead, Sheet } from '../kit'
import { GC, rgb } from '../../art/gc'
import { fitCanvas } from '../anim'
import { sourceText } from './Decorate'
import { sfx } from '../../app/sound'
import { uuid } from '../../backend/local'

export function npcSnapshot(id: string): HomeSnapshot | null {
  const h = NPC_HOMES.find(x => x.npc === id)
  if (!h) return null
  const n = npc(id)
  return {
    v: 1, name: n.name, title: 'Nhà mẫu NPC', badges: [],
    pet: { name: n.name, species: n.look.species, fur: n.look.fur, wear: { hat: n.look.hat ?? undefined, glasses: n.look.glasses ?? undefined, neck: n.look.neck ?? undefined, outfit: n.look.outfit ?? undefined, back: n.look.back ?? undefined }, stage: n.look.stage },
    rooms: [{ id: h.room, theme: h.theme, slots: Object.fromEntries(Object.entries(h.slots).map(([k, v]) => [k, { item: v!, flip: false, dx: 0 }])) }],
    garden: h.garden.map((g, idx) => ({ idx, crop: g.crop, progress: g.stage / 3, helps: 0 })),
    showSources: true,
    publishedAt: 0,
  }
}

export function Visit({ target }: { target: string }) {
  const { state, act, social, toast, reload } = useGame()
  const isNpc = target.startsWith('npc:')
  const npcId = isNpc ? target.slice(4) : null
  const [remote, setRemote] = useState<VisitResult | null>(null)
  const [error, setError] = useState<string | null>(null)
  const visited = useRef(false)
  const sending = useRef(false)

  useEffect(() => {
    if (visited.current) return
    visited.current = true
    if (npcId) void act({ type: 'visitNpc', npc: npcId }, { quiet: true })
    else if (social) social.visit(target).then(r => { setRemote(r); if (r.coins) { toast(`Quà ghé thăm: +${r.coins} xu`, 'good'); void reload() } }).catch(e => setError(e instanceof Error ? e.message : 'Không mở được ngôi nhà này.'))
    else setError('Thăm nhà bạn bè cần tài khoản online.')
  }, [npcId, social, target, act, toast, reload])

  const snap = npcId ? npcSnapshot(npcId) : remote?.snapshot ?? null
  if (error) return <div className="stack"><ScreenHead title="Thăm nhà" onBack={() => back('friends')} /><Empty>{error}</Empty></div>
  if (!snap) return <div className="stack"><ScreenHead title="Thăm nhà" onBack={() => back('friends')} /><div className="card small muted">Đang mở cửa…</div></div>

  const complimented = npcId ? (state.caps[`${new Date(Date.now() + 7 * 3600e3).toISOString().slice(0, 10)}|compliment:npc:${npcId}`] ?? 0) > 0 : !!remote?.complimentedToday
  const compliment = async (sticker: string) => {
    sfx('pop')
    if (npcId) {
      if (await act({ type: 'npcCompliment', npc: npcId, sticker })) toast('Đã gửi lời khen!', 'good')
      return
    }
    if (sending.current) return
    sending.current = true
    try {
      await social!.compliment(target, sticker)
      setRemote(r => (r ? { ...r, complimentedToday: sticker } : r))
      toast('Đã gửi lời khen!', 'good')
    } catch (e) {
      toast(e instanceof Error ? e.message : 'Không gửi được.', 'warn')
    } finally {
      sending.current = false
    }
  }
  const helpWater = async (idx: number) => {
    sfx('water')
    if (npcId) {
      if (await act({ type: 'npcHelpWater', npc: npcId })) toast(`${npc(npcId).name} cảm ơn bạn đã tưới giúp!`, 'good')
      return
    }
    if (sending.current) return
    sending.current = true
    try {
      const r = await social!.helpWater(target, idx, uuid())
      setRemote(v => (v ? { ...v, helpedPlots: [...v.helpedPlots, idx], helpsLeftToday: Math.max(0, v.helpsLeftToday - 1) } : v))
      toast(r.coins ? `Tưới giúp xong! +${r.coins} xu` : 'Tưới giúp xong!', 'good')
      if (r.coins) void reload()
    } catch (e) {
      toast(e instanceof Error ? e.message : 'Không tưới được.', 'warn')
    } finally {
      sending.current = false
    }
  }

  return (
    <SnapshotView
      snap={snap}
      isNpc={!!npcId}
      hostId={npcId ? null : target}
      isFriend={!!remote?.isFriend}
      complimented={complimented}
      onCompliment={compliment}
      helped={npcId ? ((state.caps[`${new Date(Date.now() + 7 * 3600e3).toISOString().slice(0, 10)}|help:npc:${npcId}`] ?? 0) > 0 ? snap.garden?.map(g => g.idx) ?? [] : []) : remote?.helpedPlots ?? []}
      canHelp={npcId ? true : !!remote?.isFriend && (remote?.helpsLeftToday ?? 0) > 0}
      onHelp={helpWater}
      coins={remote?.coins ?? 0}
    />
  )
}

export function SnapshotView({ snap, isNpc, hostId, isFriend, complimented, onCompliment, helped, canHelp, onHelp, coins, preview }: {
  snap: HomeSnapshot; isNpc: boolean; hostId: string | null; isFriend: boolean; complimented: boolean | string
  onCompliment?: (s: string) => void; helped: number[]; canHelp: boolean; onHelp?: (idx: number) => void; coins: number; preview?: boolean
}) {
  const { social, toast } = useGame()
  const [roomId, setRoomId] = useState<RoomId>(snap.rooms[0]?.id ?? 'study')
  const [bubble, setBubble] = useState<string | null>(null)
  const [items, setItems] = useState(false)
  const [report, setReport] = useState(false)
  const taps = useRef(0)
  const room = snap.rooms.find(r => r.id === roomId) ?? snap.rooms[0]
  const appearance = useMemo(() => ({ species: snap.pet.species, fur: snap.pet.fur, stage: snap.pet.stage, ...snap.pet.wear }), [snap])

  useEffect(() => {
    if (coins > 0) toast(`Ghé thăm lần đầu hôm nay: +${coins} xu`, 'good')
  }, [coins, toast])

  return (
    <div className="wide-2">
      <div className="stack">
        <ScreenHead
          title={preview ? 'Xem trước nhà bạn' : `Nhà ${isNpc ? npc(hostId ?? '')?.name ?? snap.name : snap.name}`}
          onBack={() => back('friends')}
          right={isNpc ? <span className="badge peach">Nhà mẫu NPC</span> : snap.title ? <span className="badge">{snap.title}</span> : undefined}
        />
        {isNpc && <p className="small muted">Đây là nhà mẫu do thị trấn dựng sẵn, không phải người chơi thật. {NPC_HOMES.find(h => npc(h.npc).name === snap.name)?.note ?? ''}</p>}
        {snap.rooms.length > 1 && (
          <div className="pill-tabs">{snap.rooms.map(r => <button key={r.id} className="pill" aria-pressed={r.id === roomId} onClick={() => setRoomId(r.id)}>{ROOMS.find(x => x.id === r.id)?.name}</button>)}</div>
        )}
        {room && (
          <RoomCanvas
            room={room.id}
            state={{ theme: room.theme, slots: room.slots }}
            appearance={appearance}
            mood="happy"
            petName={snap.pet.name}
            mode="visit"
            bubble={bubble}
            onPetTap={() => {
              setBubble(VISIT_LOCAL_LINES[taps.current++ % VISIT_LOCAL_LINES.length])
              setTimeout(() => setBubble(null), 2400)
            }}
            onStroke={() => { if (Math.random() < 0.05) setBubble(PETTED_LINES[taps.current++ % PETTED_LINES.length]) }}
          />
        )}
        <p className="tiny muted center">Chạm hay vuốt {snap.pet.name} chỉ tạo biểu cảm trên máy bạn, không đổi chỉ số của chủ nhà.</p>
      </div>
      <div className="stack">
        {!preview && (
          <div className="card stack" style={{ gap: 8 }}>
            <b>Gửi một lời khen</b>
            {complimented ? <div className="small muted">Bạn đã khen nhà này hôm nay. Mai ghé lại nhé.</div> : (
              <div className="row wrap">{STICKERS.map(s => <button key={s.id} className="pill" onClick={() => onCompliment?.(s.id)}>{s.emoji} {s.text}</button>)}</div>
            )}
          </div>
        )}
        <div className="card stack" style={{ gap: 8 }}>
          <b>Vườn</b>
          {snap.garden == null ? <div className="small muted">Chủ nhà không chia sẻ vườn.</div> : snap.garden.length === 0 ? <div className="small muted">Vườn đang trống.</div> : (
            <div className="farm-grid" style={{ gridTemplateColumns: 'repeat(4, 1fr)' }}>
              {snap.garden.map(g => {
                const done = helped.includes(g.idx)
                const can = !preview && canHelp && !done && g.progress < 1
                return (
                  <button key={g.idx} className="plot" disabled={!can} onClick={() => can && onHelp?.(g.idx)} aria-label={`${cropDef(g.crop)?.name}${can ? ', chạm để tưới giúp' : ''}`}>
                    <MiniCrop crop={g.crop} progress={g.progress} />
                    <span className="plot-label" style={{ fontSize: 10 }}>{done ? 'Đã tưới' : g.progress >= 1 ? 'Chín' : can ? 'Tưới' : cropDef(g.crop)?.name}</span>
                  </button>
                )
              })}
            </div>
          )}
          {!preview && !isNpc && !isFriend && snap.garden && <div className="tiny muted">Chỉ bạn bè mới tưới giúp được.</div>}
          {!preview && <div className="tiny muted">Tưới giúp: mỗi cây tối đa 2 lượt từ bạn bè, mỗi lượt nhanh hơn 10%. Bạn được tưới giúp tối đa 3 lần mỗi ngày.</div>}
        </div>
        {snap.showSources && <button className="btn" onClick={() => setItems(true)}>Xem các món trang trí</button>}
        {!isNpc && !preview && hostId && social && (
          <div className="row">
            <button className="btn small" onClick={() => setReport(true)}><Icon.flag />Báo cáo</button>
            <button className="btn small" onClick={async () => {
              if (!confirm('Chặn người này? Họ sẽ không xem được nhà bạn và bạn cũng không thấy nhà họ.')) return
              try { await social.block(hostId); toast('Đã chặn.', 'good'); back('friends') } catch (e) { toast(e instanceof Error ? e.message : 'Lỗi', 'warn') }
            }}><Icon.ban />Chặn</button>
          </div>
        )}
      </div>
      {items && room && (
        <Sheet title="Đồ trong phòng" onClose={() => setItems(false)}>
          <div className="list">
            {[room.theme, ...Object.values(room.slots).map(s => s!.item)].map(id => {
              const it = catalogItem(id)
              if (!it) return null
              return <div key={id} className="list-item"><ItemThumb id={id} size={44} /><div style={{ flex: 1 }} className="small"><b>{it.name}</b><div className="tiny muted">{sourceText(it)}</div></div></div>
            })}
          </div>
        </Sheet>
      )}
      {report && hostId && <ReportSheet userId={hostId} onClose={() => setReport(false)} />}
    </div>
  )
}

function MiniCrop({ crop, progress }: { crop: string; progress: number }) {
  const ref = useRef<HTMLCanvasElement>(null)
  useEffect(() => {
    const cv = ref.current
    if (!cv) return
    const s = cv.clientWidth || 70
    const c = fitCanvas(cv, s, s)
    const g = new GC(c)
    g.scaleBy(s / 100, s / 100)
    for (let i = 0; i < 3; i++) g.rect(10, 30 + i * 20, 80, 9, rgb(0xb48f66).opacity(0.55), 4.5)
    drawCrop(g, crop, 50, 82, progress, 1.1)
  }, [crop, progress])
  return <canvas ref={ref} aria-hidden />
}

export function ReportSheet({ userId, onClose }: { userId: string; onClose: () => void }) {
  const { social, toast } = useGame()
  const [reason, setReason] = useState<string>(REPORT_REASONS[0].id)
  const [details, setDetails] = useState('')
  return (
    <Sheet title="Báo cáo" onClose={onClose}>
      <div className="stack">
        <p className="small muted">Báo cáo được lưu để người quản lý thị trấn xem xét. Người bị báo cáo không biết ai báo cáo.</p>
        <div className="row wrap">{REPORT_REASONS.map(r => <button key={r.id} className="pill" aria-pressed={reason === r.id} onClick={() => setReason(r.id)}>{r.text}</button>)}</div>
        <textarea className="input" rows={3} maxLength={300} placeholder="Ghi chú (không bắt buộc)" value={details} onChange={e => setDetails(e.target.value)} />
        <button className="btn primary" onClick={async () => {
          try { await social!.report(userId, reason, details); toast('Đã gửi báo cáo. Cảm ơn bạn.', 'good'); onClose() } catch (e) { toast(e instanceof Error ? e.message : 'Lỗi', 'warn') }
        }}>Gửi báo cáo</button>
      </div>
    </Sheet>
  )
}
