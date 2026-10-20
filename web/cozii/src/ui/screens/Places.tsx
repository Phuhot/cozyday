import { useMemo, useState } from 'react'
import { useGame } from '../../app/game'
import { back, go } from '../../app/router'
import { CROPS, FOODS, RECIPES, STOCK_NAME, MAX_FOOD_PER_PURCHASE } from '../../content/farm'
import { ITEMS, ROOMS, SLOT_LABEL, type RoomId } from '../../content/catalog'
import { ECONOMY } from '../../content/economy'
import { npc, type Npc } from '../../content/town'
import { rankOf } from '../../core/state'
import { sellQuote, marketProfitLeft } from '../../core/engine'
import { formatDuration } from '../../core/time'
import { Coins, Empty, ItemThumb, ScreenHead, Sheet } from '../kit'
import { PetCanvas } from '../PetCanvas'
import { sfx } from '../../app/sound'
import { Wardrobe } from './Wardrobe'
import { Capsule } from './Capsule'
import { Playground } from './Playground'
import { Hall } from './Hall'

export function NpcHeader({ id, line }: { id: string; line?: string }) {
  const n: Npc = npc(id)
  const [i, setI] = useState(() => Math.floor(Math.random() * n.lines.length))
  return (
    <div className="card row" style={{ gap: 12, background: 'linear-gradient(120deg, #fffdf8, #f6eefc)' }}>
      <PetCanvas appearance={n.look} size={78} interactive onTap={() => setI(v => v + 1)} label={n.name} />
      <div style={{ flex: 1 }}>
        <div className="bold">{n.name} <span className="badge gray">{n.role}</span></div>
        <div className="small" style={{ marginTop: 4 }}>{line ?? n.lines[i % n.lines.length]}</div>
      </div>
    </div>
  )
}

export function Place({ id }: { id: string }) {
  switch (id) {
    case 'market': return <Market />
    case 'bakery': return <Bakery />
    case 'furniture': return <FurnitureShop />
    case 'tailor': return <Wardrobe shopOnly />
    case 'capsule': return <Capsule />
    case 'orders': return <Orders />
    case 'playground': return <Playground />
    case 'hall': return <Hall />
    default: return <div className="card">Không tìm thấy địa điểm.</div>
  }
}

function Qty({ value, set, max }: { value: number; set: (n: number) => void; max: number }) {
  return (
    <div className="row" style={{ gap: 4 }}>
      <button className="btn small" onClick={() => set(Math.max(1, value - 1))} aria-label="Bớt">−</button>
      <span className="bold" style={{ minWidth: 24, textAlign: 'center' }}>{value}</span>
      <button className="btn small" onClick={() => set(Math.min(max, value + 1))} aria-label="Thêm">+</button>
    </div>
  )
}

