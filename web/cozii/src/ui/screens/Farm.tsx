import { useEffect, useRef, useState } from 'react'
import { useGame } from '../../app/game'
import { back, go } from '../../app/router'
import { CROPS, TUTORIAL_CROP, crop as cropDef, cropBySeed, STOCK_NAME } from '../../content/farm'
import { ECONOMY } from '../../content/economy'
import { rankOf, readyAt, type Plot } from '../../core/state'
import { formatDuration, formatShort } from '../../core/time'
import { Coins, drawCrop, Empty, Icon, ItemThumb, ScreenHead, Sheet } from '../kit'
import { GC, rgb, Color } from '../../art/gc'
import { fitCanvas } from '../anim'
import { sfx } from '../../app/sound'
import { useTutorial } from '../../app/tutorial'

function useTick(ms = 1000) {
  const [, setN] = useState(0)
  useEffect(() => {
    const id = setInterval(() => setN(n => n + 1), ms)
    return () => clearInterval(id)
  }, [ms])
}

export function stage(p: Plot, now: number): number {
  if (!p.crop) return -1
  const total = readyAt(p) - p.plantedAt
  return Math.min(1, Math.max(0, (now - p.plantedAt) / Math.max(1, total)))
}

function PlotArt({ plot, progress, locked }: { plot: Plot; progress: number; locked: boolean }) {
  const ref = useRef<HTMLCanvasElement>(null)
  const bucket = progress >= 1 ? 3 : progress >= 0.34 ? 2 : progress >= 0 ? 1 : 0
  useEffect(() => {
    const cv = ref.current
    if (!cv) return
    const size = cv.clientWidth || 100
    const c = fitCanvas(cv, size, size)
    c.clearRect(0, 0, size, size)
    const g = new GC(c)
    g.scaleBy(size / 100, size / 100)
    if (locked) {
      g.strokePath(rgb(0xc8b89f), 3, q => { for (const x of [20, 50, 80]) { q.move({ x, y: 30 } as never); q.addLine({ x, y: 80 } as never) } })
      return
    }
    // luống đất
    for (let i = 0; i < 3; i++) g.rect(10, 30 + i * 20, 80, 9, rgb(0xb48f66).opacity(0.55), 4.5)
    if (plot.crop) drawCrop(g, plot.crop, 50, 82, progress >= 1 ? 1 : progress, 1.15)
    if (plot.selfWatered && progress < 1) g.ellipse(18, 84, 64, 8, rgb(0x6fa3d9).opacity(0.25))
    if (progress >= 1) g.text('✦', 12, rgb(0xf0c26a), { x: 82, y: 18 } as never)
    void Color
  }, [plot.crop, bucket, locked, plot.selfWatered, progress])
  return <canvas ref={ref} aria-hidden />
}

