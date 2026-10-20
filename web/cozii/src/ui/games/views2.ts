// Phần vẽ & điều khiển của Vườn Nốt Nhạc, Đường Về Nhà, Xếp Giỏ Picnic.
import { Rhythm, SONGS, midiHz, JUDGE } from '../../games/rhythm'
import { Runner, RUNNER } from '../../games/runner'
import { PicnicBoard, generatePuzzle, rotate, PICNIC_FOODS, type Placement } from '../../games/picnic'
import { GC, rgb, Color, pt, R, Path, linear } from '../../art/gc'
import * as T from '../../art/town'
import { petSprite } from '../../art'
import { restPose, type PetAppearance } from '../../content/pet'
import { playNote } from '../../app/sound'
import type { RunResult } from '../../core/games'
import type { GameOpts, GameView, HudItem } from './types'

function sprite(a: PetAppearance, happy: boolean, px: number, lifted = false) {
  const pose = restPose()
  if (happy) pose.petted = 1
  if (lifted) pose.lifted = true
  return petSprite(a, happy ? 'happy' : 'idle', pose, px, happy ? 'happy' : lifted ? 'surprised' : 'idle')
}

export function rhythmOffsetMs(): number {
  try {
    return Math.max(-250, Math.min(250, Number(localStorage.getItem('cozii:rhythmOffset') ?? 0) || 0))
  } catch {
    return 0
  }
}

// ---------------- Vườn Nốt Nhạc ----------------

const LANE_COLORS = [0xf2a3b8, 0xa9ddb8, 0xb7a6f0]
const LANE_KEYS: Record<string, number> = { ArrowLeft: 0, ArrowDown: 1, ArrowRight: 2, a: 0, s: 1, d: 2, j: 0, k: 1, l: 2 }

export class RhythmView implements GameView {
  readonly aspect = 0.62
  private e: Rhythm
  private o: GameOpts
  private flash: { lane: number; t: number; kind: string }[] = []
  private pressed = [0, 0, 0]
  private lastJudge: { text: string; t: number } | null = null

