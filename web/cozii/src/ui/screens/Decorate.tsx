import { useMemo, useState } from 'react'
import { useGame } from '../../app/game'
import { back } from '../../app/router'
import { itemsIn, MAX_NUDGE, room as roomDef, ROOMS, SLOT_LABEL, type CatalogItem, type ItemSlot, type RoomId } from '../../content/catalog'
import { ECONOMY } from '../../content/economy'
import { rankOf, type PlacedItem } from '../../core/state'
import { RoomCanvas } from '../RoomCanvas'
import { Coins, Icon, ItemThumb, ScreenHead, Sheet } from '../kit'
import { petAppearance } from './Home'
import { sfx } from '../../app/sound'
import { seriesOfItem } from '../../content/capsule'

export function sourceText(it: CatalogItem): string {
  if (it.source === 'starter') return 'Có sẵn khi mở phòng'
  if (it.source === 'shop') return `Tiệm ${it.slot === 'species' || it.slot === 'fur' || ['hat', 'glasses', 'neck', 'outfit', 'back'].includes(it.slot) ? 'May Mây' : 'Nội Thất'} · ${it.price} xu`
  if (it.source === 'capsule') return `Máy capsule · bộ ${seriesOfItem(it.id)?.series.name ?? ''}`
  return 'Quà hoàn thành bộ capsule'
}

/** Chế độ Trang trí: tách khỏi vuốt ve pet; chạm một vị trí để chọn đồ, xem thử trước khi mua. */
export function Decorate({ roomId }: { roomId: RoomId }) {
  const { state, act, toast } = useGame()
  const rank = rankOf(state)
  const def = roomDef(roomId) ?? ROOMS[0]
  const rs = state.home.rooms[def.id]!
  const [slot, setSlot] = useState<ItemSlot | 'theme'>(def.slots[0])
  const [preview, setPreview] = useState<{ slot: ItemSlot; placed: PlacedItem | null } | null>(null)
  const [previewTheme, setPreviewTheme] = useState<string | null>(null)
  const [layouts, setLayouts] = useState(false)

  const activeSlot = slot === 'theme' ? def.themeSlot : slot
  const options = useMemo(() => itemsIn(activeSlot).filter(i => i.rank <= rank + 1 || state.owned.includes(i.id)), [activeSlot, rank, state.owned])
  const current = slot === 'theme' ? rs.theme : rs.slots[slot as ItemSlot]?.item
  const placed = slot !== 'theme' ? rs.slots[slot as ItemSlot] : undefined
  const selectedId = slot === 'theme' ? previewTheme ?? rs.theme : preview?.slot === slot ? preview.placed?.item : current
  const selected = options.find(o => o.id === selectedId)
  const owned = (id: string) => state.owned.includes(id)

  if (def.rank > rank) {
    return <div className="stack"><ScreenHead title="Trang trí" onBack={() => back('home')} /><div className="card">Phòng này chưa mở.</div></div>
  }

  const pick = async (it: CatalogItem) => {
    sfx('tap')
    if (slot === 'theme') {
      if (owned(it.id)) {
        setPreviewTheme(null)
        await act({ type: 'theme', room: def.id, item: it.id })
      } else setPreviewTheme(it.id)
      return
    }
    if (owned(it.id)) {
      setPreview(null)
      const ok = await act({ type: 'place', room: def.id, slot: slot as ItemSlot, item: it.id, flip: placed?.flip ?? false, dx: placed?.dx ?? 0 })
      if (ok) sfx('pop')
    } else setPreview({ slot: slot as ItemSlot, placed: { item: it.id, flip: placed?.flip ?? false, dx: placed?.dx ?? 0 } })
  }

  const buy = async (it: CatalogItem) => {
    const r = await act({ type: 'buyItem', item: it.id })
    if (!r) return
    sfx('coin')
    toast(`Đã mua ${it.name}!`, 'good')
    if (slot === 'theme') {
      setPreviewTheme(null)
      await act({ type: 'theme', room: def.id, item: it.id })
    } else {
      setPreview(null)
      await act({ type: 'place', room: def.id, slot: slot as ItemSlot, item: it.id, flip: placed?.flip ?? false, dx: placed?.dx ?? 0 })
    }
  }

  const adjust = async (patch: Partial<PlacedItem>) => {
    if (!placed) return
    const next = { ...placed, ...patch }
    next.dx = Math.max(-MAX_NUDGE, Math.min(MAX_NUDGE, next.dx))
    await act({ type: 'place', room: def.id, slot: slot as ItemSlot, item: next.item, flip: next.flip, dx: next.dx }, { quiet: true })
  }

  return (
    <div className="wide-2">
      <div className="stack">
        <ScreenHead title={`Trang trí · ${def.name}`} onBack={() => back('home')} right={<button className="btn small" onClick={() => setLayouts(true)}><Icon.save />Bố cục</button>} />
        <RoomCanvas
          room={def.id}
          state={rs}
          appearance={petAppearance(state)}
          mood="idle"
          petName={state.pet.name}
          mode="decorate"
          activeSlot={slot === 'theme' ? null : (slot as ItemSlot)}
          onSlotTap={s => { setSlot(s); setPreview(null) }}
          preview={preview}
          previewTheme={previewTheme}
          hidePet
        />
        <p className="muted tiny center">Chạm ô nét đứt trong phòng để chọn vị trí. Đồ chưa có sẽ được đặt thử, chưa trừ xu.</p>
      </div>
      <div className="stack">
        <div className="pill-tabs">
          <button className="pill" aria-pressed={slot === 'theme'} onClick={() => { setSlot('theme'); setPreview(null) }}>{SLOT_LABEL[def.themeSlot]}</button>
          {def.slots.map(s => <button key={s} className="pill" aria-pressed={slot === s} onClick={() => { setSlot(s); setPreview(null); setPreviewTheme(null) }}>{SLOT_LABEL[s]}</button>)}
        </div>
        {slot !== 'theme' && placed && !preview && (
          <div className="card row wrap" style={{ padding: 10 }}>
            <span className="small bold" style={{ flex: 1 }}>Chỉnh món đang đặt</span>
            <button className="btn small" onClick={() => adjust({ dx: placed.dx - 1.5 })} aria-label="Dịch sang trái" disabled={placed.dx <= -MAX_NUDGE}><Icon.left /></button>
            <button className="btn small" onClick={() => adjust({ dx: placed.dx + 1.5 })} aria-label="Dịch sang phải" disabled={placed.dx >= MAX_NUDGE}><Icon.right /></button>
            <button className="btn small" onClick={() => adjust({ flip: !placed.flip })} aria-label="Lật ngang"><Icon.flip /></button>
            <button className="btn small" onClick={() => void act({ type: 'place', room: def.id, slot: slot as ItemSlot, item: null })} aria-label="Cất đi"><Icon.trash /></button>
          </div>
        )}
        {(preview || previewTheme) && selected && !owned(selected.id) && (
          <div className="card stack" style={{ gap: 6, borderColor: 'var(--lavender)' }}>
            <div className="row"><ItemThumb id={selected.id} size={52} /><div style={{ flex: 1 }}><div className="bold">Đang xem thử: {selected.name}</div><div className="muted small">{selected.blurb}</div></div></div>
            {selected.source === 'shop' ? (
              selected.rank > rank ? <div className="small muted">Mở bán ở hạng thị trấn {selected.rank}.</div> : (
                <div className="row">
                  <button className="btn primary" style={{ flex: 1 }} onClick={() => buy(selected)} disabled={state.wallet.coins < selected.price}>Mua · <Coins n={selected.price} /></button>
                  <button className="btn" onClick={() => { setPreview(null); setPreviewTheme(null) }}>Thôi</button>
                </div>
              )
            ) : <div className="small muted">{sourceText(selected)}</div>}
          </div>
        )}
        <div className="grid">
          {options.map(it => {
            const has = owned(it.id)
            const on = it.id === (slot === 'theme' ? rs.theme : current)
            return (
              <button key={it.id} className={'tile' + (!has && it.rank > rank ? ' locked' : '')} aria-pressed={on || it.id === selectedId} onClick={() => void pick(it)}>
                <ItemThumb id={it.id} size={slot === 'theme' ? 72 : 64} label={it.name} />
                <span className="name">{it.name}</span>
                {has ? <span className="tiny muted">{on ? 'Đang dùng' : 'Đã có'}</span>
                  : it.source === 'shop' ? <Coins n={it.price} /> : <span className="tiny muted">{it.source === 'capsule' ? 'Capsule' : 'Quà bộ'}</span>}
                {!has && it.rank > rank && <span className="tag badge gray">Hạng {it.rank}</span>}
              </button>
            )
          })}
        </div>
      </div>
      {layouts && <LayoutSheet roomId={def.id} onClose={() => setLayouts(false)} />}
    </div>
  )
}

