import { useEffect, useRef, useState } from 'react'
import { useGame } from '../../app/game'
import { back } from '../../app/router'
import { SERIES, itemRates, RARITY_LABEL, type Series } from '../../content/capsule'
import { ECONOMY } from '../../content/economy'
import { item as catalogItem } from '../../content/catalog'
import type { PullResult } from '../../core/state'
import { Coins, ItemThumb, ScreenHead, ShardIcon, Sheet, TicketIcon } from '../kit'
import { GC, rgb, Color, pt } from '../../art/gc'
import * as T from '../../art/town'
import { fitCanvas, useFrame, useReducedMotion } from '../anim'
import { sfx } from '../../app/sound'
import { uuid } from '../../backend/local'
import { dayKey } from '../../core/time'

const RARITY_COLOR = { common: '#9aa6b2', rare: '#6f9ad9', special: '#d9a441' }

/** Máy capsule: tỷ lệ, danh sách và bảo hiểm công khai; kết quả do máy chủ quyết định và lưu cùng giao dịch tiêu vé. */
export function Capsule() {
  const { state, act, serverNow, toast } = useGame()
  const [sid, setSid] = useState(SERIES[0].id)
  const [rates, setRates] = useState(false)
  const [reveal, setReveal] = useState<PullResult | null>(null)
  const [spinning, setSpinning] = useState(false)
  const pendingId = useRef<string | null>(null)
  const s = SERIES.find(x => x.id === sid)!
  const owned = (id: string) => state.owned.includes(id)
  const have = s.items.filter(i => owned(i.id)).length
  const complete = have === s.items.length
  const rewardClaimed = owned(s.reward.item)
  const pity = state.capsule.pity[sid] ?? { sinceRare: 0, sinceSpecial: 0 }
  const today = dayKey(serverNow())
  const boughtToday = state.capsule.ticketDay === today ? state.capsule.ticketsBought : 0

  const pull = async () => {
    if (state.wallet.tickets < 1) {
      toast('Cần một vé capsule.', 'warn')
      return
    }
    // Giữ mã yêu cầu: mất mạng giữa chừng thì gửi lại đúng mã, máy chủ trả lại đúng kết quả đã lưu.
    pendingId.current = pendingId.current ?? uuid()
    setSpinning(true)
    sfx('open')
    const r = await act({ type: 'openCapsule', series: sid }, { requestId: pendingId.current })
    if (!r) {
      setSpinning(false)
      return
    }
    pendingId.current = null
    const p = (r as { pull: PullResult }).pull
    setTimeout(() => {
      setSpinning(false)
      setReveal(p)
      sfx(p.rarity === 'special' ? 'special' : p.rarity === 'rare' ? 'rare' : 'pop')
    }, 1300)
  }

  return (
    <div className="wide-2">
      <div className="stack">
        <ScreenHead title="Máy capsule" onBack={() => back('town')} right={<button className="btn small" onClick={() => setRates(true)}>Tỷ lệ & quy tắc</button>} />
        <div className="pill-tabs">{SERIES.map(x => <button key={x.id} className="pill" aria-pressed={x.id === sid} onClick={() => setSid(x.id)}>{x.name}</button>)}</div>
        <div className="card machine">
          <MachineCanvas series={s} spinning={spinning} />
          <div className="small center muted">{s.blurb}</div>
          <div className="row">
            <span className="chip"><TicketIcon /> {state.wallet.tickets} vé</span>
            <span className="chip"><ShardIcon /> {state.wallet.shards} mảnh</span>
          </div>
          <button className="btn primary block" disabled={spinning || state.wallet.tickets < 1} onClick={() => void pull()}>Quay 1 lần · 1 vé</button>
          <button className="btn block" disabled={boughtToday >= ECONOMY.capsule.maxTicketBuysPerDay || state.wallet.coins < ECONOMY.capsule.ticketPriceCoins} onClick={async () => {
            if (await act({ type: 'buyTicket' })) { sfx('coin'); toast('+1 vé capsule', 'good') }
          }}>Đổi 1 vé · <Coins n={ECONOMY.capsule.ticketPriceCoins} /> <span className="tiny muted">({boughtToday}/{ECONOMY.capsule.maxTicketBuysPerDay} hôm nay)</span></button>
          <div className="tiny muted center">Bảo hiểm bộ này: còn {Math.max(1, ECONOMY.capsule.rarePity - pity.sinceRare)} lượt chắc chắn ra Hiếm trở lên · còn {Math.max(1, ECONOMY.capsule.specialPity - pity.sinceSpecial)} lượt chắc chắn ra Đặc biệt.</div>
        </div>
      </div>
      <div className="stack">
        <div className="card stack" style={{ gap: 8 }}>
          <div className="row"><b style={{ flex: 1 }}>Bộ sưu tập · {have}/{s.items.length}</b></div>
          <div className="grid" style={{ gridTemplateColumns: 'repeat(4, 1fr)', gap: 6 }}>
            {s.items.map(i => {
              const it = catalogItem(i.id)!
              const got = owned(i.id)
              const cost = ECONOMY.capsule.shardCost[i.rarity]
              return (
                <div key={i.id} className="tile" style={{ minHeight: 100, opacity: got ? 1 : 0.85, borderColor: RARITY_COLOR[i.rarity] }}>
                  <div style={{ filter: got ? 'none' : 'grayscale(1) opacity(0.45)' }}><ItemThumb id={i.id} size={48} /></div>
                  <span className="name" style={{ fontSize: 11 }}>{it.name}</span>
                  {!got && <button className="btn small" style={{ minHeight: 28, padding: '2px 6px', fontSize: 11 }} disabled={state.wallet.shards < cost} onClick={async () => {
                    if (await act({ type: 'exchangeShards', item: i.id })) { sfx('good'); toast(`Đã đổi ${it.name}!`, 'good') }
                  }}><ShardIcon size={14} />{cost}</button>}
                </div>
              )
            })}
          </div>
          <div className="card row" style={{ background: complete ? 'var(--honey-2)' : 'var(--surface-2)' }}>
            <ItemThumb id={s.reward.item} size={56} />
            <div style={{ flex: 1 }} className="small">
              <b>Quà hoàn thành bộ</b>
              <div>{catalogItem(s.reward.item)?.name} · danh hiệu “{s.reward.title}” · tư thế chụp ảnh mới</div>
            </div>
            {complete && !rewardClaimed && <button className="btn honey small" onClick={async () => {
              if (await act({ type: 'claimSeries', series: s.id })) { sfx('special'); toast('Hoàn thành bộ! Đã nhận quà.', 'good') }
            }}>Nhận</button>}
            {rewardClaimed && <span className="badge sage">Đã nhận</span>}
          </div>
        </div>
        {state.capsule.last.length > 0 && (
          <div className="card stack" style={{ gap: 4 }}>
            <b className="small">Lượt quay gần đây (lưu trên {state.mode === 'online' ? 'máy chủ' : 'máy này'})</b>
            {state.capsule.last.slice(0, 5).map(p => (
              <div key={p.requestId} className="row small">
                <ItemThumb id={p.item} size={28} />
                <span style={{ flex: 1 }}>{catalogItem(p.item)?.name}</span>
                <span className="badge" style={{ background: RARITY_COLOR[p.rarity], color: '#fff' }}>{RARITY_LABEL[p.rarity]}</span>
                {p.duplicate && <span className="tiny muted">+{p.shards} mảnh</span>}
              </div>
            ))}
          </div>
        )}
      </div>
      {reveal && (
        <Sheet title={reveal.duplicate ? 'Món trùng → mảnh' : 'Món mới!'} onClose={() => setReveal(null)}>
          <div className="stack" style={{ alignItems: 'center', textAlign: 'center' }}>
            <div style={{ animation: 'pop .45s ease' }}><ItemThumb id={reveal.item} size={150} /></div>
            <span className="badge" style={{ background: RARITY_COLOR[reveal.rarity], color: '#fff', fontSize: 14 }}>{RARITY_LABEL[reveal.rarity]}</span>
            <b style={{ fontSize: 20 }}>{catalogItem(reveal.item)?.name}</b>
            <p className="small muted">{reveal.duplicate ? `Bạn đã có món này nên nhận ${reveal.shards} mảnh. Đủ mảnh thì đổi được món còn thiếu.` : catalogItem(reveal.item)?.blurb}</p>
            <button className="btn primary block" onClick={() => setReveal(null)}>Tuyệt!</button>
          </div>
        </Sheet>
      )}
      {rates && <RatesSheet onClose={() => setRates(false)} />}
    </div>
  )
}