  constructor(o: GameOpts) {
    this.o = o
    const song = SONGS.find(s => s.id === o.variant) ?? SONGS[0]
    this.e = new Rhythm(song, rhythmOffsetMs())
  }
  step(dt: number) {
    const due = this.e.step(dt)
    for (const n of due) {
      n.played = true
      // Nốt phát đúng lúc chạm vạch (cue âm thanh); khi tắt tiếng vẫn chơi được bằng cue hình ảnh.
      const lead = Math.max(0, n.t - this.e.time)
      setTimeoutSafe(() => playNote(midiHz(n.midi), 0.28, 'triangle', 0.18), lead * 1000)
    }
    for (const f of this.flash) f.t += dt * 3
    this.flash = this.flash.filter(f => f.t < 1)
    this.pressed = this.pressed.map(p => Math.max(0, p - dt * 5))
    if (this.lastJudge) this.lastJudge.t += dt
  }
  render(c: CanvasRenderingContext2D, w: number, h: number) {
    const g = new GC(c)
    g.fill(Path.rect(R(0, 0, w, h)), linear([rgb(0xe9f4e4), rgb(0xfdf1e4)], pt(0, 0), pt(0, h)))
    const laneW = w / 3
    const hitY = h * 0.84
    const travel = 1.6
    for (let i = 0; i < 3; i++) {
      g.rect(i * laneW + laneW * 0.08, 0, laneW * 0.84, h, rgb(LANE_COLORS[i]).opacity(0.12 + this.pressed[i] * 0.2), laneW * 0.2)
      // bông hoa ở vạch chạm
      const cx = i * laneW + laneW / 2
      for (let p = 0; p < 6; p++) g.rotated(p * 60, pt(cx, hitY), q => q.ellipse(cx - laneW * 0.07, hitY - laneW * 0.26, laneW * 0.14, laneW * 0.22, rgb(LANE_COLORS[i]).opacity(0.85)))
      g.circle(cx, hitY, laneW * 0.11, rgb(0xf6d35e))
    }
    for (const n of this.e.notes) {
      if (n.judged === 'perfect' || n.judged === 'good') continue
      const dtn = n.t - (this.e.time - this.e.offset)
      if (dtn > travel || dtn < -0.3) continue
      const y = hitY - (dtn / travel) * hitY
      const cx = n.lane * laneW + laneW / 2
      const col = rgb(LANE_COLORS[n.lane])
      g.circle(cx, y, laneW * 0.16, n.judged === 'miss' ? col.opacity(0.3) : col)
      g.text('♪', laneW * 0.2, Color.white, pt(cx, y), 'bold')
    }
    for (const f of this.flash) {
      const cx = f.lane * laneW + laneW / 2
      g.circle(cx, hitY, laneW * (0.2 + f.t * 0.3), rgb(0xffe08a).opacity(0.5 * (1 - f.t)))
    }
    if (this.lastJudge && this.lastJudge.t < 0.8) g.text(this.lastJudge.text, w * 0.07, rgb(0x6f5ab8).opacity(1 - this.lastJudge.t), pt(w / 2, h * 0.62), 'bold')
    const size = w * 0.26
    const dance = this.e.combo > 0 && !this.o.reduceMotion ? Math.abs(Math.sin(this.e.time * Math.PI * (this.e.song.bpm / 60))) * size * 0.06 : 0
    c.drawImage(sprite(this.o.appearance, this.e.combo >= 5, size), w - size - 4, 6 - dance, size, size)
    if (this.e.combo >= 3) g.text(`Chuỗi ${this.e.combo}`, w * 0.05, rgb(0x6f5ab8), pt(w * 0.2, h * 0.08), 'bold')
  }
  private hit(lane: number) {
    this.pressed[lane] = 1
    const r = this.e.tap(lane)
    if (r) {
      this.flash.push({ lane, t: 0, kind: r })
      this.lastJudge = { text: r === 'perfect' ? 'Tuyệt!' : 'Tốt', t: 0 }
    }
  }
  pointer(type: 'down' | 'move' | 'up', x: number, _y: number, w: number) {
    if (type === 'down') this.hit(Math.max(0, Math.min(2, Math.floor((x / w) * 3))))
  }
  key(type: 'down' | 'up', key: string) {
    if (type === 'down' && key in LANE_KEYS) this.hit(LANE_KEYS[key])
  }
  hud(): HudItem[] {
    return [{ label: 'Bài', value: this.e.song.name }, { label: 'Chính xác', value: `${this.e.accuracy}%` }]
  }
  over() {
    return this.e.over
  }
  result(completed: boolean): RunResult {
    return { game: 'rhythm', completed: completed && this.e.over, song: this.e.song.id, accuracy: this.e.accuracy, hits: this.e.perfect + this.e.good, total: this.e.total, duration: this.e.duration }
  }
  dispose() {
    disposed.add(this)
  }
}

const disposed = new WeakSet<object>()
const timers = new Set<number>()
function setTimeoutSafe(fn: () => void, ms: number) {
  const id = window.setTimeout(() => {
    timers.delete(id)
    fn()
  }, ms)
  timers.add(id)
}
/** Hủy mọi nốt nhạc đã hẹn (khi tạm dừng / thoát / chơi lại). */
export function cancelScheduledNotes() {
  for (const id of timers) clearTimeout(id)
  timers.clear()
}
void JUDGE

// ---------------- Đường Về Nhà ----------------

export class RunnerView implements GameView {
  readonly aspect = 0.62
  private e: Runner
  private o: GameOpts
  private swipe: { x: number; y: number; done: boolean } | null = null
  private pops: { lane: number; t: number }[] = []