function LayoutSheet({ roomId, onClose }: { roomId: RoomId; onClose: () => void }) {
  const { state, act, toast } = useGame()
  const list = state.presets.layouts[roomId] ?? []
  return (
    <Sheet title="Bố cục yêu thích" onClose={onClose}>
      <div className="stack">
        <p className="muted small">Lưu tối đa {ECONOMY.presets.layoutsPerRoom} bố cục cho mỗi phòng. Áp dụng lại cần đang sở hữu đủ các món.</p>
        {Array.from({ length: ECONOMY.presets.layoutsPerRoom }).map((_, i) => {
          const p = list[i]
          return (
            <div key={i} className="card row">
              <div style={{ flex: 1 }}>
                <div className="bold">{p?.name ?? `Ô lưu ${i + 1}`}</div>
                <div className="muted tiny">{p ? `${Object.keys(p.slots).length} món đồ` : 'Còn trống'}</div>
              </div>
              {p && <button className="btn small" onClick={async () => { if (await act({ type: 'applyLayout', room: roomId, index: i })) { toast('Đã áp dụng bố cục.', 'good'); onClose() } }}>Áp dụng</button>}
              <button className="btn small primary" onClick={async () => { if (await act({ type: 'saveLayout', room: roomId, index: i, name: `Bố cục ${i + 1}` })) toast('Đã lưu bố cục hiện tại.', 'good') }}>Lưu đè</button>
            </div>
          )
        })}
      </div>
    </Sheet>
  )
}