function RatesSheet({ onClose }: { onClose: () => void }) {
  const c = ECONOMY.capsule
  return (
    <Sheet title="Tỷ lệ & quy tắc" onClose={onClose}>
      <div className="stack small">
        <p>Capsule chỉ có đồ ngoại hình, không tăng sức mạnh. Không dùng tiền thật, không đổi ra tiền, không trao đổi giữa người chơi.</p>
        <ul style={{ margin: 0, paddingLeft: 18 }}>
          <li>Mỗi lượt: Thường {c.rates.common}% · Hiếm {c.rates.rare}% · Đặc biệt {c.rates.special}%. Các món cùng bậc chia đều.</li>
          <li>Bảo hiểm: lượt thứ {c.rarePity} kể từ lần ra Hiếm/Đặc biệt gần nhất chắc chắn ra Hiếm trở lên; lượt thứ {c.specialPity} kể từ lần ra Đặc biệt gần nhất chắc chắn ra Đặc biệt. Bảo hiểm tính riêng cho từng bộ và không mất đi.</li>
          <li>Món trùng thành mảnh: Thường {c.shardsForDuplicate.common} · Hiếm {c.shardsForDuplicate.rare} · Đặc biệt {c.shardsForDuplicate.special}.</li>
          <li>Đổi mảnh lấy món còn thiếu: Thường {c.shardCost.common} · Hiếm {c.shardCost.rare} · Đặc biệt {c.shardCost.special}.</li>
          <li>Đủ 8 món của một bộ: nhận món trang trí hoàn thiện chủ đề, danh hiệu và tư thế chụp ảnh.</li>
          <li>Kết quả do máy chủ quyết định và lưu cùng lần tiêu vé. Mất mạng giữa lúc mở: mở lại sẽ thấy đúng kết quả đã lưu, không quay lại. (Chế độ chơi trên máy: kết quả do trình duyệt quyết định, không phải tài sản online.)</li>
        </ul>
        {SERIES.map(s => (
          <div key={s.id}>
            <b>{s.name}</b>
            <table className="rate-table"><tbody>
              {itemRates(s).map(r => <tr key={r.id}><td>{catalogItem(r.id)?.name}</td><td>{RARITY_LABEL[r.rarity]}</td><td style={{ textAlign: 'right' }}>{r.pct}%</td></tr>)}
            </tbody></table>
          </div>
        ))}
      </div>
    </Sheet>
  )
}