  constructor(o: GameOpts) {
    this.o = o
    this.e = new Runner(o.seed)
  }
  step(dt: number) {
    for (const ev of this.e.step(dt)) {
      if (ev === 'berry') {
        this.o.sfx('star')
        this.pops.push({ lane: Math.round(this.e.laneX), t: 0 })
      }
      if (ev === 'hit') this.o.sfx('hit')
    }
    for (const p of this.pops) p.t += dt * 2
    this.pops = this.pops.filter(p => p.t < 1)
  }
  render(c: CanvasRenderingContext2D, w: number, h: number, t: number) {
    const e = this.e
    const g = new GC(c)
    const horizon = h * 0.3
    T.sky(g, w, horizon + 2, rgb(0xbfe0f5), rgb(0xfdebdd))
    T.cloud(g, w * 0.08 - ((t * 6) % 40), h * 0.06, w / 140, Color.white.opacity(0.9))
    g.rect(0, horizon, w, h - horizon, rgb(0xb8e0a2))
    // con đường thu về chân trời
    const roadTop = w * 0.12, roadBottom = w * 0.96
    const road = new Path()
    road.move(pt(w / 2 - roadTop / 2, horizon))
    road.addLine(pt(w / 2 + roadTop / 2, horizon))
    road.addLine(pt(w / 2 + roadBottom / 2, h))
    road.addLine(pt(w / 2 - roadBottom / 2, h))
    road.closeSubpath()
    g.fill(road, rgb(0xf1e2c4))
    // nhà ở cuối đường
    T.house(g, w / 2, horizon + 1, w * 0.12, { wall: rgb(0xfffaf0), roof: rgb(0xa58bd9), door: rgb(0xc89b6d), lit: 1 })
    const view = RUNNER.view
    const proj = (z: number, lane: number) => {
      const d = Math.max(0.001, z - e.dist)
      const k = 1 / (1 + d / 6)
      const y = horizon + (h - horizon) * k
      const width = roadTop + (roadBottom - roadTop) * k
      const x = w / 2 + ((lane - 1) / 3) * width
      return { x, y, s: k }
    }
    // vạch kẻ làn chạy
    for (let i = 0; i < 12; i++) {
      const z = Math.floor(e.dist / 4) * 4 + i * 4
      for (const lane of [0.5, 1.5]) {
        const a = proj(z, lane), b = proj(z + 1.6, lane)
        g.strokePath(Color.white.opacity(0.8), Math.max(1, 4 * a.s), q => { q.move(pt(a.x, a.y)); q.addLine(pt(b.x, b.y)) })
      }
    }
    // hàng vật cản, vẽ từ xa tới gần
    const rows = e.rows.filter(r => r.z > e.dist - 1 && r.z < e.dist + view).sort((a, b) => b.z - a.z)
    for (const r of rows) {
      r.cells.forEach((cell, lane) => {
        if (cell === 'none') return
        const p = proj(r.z, lane)
        const s = p.s * w * 0.22
        if (cell === 'berry' && !r.taken?.[lane]) {
          g.circle(p.x, p.y - s * 0.3, s * 0.22, rgb(0xe8566b))
          g.polygon([pt(p.x - s * 0.12, p.y - s * 0.5), pt(p.x, p.y - s * 0.6), pt(p.x + s * 0.12, p.y - s * 0.5)], rgb(0x6faf62))
        } else if (cell === 'fence') {
          g.rect(p.x - s * 0.45, p.y - s * 0.32, s * 0.9, s * 0.08, rgb(0xd4b08a), s * 0.03)
          g.rect(p.x - s * 0.45, p.y - s * 0.18, s * 0.9, s * 0.08, rgb(0xd4b08a), s * 0.03)
          for (const dx of [-0.38, 0, 0.38]) g.rect(p.x + dx * s - s * 0.04, p.y - s * 0.4, s * 0.08, s * 0.4, rgb(0xc89b6d), s * 0.03)
        } else if (cell === 'cart') {
          g.rect(p.x - s * 0.4, p.y - s * 0.75, s * 0.8, s * 0.55, rgb(0xd98a5a), s * 0.08)
          g.rect(p.x - s * 0.42, p.y - s * 0.8, s * 0.84, s * 0.12, rgb(0xb06a3c), s * 0.05)
          for (const dx of [-0.25, 0.25]) g.circle(p.x + dx * s, p.y - s * 0.16, s * 0.14, rgb(0x6b5a7a))
          for (let i = 0; i < 3; i++) g.circle(p.x - s * 0.2 + i * s * 0.2, p.y - s * 0.82, s * 0.1, rgb([0xf2a65a, 0xf6d35e, 0x7fbf7a][i]))
        }
      })
    }
    // bạn nhỏ
    const size = w * 0.26
    const px = w / 2 + ((e.laneX - 1) / 3) * roadBottom * 0.92
    const py = h - size * 0.98 - e.jumpHeight * size * 0.35
    g.ellipse(px - size * 0.3, h - size * 0.12, size * 0.6, size * 0.1, Color.black.opacity(0.12))
    // vừa va chạm: mờ nhẹ theo nhịp (không biến mất hẳn, không nháy khi bật giảm chuyển động)
    const faded = e.invulnerable && (this.o.reduceMotion || Math.floor(t * 8) % 2 === 0)
    c.save()
    if (faded) c.globalAlpha = 0.45
    c.drawImage(sprite(this.o.appearance, e.airborne, size, e.invulnerable), px - size / 2, py, size, size)
    c.restore()
    for (const p of this.pops) {
      const x = w / 2 + ((p.lane - 1) / 3) * roadBottom * 0.92
      g.text('+1', w * 0.06, rgb(0xd9667a).opacity(1 - p.t), pt(x, py - p.t * 30), 'bold')
    }
  }
  pointer(type: 'down' | 'move' | 'up', x: number, y: number) {
    if (type === 'down') this.swipe = { x, y, done: false }
    else if (type === 'move' && this.swipe && !this.swipe.done) {
      const dx = x - this.swipe.x, dy = y - this.swipe.y
      if (Math.abs(dx) > 28 && Math.abs(dx) > Math.abs(dy)) {
        if (this.e.move(dx < 0 ? -1 : 1)) this.o.sfx('swish')
        this.swipe.done = true
      } else if (dy < -28) {
        if (this.e.jump()) this.o.sfx('jump')
        this.swipe.done = true
      }
    } else if (type === 'up') {
      if (this.swipe && !this.swipe.done) {
        if (this.e.jump()) this.o.sfx('jump')
      }
      this.swipe = null
    }
  }
  key(type: 'down' | 'up', key: string) {
    if (type !== 'down') return
    if (key === 'ArrowLeft' || key === 'a') this.e.move(-1) && this.o.sfx('swish')
    if (key === 'ArrowRight' || key === 'd') this.e.move(1) && this.o.sfx('swish')
    if (key === 'ArrowUp' || key === ' ' || key === 'w') this.e.jump() && this.o.sfx('jump')
  }
  hud(): HudItem[] {
    return [{ label: 'Quãng đường', value: `${this.e.meters} m` }, { label: 'Dâu', value: String(this.e.berries) }, { label: 'Tim', value: '♥'.repeat(Math.max(0, this.e.hearts)) || '0' }]
  }
  over() {
    return this.e.over
  }
  result(completed: boolean): RunResult {
    return { game: 'runner', completed: completed && this.e.over, meters: this.e.meters, berries: this.e.berries }
  }
  dispose() {}
}