export function Farm() {
  const { state, act, serverNow, toast } = useGame()
  useTick(1000)
  const now = serverNow()
  const [open, setOpen] = useState<number | null>(null)
  const [buying, setBuying] = useState(false)
  const rank = rankOf(state)
  const { step } = useTutorial()

  const nextPlot = ECONOMY.farm.plotPrices.find(p => p.plot === state.farm.unlocked + 1)
  const hasSeeds = Object.keys(state.stock).some(k => k.startsWith('seed.') && k !== 'seed.sprout')
  const anyPlanted = state.farm.plots.some(p => p.crop)
  const canFree = !hasSeeds && !anyPlanted && state.wallet.coins < 10 && state.farm.freeSeedDay !== new Date(now + 7 * 3600e3).toISOString().slice(0, 10)

  const harvest = async (p: Plot) => {
    const r = await act({ type: 'harvest', plot: p.idx })
    if (r) {
      sfx('harvest')
      const res = r as { produce: string; count: number }
      toast(`+${res.count} ${STOCK_NAME(res.produce)}`, 'good')
    }
  }

  const produce = Object.entries(state.stock).filter(([k]) => k.startsWith('crop.'))

  return (
    <div className="stack">
      <ScreenHead title="Vườn rau" onBack={() => back('home')} right={<button className="btn small" onClick={() => go('place/market')}>Quầy hạt giống</button>} />
      <p className="muted small">Cây lớn theo thời gian thật, kể cả khi bạn đóng trình duyệt. Không có cây héo hay thối. Tưới là thưởng thêm, không bắt buộc.</p>
      <div className="farm-grid">
        {state.farm.plots.map(p => {
          const locked = p.idx >= state.farm.unlocked
          const prog = stage(p, now)
          const ready = !!p.crop && prog >= 1
          const isNext = locked && p.idx === state.farm.unlocked
          const label = locked ? (isNext && nextPlot ? `Mở: ${nextPlot.price} xu` : 'Chưa mở')
            : !p.crop ? 'Trống' : ready ? 'Thu hoạch!' : formatShort(readyAt(p) - now)
          return (
            <button
              key={p.idx}
              className={'plot' + (locked ? ' locked' : '') + (ready ? ' ready' : '')}
              style={step && (step.id === 'plant' || step.id === 'harvest') && !locked && (step.id === 'plant' ? !p.crop : ready) ? { boxShadow: '0 0 0 4px rgba(141,120,207,.45)' } : undefined}
              onClick={() => {
                sfx('tap')
                if (locked) {
                  if (isNext) setBuying(true)
                  return
                }
                if (ready) void harvest(p)
                else setOpen(p.idx)
              }}
              aria-label={`Ô ${p.idx + 1}: ${locked ? 'chưa mở' : p.crop ? `${cropDef(p.crop)?.name}, ${ready ? 'đã chín' : 'còn ' + formatDuration(readyAt(p) - now)}` : 'trống'}`}
            >
              <PlotArt plot={p} progress={prog} locked={locked} />
              <span className="plot-label">{label}</span>
            </button>
          )
        })}
      </div>

      {canFree && (
        <div className="card row">
          <div style={{ flex: 1 }} className="small"><b>Hết hạt và hết xu?</b> Cô Lá tặng {ECONOMY.farm.freeSeedPack.count} hạt củ cải, mỗi ngày một lần.</div>
          <button className="btn sage small" onClick={async () => { if (await act({ type: 'freeSeeds' })) toast('Nhận gói hạt miễn phí!', 'good') }}>Nhận</button>
        </div>
      )}

      <h2 className="section-title">Kho nông sản</h2>
      {produce.length === 0 ? <Empty>Chưa có nông sản. Thu hoạch xong sẽ nằm ở đây.</Empty> : (
        <div className="card row wrap">
          {produce.map(([id, n]) => (
            <div key={id} className="row" style={{ minWidth: 120 }}>
              <ItemThumb id={id} size={40} />
              <span className="small bold">{STOCK_NAME(id)} ×{n}</span>
            </div>
          ))}
          <span className="spacer" />
          <button className="btn small" onClick={() => go('place/orders')}>Giao đơn</button>
          <button className="btn small" onClick={() => go('place/market')}>Bán</button>
        </div>
      )}

      {open != null && <PlotSheet plot={state.farm.plots[open]} onClose={() => setOpen(null)} />}
      {buying && nextPlot && (
        <Sheet title={`Mở ô đất thứ ${nextPlot.plot}`} onClose={() => setBuying(false)}>
          <div className="stack">
            <p className="small">Thêm một ô đất để trồng nhiều hơn. Ô đất mở rồi là của bạn mãi mãi.</p>
            {nextPlot.rank > rank ? <div className="card small">Cần hạng thị trấn {nextPlot.rank}. Đóng dấu thêm chương hộ chiếu nhé.</div> : (
              <button className="btn primary block" disabled={state.wallet.coins < nextPlot.price} onClick={async () => {
                if (await act({ type: 'buyPlot' })) {
                  sfx('coin')
                  toast('Đã mở thêm ô đất!', 'good')
                  setBuying(false)
                }
              }}>Mở với <Coins n={nextPlot.price} /></button>
            )}
          </div>
        </Sheet>
      )}
    </div>
  )
}

