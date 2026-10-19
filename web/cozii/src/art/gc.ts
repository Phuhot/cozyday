// Lớp vẽ mô phỏng SwiftUI GraphicsContext trên Canvas 2D.
// Hình vẽ của Cozyday (bản iOS) được chuyển gần như từng dòng sang TypeScript, nên lớp này giữ đúng ngữ nghĩa
// "giá trị" của GraphicsContext: sao chép ngữ cảnh rồi xoay/dịch/cắt không ảnh hưởng bản gốc.

export class Color {
  readonly r: number
  readonly g: number
  readonly b: number
  readonly a: number
  constructor(r: number, g: number, b: number, a = 1) {
    this.r = r
    this.g = g
    this.b = b
    this.a = a
  }
  opacity(k: number): Color {
    return new Color(this.r, this.g, this.b, this.a * k)
  }
  get css(): string {
    return `rgba(${this.r},${this.g},${this.b},${Math.max(0, Math.min(1, this.a))})`
  }
  /** Trộn tuyến tính hai màu. */
  mix(o: Color, t: number): Color {
    return new Color(
      Math.round(this.r + (o.r - this.r) * t),
      Math.round(this.g + (o.g - this.g) * t),
      Math.round(this.b + (o.b - this.b) * t),
      this.a + (o.a - this.a) * t,
    )
  }
  static readonly white = new Color(255, 255, 255)
  static readonly black = new Color(0, 0, 0)
  static readonly clear = new Color(0, 0, 0, 0)
  static rgb01(r: number, g: number, b: number, a = 1): Color {
    return new Color(Math.round(r * 255), Math.round(g * 255), Math.round(b * 255), a)
  }
}

/** Màu cố định từ mã hex (0xRRGGBB). */
export function rgb(hex: number): Color {
  return new Color((hex >> 16) & 0xff, (hex >> 8) & 0xff, hex & 0xff)
}

export class Pt {
  readonly x: number
  readonly y: number
  constructor(x: number, y: number) {
    this.x = x
    this.y = y
  }
}
export function pt(x: number, y: number): Pt {
  return new Pt(x, y)
}

export class Rect {
  readonly x: number
  readonly y: number
  readonly width: number
  readonly height: number
  constructor(x: number, y: number, w: number, h: number) {
    this.x = x
    this.y = y
    this.width = w
    this.height = h
  }
  get minX() { return this.x }
  get minY() { return this.y }
  get maxX() { return this.x + this.width }
  get maxY() { return this.y + this.height }
  get midX() { return this.x + this.width / 2 }
  get midY() { return this.y + this.height / 2 }
  insetBy(dx: number, dy: number): Rect {
    return new Rect(this.x + dx, this.y + dy, this.width - dx * 2, this.height - dy * 2)
  }
  offsetBy(dx: number, dy: number): Rect {
    return new Rect(this.x + dx, this.y + dy, this.width, this.height)
  }
}
export function R(x: number, y: number, w: number, h: number): Rect {
  return new Rect(x, y, w, h)
}

export const deg = (d: number) => (d * Math.PI) / 180

type Cmd =
  | ['M', number, number]
  | ['L', number, number]
  | ['Q', number, number, number, number]
  | ['C', number, number, number, number, number, number]
  | ['A', number, number, number, number, number, boolean]
  | ['E', number, number, number, number]
  | ['RR', number, number, number, number, number]
  | ['Z']

/** Đường vẽ ghi lại lệnh (như SwiftUI Path), dựng thành Path2D khi cần. */
export class Path {
  private cmds: Cmd[] = []
  private cached: Path2D | null = null
  private cur: Pt | null = null

  static ellipse(r: Rect): Path {
    const p = new Path()
    p.addEllipse(r)
    return p
  }
  static roundedRect(r: Rect, radius: number): Path {
    const p = new Path()
    p.addRoundedRect(r, radius)
    return p
  }
  static rect(r: Rect): Path {
    const p = new Path()
    p.addRect(r)
    return p
  }

  private push(c: Cmd) {
    this.cmds.push(c)
    this.cached = null
  }
  move(to: Pt) {
    this.push(['M', to.x, to.y])
    this.cur = to
  }
  addLine(to: Pt) {
    if (!this.cur) this.move(to)
    else this.push(['L', to.x, to.y])
    this.cur = to
  }
  addLines(pts: Pt[]) {
    if (pts.length === 0) return
    this.move(pts[0])
    for (let i = 1; i < pts.length; i++) this.addLine(pts[i])
  }
  addQuadCurve(to: Pt, control: Pt) {
    if (!this.cur) this.move(control)
    this.push(['Q', control.x, control.y, to.x, to.y])
    this.cur = to
  }
  addCurve(to: Pt, c1: Pt, c2: Pt) {
    if (!this.cur) this.move(c1)
    this.push(['C', c1.x, c1.y, c2.x, c2.y, to.x, to.y])
    this.cur = to
  }
  /** Cùng quy ước với SwiftUI: clockwise=false ⇒ góc tăng dần (Canvas anticlockwise=false). */
  addArc(center: Pt, radius: number, start: number, end: number, clockwise: boolean) {
    this.push(['A', center.x, center.y, radius, start, end, clockwise])
    this.cur = new Pt(center.x + radius * Math.cos(end), center.y + radius * Math.sin(end))
  }
  addEllipse(r: Rect) {
    this.push(['E', r.x, r.y, r.width, r.height])
    this.cur = null
  }
  addRect(r: Rect) {
    this.push(['RR', r.x, r.y, r.width, r.height, 0])
    this.cur = null
  }
  addRoundedRect(r: Rect, radius: number) {
    this.push(['RR', r.x, r.y, r.width, r.height, radius])
    this.cur = null
  }
  closeSubpath() {
    this.push(['Z'])
  }