// ---------------- Xếp Giỏ Picnic ----------------

const FOOD_COLORS = [0xf2c97a, 0xf2a3b8, 0xb7a6f0, 0xffffff, 0xd9a865, 0xf2a65a, 0xe8566b, 0xf6d35e, 0xe0a060]

export class PicnicView implements GameView {
  readonly aspect = 0.72
  private b: PicnicBoard
  private o: GameOpts
  private time = 0
  private rot = new Map<number, number>()
  private selected: number | null = null
  private drag: { piece: number; x: number; y: number; moved: boolean; fromBoard: boolean } | null = null
  private layoutCache: { cell: number; gx: number; gy: number; tray: { id: number; x: number; y: number; cs: number }[]; btns: Record<string, [number, number, number, number]> } | null = null
  private done = false

  constructor(o: GameOpts) {
    this.o = o
    const diff = o.variant === 'hard' ? 3 : o.variant === 'easy' ? 0 : 1
    this.b = new PicnicBoard(generatePuzzle(o.seed, diff))
    for (const p of this.b.puzzle.pieces) this.rot.set(p.id, 0)
  }

  step(dt: number) {
    this.time += dt
    if (!this.done && this.b.solved) {
      this.done = true
      this.o.sfx('good')
    }
  }

  private layout(w: number, h: number) {
    const P = this.b.puzzle
    const cell = Math.min((w * 0.86) / P.cols, (h * 0.42) / P.rows)
    const gx = (w - cell * P.cols) / 2
    const gy = h * 0.1
    const trayTop = gy + cell * P.rows + h * 0.08
    const free = P.pieces.filter(p => !this.b.placements.has(p.id))
    const cs = Math.min(cell * 0.55, w / 14)
    const tray: { id: number; x: number; y: number; cs: number }[] = []
    let x = w * 0.04, y = trayTop
    for (const p of free) {
      const shape = rotate(p.cells, this.rot.get(p.id) ?? 0)
      const pw = (Math.max(...shape.map(s => s[0])) + 1) * cs
      const ph = (Math.max(...shape.map(s => s[1])) + 1) * cs
      if (x + pw > w * 0.96) {
        x = w * 0.04
        y += cs * 3.4
      }
      tray.push({ id: p.id, x, y, cs })
      x += pw + cs * 0.8
      void ph
    }
    const bw = w * 0.28
    const btns: Record<string, [number, number, number, number]> = {
      rotate: [w * 0.06, h - h * 0.09, bw, h * 0.07],
      hint: [w * 0.36, h - h * 0.09, bw, h * 0.07],
      clear: [w * 0.66, h - h * 0.09, bw, h * 0.07],
    }
    this.layoutCache = { cell, gx, gy, tray, btns }
    return this.layoutCache
  }