function PlotSheet({ plot, onClose }: { plot: Plot; onClose: () => void }) {
  const { state, act, serverNow, toast } = useGame()
  useTick(1000)
  const now = serverNow()
  const rank = rankOf(state)
  if (plot.crop) {
    const c = cropDef(plot.crop)!
    const left = readyAt(plot) - now
    return (
      <Sheet title={c.name} onClose={onClose}>
        <div className="stack">
          <div className="row"><ItemThumb id={c.produceId} size={56} /><div className="small" style={{ flex: 1 }}>{c.blurb}<div className="muted">Thu hoạch được {c.yield} {c.name.toLowerCase()}.</div></div></div>
          <div className="card center">
            {left > 0 ? <><div className="muted small">Còn khoảng</div><div className="bold" style={{ fontSize: 24 }}>{formatDuration(left)}</div></> : <div className="bold">Đã chín! Chạm ô đất để thu hoạch.</div>}
            <div className="muted tiny">Đồng hồ chỉ để xem. Máy chủ xác nhận khi bạn thu hoạch.</div>
          </div>
          {left > 0 && (
            <button className="btn block" disabled={plot.selfWatered} onClick={async () => {
              if (await act({ type: 'water', plot: plot.idx })) {
                sfx('water')
                toast(`Đã tưới! Cây lớn nhanh hơn ${ECONOMY.farm.selfWaterCutPct}%.`, 'good')
              }
            }}><Icon.water />{plot.selfWatered ? 'Đã tưới vụ này' : `Tưới nước (nhanh hơn ${ECONOMY.farm.selfWaterCutPct}%)`}</button>
          )}
          {plot.helps > 0 && <div className="muted small center">Bạn bè đã tưới giúp {plot.helps} lần.</div>}
        </div>
      </Sheet>
    )
  }
  const seeds = Object.entries(state.stock).filter(([k]) => k.startsWith('seed.'))
  return (
    <Sheet title="Gieo hạt" onClose={onClose}>
      <div className="stack">
        {seeds.length === 0 ? <Empty>Túi hạt trống. Mua hạt ở Quầy Hạt Giống của Cô Lá.</Empty> : (
          <div className="grid">
            {seeds.map(([id, n]) => {
              const c = cropBySeed(id)!
              return (
                <button key={id} className="tile" onClick={async () => {
                  if (await act({ type: 'plant', plot: plot.idx, seed: id })) {
                    sfx('pop')
                    onClose()
                  }
                }}>
                  <ItemThumb id={id} size={56} />
                  <span className="name">{c.id === TUTORIAL_CROP.id ? 'Hạt mầm hướng dẫn' : c.name}</span>
                  <span className="tiny muted">{formatDuration(c.growSec * 1000)}</span>
                  <span className="tag badge gray">×{n}</span>
                </button>
              )
            })}
          </div>
        )}
        <p className="muted tiny">Hạt mầm hướng dẫn là quy tắc riêng của bước hướng dẫn: lớn trong 20 giây và chỉ có một hạt. Cây thường dùng thời gian thật.</p>
        <h3 className="bold small">Mua nhanh</h3>
        <div className="grid">
          {CROPS.filter(c => c.rank <= rank).map(c => (
            <button key={c.id} className="tile" onClick={async () => {
              if (await act({ type: 'buyStock', id: c.seedId, count: 1 })) {
                sfx('coin')
                if (await act({ type: 'plant', plot: plot.idx, seed: c.seedId })) onClose()
              }
            }} disabled={state.wallet.coins < c.seedPrice}>
              <ItemThumb id={c.seedId} size={48} />
              <span className="name">{c.name}</span>
              <span className="tiny muted">{formatDuration(c.growSec * 1000)} · {c.yield} quả</span>
              <Coins n={c.seedPrice} />
            </button>
          ))}
        </div>
      </div>
    </Sheet>
  )
}