  build(): Path2D {
    if (this.cached) return this.cached
    const p = new Path2D()
    for (const c of this.cmds) {
      switch (c[0]) {
        case 'M': p.moveTo(c[1], c[2]); break
        case 'L': p.lineTo(c[1], c[2]); break
        case 'Q': p.quadraticCurveTo(c[1], c[2], c[3], c[4]); break
        case 'C': p.bezierCurveTo(c[1], c[2], c[3], c[4], c[5], c[6]); break
        case 'A': p.arc(c[1], c[2], Math.max(0, c[3]), c[4], c[5], c[6]); break
        case 'E': {
          const [, x, y, w, h] = c
          if (w <= 0 || h <= 0) break
          p.moveTo(x + w, y + h / 2)
          p.ellipse(x + w / 2, y + h / 2, w / 2, h / 2, 0, 0, Math.PI * 2)
          p.closePath()
          break
        }
        case 'RR': {
          const [, x, y, w, h, r0] = c
          if (w <= 0 || h <= 0) break
          const r = Math.max(0, Math.min(r0, w / 2, h / 2))
          if (r === 0) {
            p.rect(x, y, w, h)
          } else {
            p.moveTo(x + r, y)
            p.lineTo(x + w - r, y)
            p.arcTo(x + w, y, x + w, y + r, r)
            p.lineTo(x + w, y + h - r)
            p.arcTo(x + w, y + h, x + w - r, y + h, r)
            p.lineTo(x + r, y + h)
            p.arcTo(x, y + h, x, y + h - r, r)
            p.lineTo(x, y + r)
            p.arcTo(x, y, x + r, y, r)
            p.closePath()
          }
          break
        }
        case 'Z': p.closePath(); break
      }
    }
    this.cached = p
    return p
  }
}

export type Paint = Color | Gradient

export class Gradient {
  readonly colors: Color[]
  readonly kind: 'linear' | 'radial'
  readonly a: Pt
  readonly b: Pt
  readonly r0: number
  readonly r1: number
  constructor(kind: 'linear' | 'radial', colors: Color[], a: Pt, b: Pt, r0 = 0, r1 = 0) {
    this.kind = kind
    this.colors = colors
    this.a = a
    this.b = b
    this.r0 = r0
    this.r1 = r1
  }
}
export function linear(colors: Color[], start: Pt, end: Pt): Gradient {
  return new Gradient('linear', colors, start, end)
}
export function radial(colors: Color[], center: Pt, startRadius: number, endRadius: number): Gradient {
  return new Gradient('radial', colors, center, center, startRadius, endRadius)
}

type M = [number, number, number, number, number, number]
const ID: M = [1, 0, 0, 1, 0, 0]
function mul(m: M, n: M): M {
  return [
    m[0] * n[0] + m[2] * n[1],
    m[1] * n[0] + m[3] * n[1],
    m[0] * n[2] + m[2] * n[3],
    m[1] * n[2] + m[3] * n[3],
    m[0] * n[4] + m[2] * n[5] + m[4],
    m[1] * n[4] + m[3] * n[5] + m[5],
  ]
}

interface Clip {
  path: Path2D
  m: M
}

export const FONT_STACK = '"Nunito", ui-rounded, "SF Pro Rounded", system-ui, -apple-system, "Segoe UI", sans-serif'

/**
 * Ngữ cảnh vẽ kiểu giá trị. `copy()` tạo bản sao độc lập (tương đương `var c = ctx` trong Swift);
 * các phép dịch/xoay/cắt chỉ áp dụng cho bản đó.
 */
export class GC {
  readonly ctx: CanvasRenderingContext2D
  private m: M
  private clips: Clip[]
  private alpha: number

  constructor(ctx: CanvasRenderingContext2D, m: M = ID, clips: Clip[] = [], alpha = 1) {
    this.ctx = ctx
    this.m = m
    this.clips = clips
    this.alpha = alpha
  }

  copy(): GC {
    return new GC(this.ctx, this.m, this.clips.slice(), this.alpha)
  }

