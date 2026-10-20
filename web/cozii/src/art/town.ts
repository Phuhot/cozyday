// Hình vẽ thị trấn Cozii (bản đồ, cốt truyện mở đầu) — vẽ bằng code, cùng phong cách với phòng của Cozyday.
import { GC, Color, rgb, pt, R, Path, linear } from './gc'

export function sky(g: GC, w: number, h: number, top: Color, bottom: Color) {
  g.fill(Path.rect(R(0, 0, w, h)), linear([top, bottom], pt(0, 0), pt(0, h)))
}

export function hill(g: GC, x0: number, x1: number, base: number, peak: number, color: Color) {
  const p = new Path()
  p.move(pt(x0, base))
  p.addQuadCurve(pt(x1, base), pt((x0 + x1) / 2, peak))
  p.addLine(pt(x1, base + 400))
  p.addLine(pt(x0, base + 400))
  p.closeSubpath()
  g.fill(p, color)
}

export function cloud(g: GC, x: number, y: number, s: number, color: Color) {
  g.rect(x, y + 3 * s, 20 * s, 5 * s, color, 2.5 * s)
  g.circle(x + 6 * s, y + 3.6 * s, 3.6 * s, color)
  g.circle(x + 11.5 * s, y + 2.6 * s, 4.6 * s, color)
  g.circle(x + 16 * s, y + 4.4 * s, 3 * s, color)
}

export function tree(g: GC, x: number, y: number, s: number, leaf = rgb(0x8ec48d), leaf2 = rgb(0xa6d4a1)) {
  g.ellipse(x - 7 * s, y - 1.2 * s, 14 * s, 3 * s, Color.black.opacity(0.08))
  g.rect(x - 1.2 * s, y - 8 * s, 2.4 * s, 8 * s, rgb(0xa07448), 1 * s)
  g.circle(x, y - 12 * s, 6.5 * s, leaf)
  g.circle(x - 3.5 * s, y - 9.5 * s, 4.5 * s, leaf)
  g.circle(x + 3.8 * s, y - 9.8 * s, 4.6 * s, leaf)
  g.circle(x - 1.5 * s, y - 14 * s, 3 * s, leaf2)
}

export function bush(g: GC, x: number, y: number, s: number, color = rgb(0x93c784)) {
  g.circle(x - 3 * s, y, 3 * s, color)
  g.circle(x + 0.5 * s, y - 1.4 * s, 3.6 * s, color)
  g.circle(x + 4 * s, y, 2.8 * s, color)
}

export interface HouseStyle {
  wall: Color
  roof: Color
  door: Color
  lit?: number // 0…1 đèn cửa sổ
  sign?: string
  awning?: Color
}

/** Một ngôi nhà nhỏ, đáy ở (x, y), rộng w. */
export function house(g: GC, x: number, y: number, w: number, st: HouseStyle) {
  const h = w * 0.62
  const left = x - w / 2
  g.ellipse(left - w * 0.06, y - w * 0.05, w * 1.12, w * 0.12, Color.black.opacity(0.08))
  g.rect(left, y - h, w, h, st.wall, w * 0.06)
  // mái
  const p = new Path()
  p.move(pt(left - w * 0.1, y - h + w * 0.04))
  p.addLine(pt(x, y - h - w * 0.42))
  p.addLine(pt(left + w * 1.1, y - h + w * 0.04))
  p.closeSubpath()
  g.fill(p, st.roof)
  g.strokePath(Color.white.opacity(0.25), w * 0.03, q => { q.move(pt(left + w * 0.05, y - h - w * 0.02)); q.addLine(pt(x - w * 0.05, y - h - w * 0.36)) })
  // cửa
  g.rect(x - w * 0.12, y - h * 0.55, w * 0.24, h * 0.55, st.door, w * 0.08)
  g.circle(x + w * 0.07, y - h * 0.27, w * 0.018, rgb(0xf0c26a))
  // cửa sổ
  const lit = st.lit ?? 0
  const winC = rgb(0xd9e9f2).mix(rgb(0xffe08a), lit)
  for (const side of [-1, 1]) {
    const wx = x + side * w * 0.3 - w * 0.1
    g.rect(wx, y - h * 0.75, w * 0.2, w * 0.18, rgb(0xfffaf0), w * 0.03)
    g.rect(wx + w * 0.015, y - h * 0.75 + w * 0.015, w * 0.17, w * 0.15, winC, w * 0.025)
    if (lit > 0.05) g.circle(wx + w * 0.1, y - h * 0.75 + w * 0.09, w * 0.16, rgb(0xffe08a).opacity(0.18 * lit))
  }
  if (st.awning) {
    for (let i = 0; i < 5; i++) {
      g.rect(left + (w / 5) * i, y - h - w * 0.02, w / 5, w * 0.1, i % 2 === 0 ? st.awning : Color.white, 0)
    }
  }
  if (st.sign) {
    g.rect(x - w * 0.3, y - h - w * 0.2, w * 0.6, w * 0.14, rgb(0xfffdf8), w * 0.04)
    g.text(st.sign, w * 0.09, rgb(0x3e3550), pt(x, y - h - w * 0.13), 'bold')
  }
}

