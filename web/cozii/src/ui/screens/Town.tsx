import { useEffect, useRef } from 'react'
import { useGame } from '../../app/game'
import { go } from '../../app/router'
import { PLACES, NPCS, type PlaceId } from '../../content/town'
import { rankOf, readyAt } from '../../core/state'
import { GC, rgb, Color, pt, R, Path } from '../../art/gc'
import * as T from '../../art/town'
import { fitCanvas, useElementWidth, useFrame, useReducedMotion } from '../anim'
import { petAppearance } from './Home'
import { paintPet } from '../../art'
import { restPose } from '../../content/pet'
import { sfx } from '../../app/sound'
import { useTutorial } from '../../app/tutorial'
import { DailyCard } from './Hall'

const MAP_H = 160

/** Bản đồ minh họa thị trấn. Các địa điểm là nút bấm; thị trấn sáng dần theo hạng. */
export function Town() {
  const { state, serverNow } = useGame()
  const rank = rankOf(state)
  const [wrap, w] = useElementWidth<HTMLDivElement>()
  const cv = useRef<HTMLCanvasElement>(null)
  const reduce = useReducedMotion()
  const { step } = useTutorial()
  const k = w / 100

  const draw = (t: number) => {
    const c0 = cv.current
    if (!c0 || !w) return
    const c = fitCanvas(c0, w, MAP_H * k)
    const g = new GC(c)
    g.scaleBy(k, k)
    drawTown(g, t, rank, state, k)
  }
  useFrame(t => draw(t), !!w && !reduce, 20)
  useEffect(() => draw(0))

  const ready = state.farm.plots.some(p => p.crop && serverNow() >= readyAt(p))
  const marks: Partial<Record<PlaceId, boolean>> = {
    farm: ready,
    hall: false,
    capsule: state.wallet.tickets > 0,
  }
  const target = step?.where.startsWith('place/') ? step.where.slice(6) : step?.where === 'farm' ? 'farm' : step?.where.startsWith('visit/npc:') ? 'npc_' + step.where.slice(10) : null

  return (
    <div className="wide-2">
      <div className="stack">
        <h1 className="screen-title">Thị trấn Cozii</h1>
        <div ref={wrap} className="map-wrap" style={{ aspectRatio: `100 / ${MAP_H}` }}>
          <canvas ref={cv} style={{ width: '100%', height: '100%' }} role="img" aria-label="Bản đồ thị trấn Cozii" />
          {PLACES.map(p => (
            <button
              key={p.id}
              className={'place-btn' + (p.id.startsWith('npc_') ? ' npc' : '')}
              style={{ left: `${p.x}%`, top: `${((p.y + 0.5) / MAP_H) * 100}%`, outline: target === p.id ? '3px solid var(--lavender)' : undefined, borderRadius: 16 }}
              onClick={() => {
                sfx('tap')
                if (p.id === 'home') go('home')
                else if (p.id === 'farm') go('farm')
                else if (p.id.startsWith('npc_')) go('visit/npc:' + p.id.slice(4))
                else go('place/' + p.id)
              }}
            >
              <span>{p.name}</span>
              {marks[p.id] && <i className="new" aria-label="có việc mới" />}
            </button>
          ))}
        </div>
      </div>
      <div className="stack">
        <div className="card small">
          <b>Hạng thị trấn {rank}</b>
          <div className="muted">{rank >= 6 ? 'Thị trấn đã sáng đèn khắp nơi. Ngày hội vui ghê!' : 'Mỗi chương hộ chiếu đóng dấu, thị trấn lại sáng thêm một chút.'}</div>
        </div>
        <DailyCard />
        <div className="card stack" style={{ gap: 4 }}>
          <b className="small">Người trong thị trấn</b>
          {NPCS.map(n => <div key={n.id} className="small"><b>{n.name}</b> <span className="muted">· {n.role}</span></div>)}
        </div>
      </div>
    </div>
  )
}