function MachineCanvas({ series, spinning }: { series: Series; spinning: boolean }) {
  const ref = useRef<HTMLCanvasElement>(null)
  const reduce = useReducedMotion()
  const spinAt = useRef(0)
  useEffect(() => {
    if (spinning) spinAt.current = performance.now()
  }, [spinning])
  const draw = (t: number) => {
    const cv = ref.current
    if (!cv) return
    const size = 220
    const c = fitCanvas(cv, size, size)
    c.clearRect(0, 0, size, size)
    const g = new GC(c)
    g.scaleBy(size / 100, size / 100)
    g.circle(50, 52, 44, rgb(series.color).opacity(0.12))
    const shake = spinning && !reduce ? Math.sin(t * 40) * 1.2 : 0
    g.translateBy(shake, 0)
    T.capsuleMachine(g, 50, 92, 2.6, spinning && !reduce ? t * 6 : t * 0.6)
    if (spinning) {
      const k = Math.min(1, (performance.now() - spinAt.current) / 1100)
      g.circle(50, 70 + k * 18, 5, rgb(series.color))
      g.ellipse(46, 67 + k * 18, 4, 3, Color.white.opacity(0.6))
      if (k > 0.8) T.sparkle(g, 64, 70, 7, rgb(0xf0c26a))
    }
    void pt
  }
  useFrame(t => draw(t), !reduce || spinning, 30)
  useEffect(() => draw(0))
  return <canvas ref={ref} style={{ width: 220, height: 220 }} role="img" aria-label={`Máy capsule bộ ${series.name}`} />
}