  private drawPiece(g: GC, id: number, x: number, y: number, cs: number, alpha = 1) {
    const piece = this.b.puzzle.pieces.find(p => p.id === id)!
    const shape = rotate(piece.cells, this.rot.get(id) ?? 0)
    const col = rgb(FOOD_COLORS[piece.food % FOOD_COLORS.length])
    for (const [c, r] of shape) {
      g.rect(x + c * cs + cs * 0.04, y + r * cs + cs * 0.04, cs * 0.92, cs * 0.92, col.opacity(alpha), cs * 0.22)
      g.rect(x + c * cs + cs * 0.14, y + r * cs + cs * 0.12, cs * 0.3, cs * 0.14, Color.white.opacity(0.5 * alpha), cs * 0.07)
    }
    const [c0, r0] = shape[0]
    g.text(foodGlyph(piece.food), cs * 0.5, rgb(0x3e3550).opacity(0.75 * alpha), pt(x + c0 * cs + cs / 2, y + r0 * cs + cs * 0.55))
  }

  render(c: CanvasRenderingContext2D, w: number, h: number) {
    const g = new GC(c)
    const P = this.b.puzzle
    const L = this.layout(w, h)
    g.rect(0, 0, w, h, rgb(0xeaf4e2))
    for (let i = 0; i < 14; i++) for (let j = 0; j < 20; j++) if ((i + j) % 2 === 0) g.rect((i * w) / 14, (j * h) / 20, w / 14, h / 20, rgb(0xf2a3b8).opacity(0.12))
    // giỏ
    g.rect(L.gx - L.cell * 0.25, L.gy - L.cell * 0.25, L.cell * (P.cols + 0.5), L.cell * (P.rows + 0.5), rgb(0xc89b6d), L.cell * 0.3)
    g.strokePath(rgb(0xa07448), L.cell * 0.08, q => {
      q.move(pt(L.gx + L.cell * 0.4, L.gy - L.cell * 0.2))
      q.addQuadCurve(pt(L.gx + L.cell * (P.cols - 0.4), L.gy - L.cell * 0.2), pt(L.gx + (L.cell * P.cols) / 2, L.gy - L.cell * 1.1))
    })
    for (let r = 0; r < P.rows; r++) for (let cc = 0; cc < P.cols; cc++) {
      if (!P.mask[cc + r * P.cols]) continue
      g.rect(L.gx + cc * L.cell + 2, L.gy + r * L.cell + 2, L.cell - 4, L.cell - 4, rgb(0xfdf3e3), L.cell * 0.18)
    }
    for (const [id, pl] of this.b.placements) {
      if (this.drag?.piece === id && this.drag.moved) continue
      this.drawPiece(g, id, L.gx + pl.col * L.cell, L.gy + pl.row * L.cell, L.cell)
    }
    for (const t of L.tray) {
      if (this.drag?.piece === t.id && this.drag.moved) continue
      if (this.selected === t.id) g.rect(t.x - t.cs * 0.2, t.y - t.cs * 0.2, t.cs * 3.4, t.cs * 3.4, rgb(0x8d78cf).opacity(0.15), t.cs * 0.4)
      this.drawPiece(g, t.id, t.x, t.y, t.cs)
    }
    if (this.drag?.moved) {
      const snap = this.snapTarget(this.drag.piece, this.drag.x, this.drag.y)
      if (snap && this.b.fits(snap)) this.drawPiece(g, snap.piece, L.gx + snap.col * L.cell, L.gy + snap.row * L.cell, L.cell, 0.35)
      this.drawPiece(g, this.drag.piece, this.drag.x - L.cell / 2, this.drag.y - L.cell / 2, L.cell, 0.95)
    }
    const labels: Record<string, string> = { rotate: '⟳ Xoay', hint: 'Gợi ý', clear: 'Xếp lại' }
    for (const [k, [x, y, bw, bh]] of Object.entries(L.btns)) {
      g.rect(x, y, bw, bh, Color.white, bh * 0.4)
      g.text(labels[k], bh * 0.36, rgb(0x3e3550), pt(x + bw / 2, y + bh / 2), 'bold')
    }
    const size = w * 0.16
    c.drawImage(sprite(this.o.appearance, this.done, size), w - size - 4, h * 0.005, size, size)
    if (this.done) g.text('Vừa khít!', w * 0.08, rgb(0x6f5ab8), pt(w / 2, h * 0.05), 'bold')
  }