function drawTown(g: GC, t: number, rank: number, state: ReturnType<typeof useGame>['state'], k: number) {
  // nền cỏ & suối
  g.rect(0, 0, 100, MAP_H, rgb(0xcbe8b5))
  for (let i = 0; i < 40; i++) g.circle((i * 37.3) % 100, (i * 53.7) % MAP_H, 0.5, rgb(0xb3dc9c))
  const river = new Path()
  river.move(pt(-5, 104))
  river.addQuadCurve(pt(105, 100), pt(50, 112))
  g.stroke(river, rgb(0xa8d8ec), 7)
  g.stroke(river, rgb(0xc8e8f4), 3)
  // cầu
  g.rect(44, 101, 12, 9, rgb(0xd4b08a), 2)
  // đường chính
  T.road(g, [[50, 160], [50, 130], [50, 104], [50, 76], [50, 48], [50, 22]], 7)
  T.road(g, [[20, 64], [50, 70], [80, 64]], 4.5)
  T.road(g, [[22, 94], [50, 98], [78, 94]], 4.5)
  T.road(g, [[24, 128], [50, 132], [76, 128]], 4.5)
  T.road(g, [[16, 154], [50, 157], [84, 154]], 4)

  const lit = rank >= 3 ? 1 : rank >= 2 ? 0.5 : 0.15
  const at = (id: string) => PLACES.find(p => p.id === id)!
  const P = (id: string): [number, number] => [at(id).x, at(id).y]
  {
    const [x, y] = P('npc_tra'); T.house(g, x, y, 13, { wall: rgb(0xfdf3e3), roof: rgb(0x9c7bd0), door: rgb(0xa07448), lit })
  }
  {
    const [x, y] = P('hall'); T.house(g, x, y, 24, { wall: rgb(0xfffaf0), roof: rgb(0x8d78cf), door: rgb(0xa07448), lit, sign: 'THỊ CHÍNH' })
  }
  {
    const [x, y] = P('capsule'); g.ellipse(x - 16, y - 6, 32, 10, rgb(0xf1e2c4)); T.capsuleMachine(g, x, y, 0.8, t)
    if (rank >= 4) T.fountain(g, x - 14, y, 0.5, t)
  }
  { const [x, y] = P('furniture'); T.house(g, x, y, 20, { wall: rgb(0xf6e3cf), roof: rgb(0xb07a4c), door: rgb(0x8c5e3a), lit, sign: 'NỘI THẤT' }) }
  { const [x, y] = P('tailor'); T.house(g, x, y, 20, { wall: rgb(0xf3e9f7), roof: rgb(0xd98aa6), door: rgb(0xa07448), lit, sign: 'TIỆM MAY' }) }
  { const [x, y] = P('bakery'); T.house(g, x, y, 20, { wall: rgb(0xfdf0e2), roof: rgb(0xe59a7a), door: rgb(0xa07448), lit, awning: rgb(0xf2a3b8), sign: 'TIỆM BÁNH' }) }
  { const [x, y] = P('market'); T.stall(g, x, y, 20, rgb(0x6f9a72)); g.text('HẠT GIỐNG', 3, rgb(0x3e3550), pt(x, y - 14), 'bold') }
  {
    const [x, y] = P('orders')
    g.rect(x - 1, y - 8, 2, 8, rgb(0xa07448))
    g.rect(x - 7, y - 15, 14, 9, rgb(0xc89b6d), 1.5)
    g.rect(x - 6, y - 14, 12, 7, rgb(0xfdf6ec), 1)
    for (let i = 0; i < 3; i++) g.rect(x - 5 + i * 3.6, y - 13, 2.8, 3.8, rgb([0xf2a3b8, 0xf6d36b, 0x9ed4b6][i]), 0.5)
  }
  {
    const [x, y] = P('playground')
    g.ellipse(x - 14, y - 6, 28, 9, rgb(0xf6e7c8))
    g.rect(x - 9, y - 14, 2, 12, rgb(0xd9667a)); g.rect(x + 7, y - 14, 2, 12, rgb(0xd9667a)); g.rect(x - 10, y - 15, 20, 2, rgb(0xd9667a), 1)
    g.strokePath(rgb(0x7a6f86), 0.4, q => { q.move(pt(x - 4, y - 13)); q.addLine(pt(x - 4, y - 6)); q.move(pt(x + 3, y - 13)); q.addLine(pt(x + 3, y - 6)) })
    g.rect(x - 5.5, y - 6, 3, 1, rgb(0x8d78cf), 0.5); g.rect(x + 1.5, y - 6, 3, 1, rgb(0x8d78cf), 0.5)
  }
  {
    const [x, y] = P('farm')
    g.rect(x - 13, y - 16, 26, 15, rgb(0xb48f66), 3)
    for (let i = 0; i < 3; i++) g.rect(x - 11, y - 14 + i * 4.6, 22, 2.6, rgb(0x9c7650), 1.3)
    const planted = state.farm.plots.filter(p => p.crop).length
    for (let i = 0; i < Math.min(planted, 9); i++) g.circle(x - 7 + (i % 3) * 7, y - 12.6 + Math.floor(i / 3) * 4.6, 1.4, rgb(0x7fbf7a))
  }
  { const [x, y] = P('home'); T.house(g, x, y, 18, { wall: rgb(0xfffaf0), roof: rgb(0xa58bd9), door: rgb(0xc89b6d), lit: 1, sign: 'NHÀ MÌNH' }); paintPet(g.ctx, (x + 7) * k, (y - 9) * k, 9 * k, petAppearance(state), 'idle', restPose()) }
  { const [x, y] = P('npc_moc'); T.house(g, x, y, 15, { wall: rgb(0xf6e3cf), roof: rgb(0x8e6247), door: rgb(0x8c5e3a), lit }) }
  { const [x, y] = P('npc_la'); T.house(g, x, y, 15, { wall: rgb(0xe4efe2), roof: rgb(0x6f9a72), door: rgb(0xa07448), lit }) }
  // cây, đèn
  for (const [x, y, s] of [[8, 26, 1], [92, 28, 1.1], [6, 78, 0.9], [94, 78, 0.9], [6, 136, 0.9], [94, 136, 1], [36, 140, 0.6], [66, 142, 0.6], [72, 18, 0.8], [28, 18, 0.8]] as const) T.tree(g, x, y, s)
  for (const [x, y] of [[43, 52], [57, 52], [43, 118], [57, 118], [35, 146], [65, 146]] as const) T.lamp(g, x, y, 0.6, lit)
  if (rank >= 2) for (const [x, y] of [[36, 44], [64, 44], [33, 41], [67, 41]] as const) g.circle(x, y, 0.9, rgb(0xf2a3b8))
  if (rank >= 5) {
    T.bunting(g, 26, 74, 50, 5, 1)
    T.bunting(g, 26, 74, 76, 4, 1)
  }
  if (rank >= 6) {
    g.rect(32, 4, 36, 5, rgb(0xd9667a), 2.5)
    g.text('NGÀY HỘI COZII', 3, Color.white, pt(50, 6.6), 'bold')
  }
  // mây trôi
  const drift = (t * 0.8) % 140
  T.cloud(g, drift - 30, 6, 0.6, Color.white.opacity(0.75))
  T.cloud(g, ((drift + 70) % 140) - 30, 82, 0.5, Color.white.opacity(0.6))
  void R
}