export function lamp(g: GC, x: number, y: number, s: number, on: number) {
  g.rect(x - 0.4 * s, y - 10 * s, 0.8 * s, 10 * s, rgb(0x5a5068))
  g.rect(x - 1.6 * s, y - 12.5 * s, 3.2 * s, 3 * s, rgb(0x5a5068), 0.8 * s)
  g.rect(x - 1.1 * s, y - 12 * s, 2.2 * s, 2 * s, rgb(0xfdf0c8).mix(rgb(0xffd66b), on), 0.5 * s)
  if (on > 0.05) g.circle(x, y - 11 * s, 5 * s, rgb(0xffe08a).opacity(0.22 * on))
}

export function road(g: GC, pts: [number, number][], width: number, color = rgb(0xf1e2c4), edge = rgb(0xe2cfa8)) {
  const p = new Path()
  p.move(pt(pts[0][0], pts[0][1]))
  for (let i = 1; i < pts.length; i++) {
    const [x0, y0] = pts[i - 1]
    const [x1, y1] = pts[i]
    p.addQuadCurve(pt((x0 + x1) / 2, (y0 + y1) / 2), pt(x0, y0))
    if (i === pts.length - 1) p.addLine(pt(x1, y1))
  }
  g.stroke(p, edge, width + 2)
  g.stroke(p, color, width)
}

export function key(g: GC, x: number, y: number, s: number, rot = 0) {
  g.rotated(rot, pt(x, y), k => {
    k.circle(x - 6 * s, y, 4 * s, rgb(0xf0c26a))
    k.circle(x - 6 * s, y, 1.8 * s, rgb(0xfff4d0))
    k.rect(x - 2.5 * s, y - 1 * s, 11 * s, 2 * s, rgb(0xf0c26a), 1 * s)
    k.rect(x + 5 * s, y, 2 * s, 3.5 * s, rgb(0xf0c26a), 0.5 * s)
    k.rect(x + 2 * s, y, 2 * s, 2.6 * s, rgb(0xf0c26a), 0.5 * s)
  })
}

export function envelope(g: GC, x: number, y: number, w: number, open: number) {
  const h = w * 0.66
  g.rect(x - w / 2, y - h / 2, w, h, rgb(0xfdf3e3), w * 0.05)
  if (open > 0) {
    // lá thư nhô lên
    const lift = h * 0.55 * open
    g.rect(x - w * 0.4, y - h / 2 - lift, w * 0.8, h * 0.8, rgb(0xfffdf8), w * 0.03)
    g.strokePath(rgb(0xd9cbe8), w * 0.012, q => {
      for (let i = 0; i < 3; i++) {
        q.move(pt(x - w * 0.3, y - h / 2 - lift + h * (0.18 + i * 0.13)))
        q.addLine(pt(x + w * (i === 2 ? 0.1 : 0.3), y - h / 2 - lift + h * (0.18 + i * 0.13)))
      }
    })
    g.heart(pt(x + w * 0.24, y - h / 2 - lift + h * 0.58), w * 0.1, rgb(0xf27d9b))
  }
  // nắp
  const flap = new Path()
  flap.move(pt(x - w / 2, y - h / 2))
  flap.addLine(pt(x, y - h / 2 + h * 0.55 * (1 - open * 1.6)))
  flap.addLine(pt(x + w / 2, y - h / 2))
  flap.closeSubpath()
  g.fill(flap, rgb(0xf3e2c8))
  const front = new Path()
  front.move(pt(x - w / 2, y + h / 2))
  front.addLine(pt(x, y))
  front.addLine(pt(x + w / 2, y + h / 2))
  front.closeSubpath()
  g.fill(front, rgb(0xf6e8d2))
  g.circle(x, y - h * 0.02, w * 0.06, rgb(0xd9667a))
}