  private snapTarget(piece: number, x: number, y: number): Placement | null {
    const L = this.layoutCache
    if (!L) return null
    const shape = rotate(this.b.puzzle.pieces.find(p => p.id === piece)!.cells, this.rot.get(piece) ?? 0)
    const [c0, r0] = shape[0]
    const col = Math.round((x - L.gx - L.cell / 2) / L.cell) - c0
    const row = Math.round((y - L.gy - L.cell / 2) / L.cell) - r0
    return { piece, rot: this.rot.get(piece) ?? 0, col, row }
  }

  private hitTray(x: number, y: number): number | null {
    for (const t of this.layoutCache?.tray ?? []) {
      const piece = this.b.puzzle.pieces.find(p => p.id === t.id)!
      for (const [c, r] of rotate(piece.cells, this.rot.get(t.id) ?? 0)) {
        if (x >= t.x + c * t.cs && x <= t.x + (c + 1) * t.cs && y >= t.y + r * t.cs && y <= t.y + (r + 1) * t.cs) return t.id
      }
    }
    return null
  }

  private hitBoard(x: number, y: number): number | null {
    const L = this.layoutCache
    if (!L) return null
    const col = Math.floor((x - L.gx) / L.cell), row = Math.floor((y - L.gy) / L.cell)
    const occ = this.b.occupied()
    return occ.get(col + row * this.b.puzzle.cols) ?? null
  }

