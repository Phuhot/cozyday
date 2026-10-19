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
              style={{ left: `${p.x}%`, top: `${((p.y + 10) / MAP_H) * 100}%`, outline: target === p.id ? '3px solid var(--lavender)' : undefined, borderRadius: 16 }}
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
  river.move(pt(-5, 92))
  river.addQuadCurve(pt(105, 88), pt(50, 100))
  g.stroke(river, rgb(0xa8d8ec), 7)
  g.stroke(river, rgb(0xc8e8f4), 3)
  // cầu
  g.rect(44, 89, 12, 9, rgb(0xd4b08a), 2)
  // đường chính
  T.road(g, [[50, 150], [50, 120], [50, 96], [50, 70], [50, 46], [50, 24]], 7)
  T.road(g, [[20, 52], [50, 58], [80, 52]], 4.5)
  T.road(g, [[22, 82], [50, 86], [78, 82]], 4.5)
  T.road(g, [[24, 114], [50, 118], [76, 116]], 4.5)
  T.road(g, [[16, 144], [50, 148], [84, 144]], 4)

  const lit = rank >= 3 ? 1 : rank >= 2 ? 0.5 : 0.15
  // Tòa thị chính (+ nhà Ông Trà phía sau)
  T.house(g, 50, 14, 16, { wall: rgb(0xfdf3e3), roof: rgb(0x9c7bd0), door: rgb(0xa07448), lit, sign: 'NHÀ ÔNG TRÀ' })
  T.house(g, 50, 30, 24, { wall: rgb(0xfffaf0), roof: rgb(0x8d78cf), door: rgb(0xa07448), lit, sign: 'THỊ CHÍNH' })
  // quảng trường + máy capsule
  g.ellipse(36, 50, 28, 12, rgb(0xf1e2c4))
  T.capsuleMachine(g, 50, 56, 0.9, t)
  if (rank >= 4) T.fountain(g, 38, 58, 0.55, t)
  // cửa hàng
  T.house(g, 20, 50, 20, { wall: rgb(0xf6e3cf), roof: rgb(0xb07a4c), door: rgb(0x8c5e3a), lit, sign: 'NỘI THẤT' })
  T.house(g, 80, 50, 20, { wall: rgb(0xf3e9f7), roof: rgb(0xd98aa6), door: rgb(0xa07448), lit, sign: 'TIỆM MAY' })
  T.house(g, 22, 80, 20, { wall: rgb(0xfdf0e2), roof: rgb(0xe59a7a), door: rgb(0xa07448), lit, awning: rgb(0xf2a3b8), sign: 'TIỆM BÁNH' })
  T.stall(g, 78, 80, 20, rgb(0x6f9a72))
  g.text('HẠT GIỐNG', 3.2, rgb(0x3e3550), pt(78, 66.5), 'bold')
  // bảng đơn hàng
  g.rect(46.5, 76, 7, 9, rgb(0xc89b6d), 1)
  g.rect(44, 70, 12, 8, rgb(0xfdf6ec), 1.5)
  for (let i = 0; i < 3; i++) g.rect(45.3 + i * 3.7, 71.5, 2.8, 3.5, rgb([0xf2a3b8, 0xf6d36b, 0x9ed4b6][i]), 0.5)
  // sân chơi
  g.ellipse(10, 104, 28, 14, rgb(0xf6e7c8))
  g.rect(15, 98, 2, 10, rgb(0xd9667a))
  g.rect(31, 98, 2, 10, rgb(0xd9667a))
  g.rect(14, 97, 20, 2, rgb(0xd9667a), 1)
  g.strokePath(rgb(0x7a6f86), 0.4, q => { q.move(pt(20, 99)); q.addLine(pt(20, 105)); q.move(pt(27, 99)); q.addLine(pt(27, 105)) })
  g.rect(18.5, 105, 3, 1, rgb(0x8d78cf), 0.5)
  g.rect(25.5, 105, 3, 1, rgb(0x8d78cf), 0.5)
  // vườn rau
  g.rect(64, 98, 26, 16, rgb(0xb48f66), 3)
  for (let i = 0; i < 3; i++) g.rect(66, 100 + i * 4.8, 22, 2.6, rgb(0x9c7650), 1.3)
  const planted = state.farm.plots.filter(p => p.crop).length
  for (let i = 0; i < Math.min(planted, 9); i++) g.circle(69 + (i % 3) * 8, 101.2 + Math.floor(i / 3) * 4.8, 1.4, rgb(0x7fbf7a))
  // nhà mình & nhà NPC
  T.house(g, 50, 146, 18, { wall: rgb(0xfffaf0), roof: rgb(0xa58bd9), door: rgb(0xc89b6d), lit: 1, sign: 'NHÀ MÌNH' })
  T.house(g, 16, 142, 15, { wall: rgb(0xf6e3cf), roof: rgb(0x8e6247), door: rgb(0x8c5e3a), lit })
  T.house(g, 84, 142, 15, { wall: rgb(0xe4efe2), roof: rgb(0x6f9a72), door: rgb(0xa07448), lit })
  // pet của bạn trước cửa
  paintPet(g.ctx, 58 * k, 136.5 * k, 10 * k, petAppearance(state), 'idle', restPose())
  // cây, đèn
  for (const [x, y, s] of [[6, 22, 1], [92, 24, 1.1], [8, 66, 0.9], [92, 66, 0.9], [6, 124, 1], [94, 124, 1.1], [34, 128, 0.7], [66, 130, 0.7], [70, 18, 0.8], [30, 18, 0.8]] as const) T.tree(g, x, y, s)
  for (const [x, y] of [[44, 40], [56, 40], [44, 108], [56, 108], [44, 132], [56, 132]] as const) T.lamp(g, x, y, 0.6, lit)
  if (rank >= 2) for (const [x, y] of [[40, 34], [60, 34], [36, 31], [64, 31]] as const) g.circle(x, y, 0.9, rgb(0xf2a3b8))
  if (rank >= 5) {
    T.bunting(g, 26, 74, 40, 5, 1)
    T.bunting(g, 26, 74, 64, 4, 1)
  }
  if (rank >= 6) {
    g.rect(32, 4, 36, 5, rgb(0xd9667a), 2.5)
    g.text('NGÀY HỘI COZII', 3, Color.white, pt(50, 6.6), 'bold')
  }
  // mây trôi
  const drift = (t * 0.8) % 140
  T.cloud(g, drift - 30, 6, 0.6, Color.white.opacity(0.75))
  T.cloud(g, ((drift + 70) % 140) - 30, 72, 0.5, Color.white.opacity(0.6))
  void R
}