  translateBy(x: number, y: number) {
    this.m = mul(this.m, [1, 0, 0, 1, x, y])
  }
  /** Góc tính bằng radian. */
  rotate(rad: number) {
    const c = Math.cos(rad), s = Math.sin(rad)
    this.m = mul(this.m, [c, s, -s, c, 0, 0])
  }
  scaleBy(x: number, y: number) {
    this.m = mul(this.m, [x, 0, 0, y, 0, 0])
  }
  /** Nhân độ mờ cho mọi nét vẽ sau (như `ctx.opacity`). */
  setOpacity(a: number) {
    this.alpha = a
  }
  clip(path: Path) {
    this.clips.push({ path: path.build(), m: this.m })
  }

  private begin() {
    const c = this.ctx
    c.save()
    const base = c.getTransform()
    for (const cl of this.clips) {
      c.setTransform(base.multiply(new DOMMatrix(cl.m)))
      c.clip(cl.path)
    }
    c.setTransform(base.multiply(new DOMMatrix(this.m)))
    c.globalAlpha *= this.alpha
  }

  private paint(p: Paint): string | CanvasGradient {
    if (p instanceof Color) return p.css
    const c = this.ctx
    const g =
      p.kind === 'linear'
        ? c.createLinearGradient(p.a.x, p.a.y, p.b.x, p.b.y)
        : c.createRadialGradient(p.a.x, p.a.y, p.r0, p.a.x, p.a.y, p.r1)
    const n = p.colors.length
    p.colors.forEach((col, i) => g.addColorStop(n === 1 ? 0 : i / (n - 1), col.css))
    return g
  }

  fill(path: Path, paint: Paint) {
    const c = this.ctx
    this.begin()
    c.fillStyle = this.paint(paint)
    c.fill(path.build())
    c.restore()
  }

  stroke(path: Path, paint: Paint, width: number, opts?: { cap?: CanvasLineCap; join?: CanvasLineJoin; dash?: number[] }) {
    const c = this.ctx
    this.begin()
    c.strokeStyle = this.paint(paint)
    c.lineWidth = width
    c.lineCap = opts?.cap ?? 'round'
    c.lineJoin = opts?.join ?? 'round'
    if (opts?.dash) c.setLineDash(opts.dash)
    c.stroke(path.build())
    c.restore()
  }

  ellipse(x: number, y: number, w: number, h: number, color: Paint) {
    this.fill(Path.ellipse(R(x, y, w, h)), color)
  }
  rect(x: number, y: number, w: number, h: number, color: Paint, radius = 0) {
    this.fill(Path.roundedRect(R(x, y, w, h), radius), color)
  }
  polygon(points: Pt[], color: Paint) {
    const p = new Path()
    p.addLines(points)
    p.closeSubpath()
    this.fill(p, color)
  }
  strokePath(color: Paint, width: number, build: (p: Path) => void) {
    const p = new Path()
    build(p)
    this.stroke(p, color, width)
  }
  circle(cx: number, cy: number, r: number, color: Paint) {
    this.ellipse(cx - r, cy - r, r * 2, r * 2, color)
  }
  /** Vẽ trong hệ tọa độ đã xoay `degrees` độ quanh điểm `c`. */
  rotated(degrees: number, c: Pt, draw: (g: GC) => void) {
    const g = this.copy()
    g.translateBy(c.x, c.y)
    g.rotate(deg(degrees))
    g.translateBy(-c.x, -c.y)
    draw(g)
  }
  heart(c: Pt, s: number, color: Paint) {
    this.fill(heartPath(c, s), color)
  }
  /** Chữ/ký hiệu đặt tâm tại `at` (như `ctx.draw(Text(...), at:)`). */
  text(str: string, size: number, color: Color, at: Pt, weight: 'normal' | 'bold' | 'semibold' = 'normal') {
    const c = this.ctx
    this.begin()
    c.fillStyle = color.css
    const w = weight === 'bold' ? 800 : weight === 'semibold' ? 700 : 500
    c.font = `${w} ${size}px ${FONT_STACK}`
    c.textAlign = 'center'
    c.textBaseline = 'middle'
    c.fillText(str, at.x, at.y)
    c.restore()
  }
}

export function heartPath(c: Pt, s: number): Path {
  const p = new Path()
  p.move(pt(c.x, c.y + s * 0.35))
  p.addCurve(pt(c.x - s * 0.5, c.y - s * 0.1), pt(c.x - s * 0.1, c.y + s * 0.1), pt(c.x - s * 0.5, c.y + s * 0.15))
  p.addArc(pt(c.x - s * 0.25, c.y - s * 0.12), s * 0.25, deg(180), deg(0), false)
  p.addArc(pt(c.x + s * 0.25, c.y - s * 0.12), s * 0.25, deg(180), deg(0), false)
  p.addCurve(pt(c.x, c.y + s * 0.35), pt(c.x + s * 0.5, c.y + s * 0.15), pt(c.x + s * 0.1, c.y + s * 0.1))
  p.closeSubpath()
  return p
}