export function sparkle(g: GC, x: number, y: number, size: number, color: Color) {
  g.text('✦', size, color, pt(x, y))
}

/** Máy capsule ở quảng trường. */
export function capsuleMachine(g: GC, x: number, y: number, s: number, t = 0) {
  g.ellipse(x - 9 * s, y - 1.5 * s, 18 * s, 3 * s, Color.black.opacity(0.08))
  g.rect(x - 7 * s, y - 12 * s, 14 * s, 12 * s, rgb(0xe88aa6), 2.5 * s)
  g.rect(x - 4 * s, y - 7 * s, 8 * s, 4 * s, rgb(0xfff4f7), 1.5 * s)
  g.circle(x + 4 * s, y - 10 * s, 1.6 * s, rgb(0xf0c26a))
  g.circle(x, y - 18 * s, 8 * s, rgb(0xdff1fa).opacity(0.95))
  const cols = [0xf6d36b, 0x9ed4b6, 0xc9b6f0, 0xf4a9a0, 0x8fcde6]
  for (let i = 0; i < 6; i++) {
    const a = i * 1.1 + t * 0.6
    g.circle(x + Math.cos(a) * 4 * s, y - 18 * s + Math.sin(a * 1.3) * 3 * s, 2.2 * s, rgb(cols[i % cols.length]))
  }
  g.ellipse(x - 5 * s, y - 24 * s, 4 * s, 3 * s, Color.white.opacity(0.7))
  g.rect(x - 8 * s, y - 27 * s, 16 * s, 3 * s, rgb(0xe88aa6), 1.5 * s)
}

export function fountain(g: GC, x: number, y: number, s: number, t = 0) {
  g.ellipse(x - 12 * s, y - 4 * s, 24 * s, 8 * s, rgb(0xd8d0c4))
  g.ellipse(x - 10 * s, y - 3.6 * s, 20 * s, 5.6 * s, rgb(0x9fd3ea))
  g.rect(x - 1.2 * s, y - 12 * s, 2.4 * s, 9 * s, rgb(0xd8d0c4))
  for (let i = 0; i < 3; i++) {
    const k = ((t * 0.8 + i / 3) % 1)
    g.circle(x + (i - 1) * 3 * s * k, y - 12 * s - Math.sin(k * Math.PI) * 5 * s, 0.9 * s, rgb(0x9fd3ea).opacity(1 - k * 0.6))
  }
}

export function stall(g: GC, x: number, y: number, w: number, color: Color) {
  g.rect(x - w / 2, y - w * 0.32, w, w * 0.32, rgb(0xc89b6d), w * 0.04)
  for (let i = 0; i < 6; i++) g.rect(x - w / 2 + (w / 6) * i, y - w * 0.62, w / 6, w * 0.16, i % 2 === 0 ? color : Color.white)
  g.rect(x - w / 2 + w * 0.04, y - w * 0.48, w * 0.04, w * 0.18, rgb(0xa07448))
  g.rect(x + w / 2 - w * 0.08, y - w * 0.48, w * 0.04, w * 0.18, rgb(0xa07448))
  for (let i = 0; i < 4; i++) g.circle(x - w * 0.3 + i * w * 0.2, y - w * 0.36, w * 0.06, rgb([0xf2a65a, 0xe8566b, 0xf6d35e, 0x7fbf7a][i]))
}

export function bunting(g: GC, x0: number, x1: number, y: number, sag: number, s: number) {
  const cols = [0xf2a3b8, 0xf0c26a, 0x9ed4b6, 0xc9b6f0, 0x8fcde6]
  g.strokePath(rgb(0x8a7f99), 0.4 * s, q => { q.move(pt(x0, y)); q.addQuadCurve(pt(x1, y), pt((x0 + x1) / 2, y + sag)) })
  const n = 9
  for (let i = 1; i < n; i++) {
    const tt = i / n
    const px = x0 + (x1 - x0) * tt
    const py = y + 2 * sag * tt * (1 - tt) * 2 * 0.5 * 2
    g.polygon([pt(px - 1.6 * s, py), pt(px + 1.6 * s, py), pt(px, py + 3 * s)], rgb(cols[i % cols.length]))
  }
}