function Market() {
  const { state, act, toast } = useGame()
  const rank = rankOf(state)
  const [tab, setTab] = useState<'buy' | 'sell'>('buy')
  const [qty, setQty] = useState<Record<string, number>>({})
  const q = (id: string) => qty[id] ?? 1
  return (
    <div className="stack">
      <ScreenHead title="Quầy Hạt Giống" onBack={() => back('town')} />
      <NpcHeader id="la" />
      <div className="pill-tabs">
        <button className="pill" aria-pressed={tab === 'buy'} onClick={() => setTab('buy')}>Mua hạt</button>
        <button className="pill" aria-pressed={tab === 'sell'} onClick={() => setTab('sell')}>Bán nông sản</button>
      </div>
      {tab === 'buy' ? (
        <div className="stack" style={{ gap: 8 }}>
          {CROPS.map(c => {
            const locked = c.rank > rank
            return (
              <div key={c.id} className={'card row' + (locked ? ' locked' : '')} style={{ opacity: locked ? 0.6 : 1 }}>
                <ItemThumb id={c.seedId} size={52} />
                <div style={{ flex: 1 }}>
                  <div className="bold">{c.name} <span className="muted tiny">trong kho: {state.stock[c.seedId] ?? 0}</span></div>
                  <div className="muted tiny">{formatDuration(c.growSec * 1000)} · thu {c.yield} · bán {c.sellPrice} xu/quả</div>
                  {locked && <div className="tiny bold" style={{ color: 'var(--peach)' }}>Mở ở hạng {c.rank}</div>}
                </div>
                {!locked && (
                  <div className="stack" style={{ gap: 4, alignItems: 'flex-end' }}>
                    <Qty value={q(c.seedId)} set={n => setQty({ ...qty, [c.seedId]: n })} max={10} />
                    <button className="btn small primary" disabled={state.wallet.coins < c.seedPrice * q(c.seedId)} onClick={async () => {
                      if (await act({ type: 'buyStock', id: c.seedId, count: q(c.seedId) })) { sfx('coin'); toast(`Đã mua ${q(c.seedId)} hạt ${c.name.toLowerCase()}.`, 'good') }
                    }}>Mua <Coins n={c.seedPrice * q(c.seedId)} /></button>
                  </div>
                )}
              </div>
            )
          })}
          <button className="btn" onClick={() => go('farm')}>Ra vườn gieo hạt</button>
        </div>
      ) : (
        <div className="stack" style={{ gap: 8 }}>
          <p className="muted small">Giao đơn hàng cho Bé Bơ được nhiều xu hơn bán ở đây. Hôm nay bạn còn lãi được <b>{marketProfitLeft(state, Date.now())}</b>/{ECONOMY.farm.marketProfitPerDay} xu khi bán ở quầy; vượt mức thì quầy mua đúng giá vốn hạt giống (không lỗ), sang ngày mới lại đủ giá.</p>
          {CROPS.filter(c => (state.stock[c.produceId] ?? 0) > 0).length === 0 && <Empty>Chưa có nông sản để bán.</Empty>}
          {CROPS.filter(c => (state.stock[c.produceId] ?? 0) > 0).map(c => {
            const have = state.stock[c.produceId] ?? 0
            const n = Math.min(have, q(c.produceId))
            const quote = sellQuote(state, Date.now(), c, n)
            return (
              <div key={c.id} className="card row">
                <ItemThumb id={c.produceId} size={48} />
                <div style={{ flex: 1 }}><div className="bold">{c.name} ×{have}</div><div className="muted tiny">{c.sellPrice} xu mỗi quả{quote.atCost > 0 ? ` · ${quote.atCost} quả giá vốn` : ''}</div></div>
                <div className="stack" style={{ gap: 4, alignItems: 'flex-end' }}>
                  <Qty value={n} set={v => setQty({ ...qty, [c.produceId]: v })} max={have} />
                  <button className="btn small sage" onClick={async () => {
                    const r = await act({ type: 'sell', id: c.produceId, count: n })
                    if (r) { sfx('coin'); toast(`+${(r as { coins: number }).coins} xu`, 'good') }
                  }}>Bán <Coins n={quote.coins} /></button>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}

function Bakery() {
  const { state, act, toast } = useGame()
  const rank = rankOf(state)
  const [qty, setQty] = useState<Record<string, number>>({})
  const q = (id: string) => qty[id] ?? 1
  return (
    <div className="stack">
      <ScreenHead title="Tiệm Bánh" onBack={() => back('town')} />
      <div className="card small">Đồ ăn dùng một lần, mua lại thoải mái. Nấu từ nông sản nhà trồng thì rẻ hơn nhiều.</div>
      <h2 className="section-title">Mua sẵn</h2>
      <div className="grid">
        {FOODS.filter(f => f.price > 0).map(f => (
          <div key={f.id} className="tile">
            <ItemThumb id={f.id} size={58} />
            <span className="name">{f.name}</span>
            <span className="tiny muted">+{f.fullness} no{f.happiness ? ` +${f.happiness} vui` : ''}</span>
            <Qty value={q(f.id)} set={n => setQty({ ...qty, [f.id]: n })} max={MAX_FOOD_PER_PURCHASE} />
            <button className="btn small primary" disabled={state.wallet.coins < f.price * q(f.id)} onClick={async () => {
              if (await act({ type: 'buyStock', id: f.id, count: q(f.id) })) { sfx('coin'); toast(`Đã mua ${q(f.id)} ${f.name.toLowerCase()}.`, 'good') }
            }}><Coins n={f.price * q(f.id)} /></button>
            <span className="tag badge gray">×{state.stock[f.id] ?? 0}</span>
          </div>
        ))}
      </div>
      <h2 className="section-title">Nấu từ vườn</h2>
      <div className="stack" style={{ gap: 8 }}>
        {RECIPES.map(r => {
          const out = FOODS.find(f => f.id === r.output)!
          const can = Object.entries(r.needs).every(([id, n]) => (state.stock[id] ?? 0) >= n)
          const locked = r.rank > rank
          return (
            <div key={r.id} className="card row" style={{ opacity: locked ? 0.6 : 1 }}>
              <ItemThumb id={out.id} size={52} />
              <div style={{ flex: 1 }}>
                <div className="bold">{out.name}</div>
                <div className="tiny muted">{Object.entries(r.needs).map(([id, n]) => `${n} ${STOCK_NAME(id).toLowerCase()} (có ${state.stock[id] ?? 0})`).join(' + ')}</div>
                {locked && <div className="tiny bold" style={{ color: 'var(--peach)' }}>Mở ở hạng {r.rank}</div>}
              </div>
              <button className="btn small sage" disabled={!can || locked} onClick={async () => {
                if (await act({ type: 'cook', recipe: r.id, count: 1 })) { sfx('good'); toast(`Đã nấu ${out.name.toLowerCase()}!`, 'good') }
              }}>Nấu</button>
            </div>
          )
        })}
      </div>
    </div>
  )
}

function FurnitureShop() {
  const { state, act, toast } = useGame()
  const rank = rankOf(state)
  const [roomId, setRoomId] = useState<RoomId>('study')
  const [detail, setDetail] = useState<string | null>(null)
  const room = ROOMS.find(r => r.id === roomId)!
  const items = useMemo(() => ITEMS.filter(i => i.source === 'shop' && (i.slot === room.themeSlot || room.slots.includes(i.slot))), [room])
  const it = detail ? ITEMS.find(i => i.id === detail)! : null
  return (
    <div className="stack">
      <ScreenHead title="Tiệm Nội Thất" onBack={() => back('town')} />
      <NpcHeader id="moc" />
      <div className="pill-tabs">{ROOMS.map(r => <button key={r.id} className="pill" aria-pressed={roomId === r.id} onClick={() => setRoomId(r.id)}>{r.name}{r.rank > rank && <span className="lock">🔒</span>}</button>)}</div>
      {room.rank > rank && <div className="card small">{room.name} mở ở hạng {room.rank}. Vẫn xem hàng được nhé.</div>}
      <div className="grid">
        {items.map(i => {
          const has = state.owned.includes(i.id)
          return (
            <button key={i.id} className={'tile' + (i.rank > rank ? ' locked' : '')} onClick={() => setDetail(i.id)}>
              <ItemThumb id={i.id} size={64} />
              <span className="name">{i.name}</span>
              {has ? <span className="tiny muted">Đã có</span> : <Coins n={i.price} />}
              <span className="tiny muted">{SLOT_LABEL[i.slot]}</span>
              {i.rank > rank && <span className="tag badge gray">Hạng {i.rank}</span>}
            </button>
          )
        })}
      </div>
      {it && (
        <Sheet title={it.name} onClose={() => setDetail(null)}>
          <div className="stack" style={{ alignItems: 'center' }}>
            <ItemThumb id={it.id} size={160} />
            <p className="small center">{it.blurb}</p>
            {state.owned.includes(it.id) ? (
              <button className="btn primary block" onClick={() => go(`home/decorate/${roomId}`)}>Đặt vào phòng</button>
            ) : it.rank > rank ? <div className="muted small">Mở bán ở hạng thị trấn {it.rank}.</div> : (
              <>
                <button className="btn block" onClick={() => go(`home/decorate/${roomId}`)} disabled={room.rank > rank}>Xem thử trong phòng</button>
                <button className="btn primary block" disabled={state.wallet.coins < it.price} onClick={async () => {
                  if (await act({ type: 'buyItem', item: it.id })) { sfx('coin'); toast(`Đã mua ${it.name}! Vào Trang trí để đặt.`, 'good') }
                }}>Mua <Coins n={it.price} /></button>
              </>
            )}
          </div>
        </Sheet>
      )}
    </div>
  )
}

function Orders() {
  const { state, act, toast } = useGame()
  const today = new Date(Date.now() + 7 * 3600e3).toISOString().slice(0, 10)
  const rerollsLeft = ECONOMY.orders.freeRerollsPerDay - (state.orders.rerollDay === today ? state.orders.rerollsUsed : 0)
  const doneToday = state.orders.doneDay === today ? state.orders.doneToday : 0
  return (
    <div className="stack">
      <ScreenHead title="Bảng đơn hàng" onBack={() => back('town')} />
      <NpcHeader id="bo" />
      <p className="muted small">Đơn không có hạn chót. Giao đơn được nhiều hơn bán lẻ khoảng {Math.round((ECONOMY.orders.rewardMultiplier - 1) * 100)}%. Hôm nay đã giao {doneToday}/{ECONOMY.orders.maxCompletedPerDay}.</p>
      {state.orders.list.map(o => {
        const can = Object.entries(o.needs).every(([id, n]) => (state.stock[id] ?? 0) >= n)
        const sender = npc(o.npc)
        return (
          <div key={o.id} className="card stack" style={{ gap: 8 }}>
            <div className="row"><b style={{ flex: 1 }}>Đơn của {sender.name}</b><Coins n={o.coins} /></div>
            <div className="row wrap">
              {Object.entries(o.needs).map(([id, n]) => {
                const have = state.stock[id] ?? 0
                return (
                  <div key={id} className="row" style={{ gap: 4, padding: '4px 8px', borderRadius: 12, background: have >= n ? 'var(--sage-2)' : 'var(--surface-2)' }}>
                    <ItemThumb id={id} size={30} />
                    <span className="small bold">{Math.min(have, n)}/{n}</span>
                  </div>
                )
              })}
            </div>
            <div className="row">
              <button className="btn small" disabled={rerollsLeft <= 0} onClick={() => void act({ type: 'rerollOrder', order: o.id })}>Đổi đơn ({rerollsLeft})</button>
              <span className="spacer" />
              <button className="btn small primary" disabled={!can} onClick={async () => {
                const r = await act({ type: 'completeOrder', order: o.id })
                if (r) { sfx('coin'); toast(`Giao xong! +${(r as { coins: number }).coins} xu`, 'good') }
              }}>Giao hàng</button>
            </div>
          </div>
        )
      })}
    </div>
  )
}