  pointer(type: 'down' | 'move' | 'up', x: number, y: number) {
    const L = this.layoutCache
    if (!L || this.done) return
    if (type === 'down') {
      for (const [k, [bx, by, bw, bh]] of Object.entries(L.btns)) {
        if (x >= bx && x <= bx + bw && y >= by && y <= by + bh) {
          this.button(k)
          return
        }
      }
      const fromTray = this.hitTray(x, y)
      const fromBoard = fromTray == null ? this.hitBoard(x, y) : null
      const piece = fromTray ?? fromBoard
      if (piece != null) {
        this.drag = { piece, x, y, moved: false, fromBoard: fromBoard != null }
        this.selected = piece
        this.o.sfx('tap')
      } else if (this.selected != null) {
        // chạm vào giỏ để đặt miếng đang chọn
        const snap = this.snapTarget(this.selected, x, y)
        if (snap && this.b.place(snap)) this.o.sfx('pop')
      }
      return
    }
    if (type === 'move' && this.drag) {
      if (Math.hypot(x - this.drag.x, y - this.drag.y) > 6) this.drag.moved = true
      this.drag.x = x
      this.drag.y = y
      return
    }
    if (type === 'up' && this.drag) {
      const d = this.drag
      this.drag = null
      if (!d.moved) {
        if (d.fromBoard) {
          this.b.remove(d.piece)
          this.selected = d.piece
        }
        return
      }
      const snap = this.snapTarget(d.piece, d.x, d.y)
      if (snap && this.b.fits(snap)) {
        this.b.place(snap)
        this.selected = null
        this.o.sfx('pop')
      } else if (d.fromBoard) this.b.remove(d.piece)
    }
  }

  private button(k: string) {
    this.o.sfx('tap')
    if (k === 'rotate') {
      const id = this.selected ?? [...this.rot.keys()].find(i => !this.b.placements.has(i))
      if (id == null) return
      if (this.b.placements.has(id)) this.b.remove(id)
      this.rot.set(id, ((this.rot.get(id) ?? 0) + 1) % 4)
      this.selected = id
    } else if (k === 'hint') {
      const id = this.b.hint()
      if (id != null) this.rot.set(id, this.b.placements.get(id)!.rot)
    } else if (k === 'clear') {
      this.b.placements.clear()
    }
  }

  key(type: 'down' | 'up', key: string) {
    if (type !== 'down') return
    if (key === 'r' || key === 'R') this.button('rotate')
    if (key === 'h' || key === 'H') this.button('hint')
  }
  hud(): HudItem[] {
    return [{ label: 'Đã xếp', value: `${this.b.placements.size}/${this.b.puzzle.pieces.length}` }, { label: 'Gợi ý', value: String(this.b.hints) }]
  }
  over() {
    return this.done && this.time > 0
  }
  result(completed: boolean): RunResult {
    return { game: 'picnic', completed: completed && this.done, puzzle: 0, moves: Math.max(1, this.b.moves), hints: this.b.hints, seconds: Math.round(this.time) }
  }
  dispose() {}
}

function foodGlyph(i: number): string {
  return ['🥪', '🍰', '🍇', '🍙', '🍪', '🥕', '🍓', '🧀', '🥧'][i % PICNIC_FOODS.length]
}
