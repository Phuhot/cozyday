// Phần vẽ & điều khiển của Nhảy Mây, Giỏ Quà, Lật Thẻ.
import { CloudJump, CJ, platformX, hazardX } from '../../games/cloudJump'
import { GiftBasket, BASKET } from '../../games/basket'
import { MemoryBoard, MEMORY_LEVELS, type MemoryLevel } from '../../games/memory'
import * as A from '../../art/gameArt'
import { GC, rgb, Color, pt, R } from '../../art/gc'
import { paintPet, petSprite } from '../../art'
import { drawPet } from '../../art/ported/PetPainter'
import { restPose, SPECIES, NATURAL_FUR, type PetAppearance, type PetPose } from '../../content/pet'
import { CROPS } from '../../content/farm'
import { drawProduce } from '../kit'
import type { RunResult } from '../../core/games'
import type { GameOpts, GameView, HudItem } from './types'

function spriteFor(a: PetAppearance, kind: 'idle' | 'happy' | 'surprised' | 'cheer', px: number) {
  const pose: PetPose = restPose()
  if (kind === 'happy') pose.petted = 1
  if (kind === 'surprised') pose.lifted = true
  if (kind === 'cheer') {
    pose.petted = 1
    pose.hearts = 0.35
  }
  return petSprite(a, kind === 'happy' || kind === 'cheer' ? 'happy' : 'idle', pose, px, kind)
}

// ---------------- Nhảy Mây ----------------

export class CloudJumpView implements GameView {
  readonly aspect = 0.62
  private e: CloudJump
  private acc = 0
  private o: GameOpts
  private keys = { left: false, right: false }
  private flash = 0
  private sparkles: { x: number; y: number; t: number }[] = []

  constructor(o: GameOpts) {
    this.o = o
    this.e = new CloudJump(o.seed)
  }

  step(dt: number) {
    this.acc += Math.min(dt, 0.25)
    while (this.acc >= 1 / 60 && !this.e.over) {
      this.acc -= 1 / 60
      if (this.keys.left || this.keys.right) {
        const dir = this.keys.left ? -1 : 1
        this.e.setTarget((this.e.petX + dir * 20_000) / CJ.W)
      }
      for (const ev of this.e.tick()) {
        if (ev === 'bounce') this.o.sfx('jump')
        if (ev === 'star') {
          this.o.sfx('star')
          this.sparkles.push({ x: this.e.petX, y: this.e.petY + 8000, t: 0 })
        }
        if (ev === 'hit') {
          this.o.sfx('hit')
          this.flash = 0.4
        }
      }
    }
    this.flash = Math.max(0, this.flash - dt)
    for (const s of this.sparkles) s.t += dt * 2
    this.sparkles = this.sparkles.filter(s => s.t < 1)
  }

  render(c: CanvasRenderingContext2D, w: number, h: number, t: number) {
    const e = this.e
    const k = w / 100
    const g = new GC(c)
    const alt = e.cameraY / 1000
    A.sky(g, { width: w, height: h }, alt, this.o.reduceMotion)
    const sy = (yMu: number) => h - 26 * k - ((yMu - e.cameraY) / 1000) * k
    if (e.cameraY < 60_000) A.hills(g, w, sy(0))
    for (const p of e.platforms) {
      if (p.id === 0) continue
      const x = platformX(p, e.time) / 1000
      const rect = R((x - p.w / 2000) * k, sy(p.y) - 1.2 * k, (p.w / 1000) * k, 7 * k)
      if (p.fragile) A.thinCloud(g, rect)
      else A.cloud(g, rect, p.amp > 0)
    }
    for (const s of e.starList) A.star(g, pt((s.x / 1000) * k, sy(s.y)), 3.4 * k)
    for (const hz of e.hazards) {
      const c0 = pt((hazardX(hz, e.time) / 1000) * k, sy(hz.y))
      if (hz.bird) {
        const q = Math.floor((((hz.phase + e.time) % hz.period) * 4) / hz.period)
        A.bird(g, c0, (CJ.BIRD_R / 1000) * k, this.o.reduceMotion ? 0 : t, q === 1 || q === 2)
      }
      else A.stormCloud(g, c0, (CJ.STORM_R / 1000) * k, this.o.reduceMotion ? 0 : t)
    }
    for (const s of this.sparkles) A.sparkle(g, pt((s.x / 1000) * k, sy(s.y)), s.t, rgb(0xf6c445))
    // Bạn nhỏ: ảnh dựng sẵn, hitbox cố định (không phụ thuộc loài/trang phục).
    const size = 24 * k
    const kind = this.flash > 0 ? 'surprised' : e.velY > 0 ? 'happy' : 'idle'
    const spr = spriteFor(this.o.appearance, kind, size)
    const px = (e.petX / 1000) * k, py = sy(e.petY)
    c.save()
    if (e.facingLeft) {
      c.translate(px, 0)
      c.scale(-1, 1)
      c.translate(-px, 0)
    }
    c.drawImage(spr, px - size / 2, py - size * 0.88, size, size)
    c.restore()
    if (this.flash > 0) g.rect(0, 0, w, h, Color.white.opacity(this.flash * 0.5))
  }

  pointer(type: 'down' | 'move' | 'up', x: number, _y: number, w: number) {
    if (type === 'up') return
    this.e.setTarget(x / w)
  }
  key(type: 'down' | 'up', key: string) {
    const on = type === 'down'
    if (key === 'ArrowLeft' || key === 'a') this.keys.left = on
    if (key === 'ArrowRight' || key === 'd') this.keys.right = on
    if (!on && !this.keys.left && !this.keys.right) this.e.setTarget(this.e.petX / CJ.W)
  }
  hud(): HudItem[] {
    return [{ label: 'Độ cao', value: `${this.e.meters} m` }, { label: 'Sao', value: String(this.e.stars) }]
  }
  over() {
    return this.e.over
  }
  result(completed: boolean): RunResult {
    return { game: 'cloudJump', completed: completed && this.e.over, meters: this.e.meters, stars: this.e.stars, inputs: this.e.inputs }
  }
  dispose() {}
}

// ---------------- Giỏ Quà ----------------

export class BasketView implements GameView {
  readonly aspect = 0.62
  private e: GiftBasket
  private o: GameOpts
  private keys = { left: false, right: false }
  private pops: { x: number; t: number; good: boolean; text: string }[] = []

  constructor(o: GameOpts) {
    this.o = o
    this.e = new GiftBasket(o.seed, 170)
  }
  step(dt: number) {
    if (this.keys.left || this.keys.right) this.e.setTarget((this.e.basketX + (this.keys.left ? -30 : 30)) / 100)
    for (const ev of this.e.step(dt)) {
      if (ev.type === 'caught') {
        this.o.sfx(ev.kind === 'gift' ? 'coin' : 'pop')
        this.pops.push({ x: this.e.basketX, t: 0, good: true, text: `+${ev.points}` })
      } else if (ev.type === 'bad') {
        this.o.sfx('hit')
        this.pops.push({ x: this.e.basketX, t: 0, good: false, text: ev.lost ? `−${ev.lost}` : 'Ối' })
      }
    }
    for (const p of this.pops) p.t += dt * 1.6
    this.pops = this.pops.filter(p => p.t < 1)
  }
  render(c: CanvasRenderingContext2D, w: number, h: number) {
    const e = this.e
    const k = w / 100
    const g = new GC(c)
    const ground = h - 12 * k
    A.garden(g, { width: w, height: h }, ground)
    const sy = (y: number) => ground - (y - BASKET.basketY) * k - 8 * k
    for (const it of e.items) A.drop(g, it.kind, pt(it.x * k, sy(it.y)), (it.kind === 'gift' ? 5.5 : 4.5) * k)
    const size = 26 * k
    const bx = e.basketX * k
    const spr = spriteFor(this.o.appearance, e.combo >= 8 ? 'cheer' : 'idle', size)
    const brect = R(bx - BASKET.half * k, sy(BASKET.basketY), BASKET.half * 2 * k, 9 * k)
    A.basketHandle(g, brect)
    c.drawImage(spr, bx - size / 2, ground - size * 0.95, size, size)
    A.basket(g, brect, false)
    for (const p of this.pops) g.text(p.text, 5 * k, (p.good ? rgb(0x4e7a52) : rgb(0xc2565a)).opacity(1 - p.t), pt(p.x * k, sy(BASKET.basketY) - 6 * k - p.t * 10 * k), 'bold')
    if (e.combo >= 3) g.text(`Combo ×${e.combo}`, 4.6 * k, rgb(0x8d78cf), pt(w / 2, 22 * k), 'bold')
  }
  pointer(type: 'down' | 'move' | 'up', x: number, _y: number, w: number) {
    if (type !== 'up') this.e.setTarget(x / w)
  }
  key(type: 'down' | 'up', key: string) {
    const on = type === 'down'
    if (key === 'ArrowLeft' || key === 'a') this.keys.left = on
    if (key === 'ArrowRight' || key === 'd') this.keys.right = on
  }
  hud(): HudItem[] {
    return [{ label: 'Điểm', value: String(this.e.score) }, { label: 'Còn', value: `${Math.ceil(this.e.remaining)} giây` }]
  }
  over() {
    return this.e.over
  }
  result(completed: boolean): RunResult {
    return { game: 'giftBasket', completed: completed && this.e.over, score: this.e.score, caught: this.e.caught, bestCombo: this.e.bestCombo }
  }
  dispose() {}
}

// ---------------- Lật Thẻ ----------------

export class MemoryView implements GameView {
  readonly aspect: number
  private b: MemoryBoard
  private o: GameOpts
  private time = 0
  private resolveAt: { token: number; at: number } | null = null
  private flipAnim = new Map<number, number>()
  private focus = 0
  private cheer = -10
  readonly level: MemoryLevel

  constructor(o: GameOpts) {
    this.o = o
    this.level = (o.variant === 'medium' ? 'medium' : 'easy') as MemoryLevel
    this.b = new MemoryBoard(this.level, o.seed)
    this.aspect = this.level === 'easy' ? 0.66 : 0.72
  }
  private get cols() {
    return MEMORY_LEVELS[this.level].cols
  }
  step(dt: number) {
    this.time += dt
    if (this.resolveAt && this.time >= this.resolveAt.at) {
      this.b.resolveMismatch(this.resolveAt.token)
      this.resolveAt = null
    }
    for (const [id, v] of this.flipAnim) this.flipAnim.set(id, Math.min(1, v + dt * 6))
  }
  private layout(w: number, h: number) {
    const cols = this.cols, rows = 4
    const top = h * 0.2
    const gap = w * 0.03
    const cw = (w - gap * (cols + 1)) / cols
    const ch = Math.min(cw * 1.2, (h - top - gap * (rows + 1)) / rows)
    return { cols, rows, top, gap, cw, ch }
  }
  render(c: CanvasRenderingContext2D, w: number, h: number) {
    const g = new GC(c)
    g.rect(0, 0, w, h, rgb(0xfdf3e7))
    const L = this.layout(w, h)
    const size = h * 0.17
    const spr = spriteFor(this.o.appearance, this.time - this.cheer < 1.2 ? 'cheer' : 'idle', size)
    c.drawImage(spr, w / 2 - size / 2, 2, size, size)
    this.b.cards.forEach((card, i) => {
      const col = i % L.cols, row = Math.floor(i / L.cols)
      const x = L.gap + col * (L.cw + L.gap), y = L.top + L.gap + row * (L.ch + L.gap)
      const anim = this.flipAnim.get(card.id) ?? 1
      const showFace = card.state !== 'down'
      const sx = Math.abs(Math.cos(Math.PI * (1 - anim) / 2))
      const cg = g.copy()
      cg.translateBy(x + L.cw / 2, y)
      cg.scaleBy(this.o.reduceMotion ? 1 : Math.max(0.05, sx), 1)
      cg.translateBy(-L.cw / 2, 0)
      if (showFace) {
        cg.rect(0, 0, L.cw, L.ch, card.state === 'matched' ? rgb(0xe4efe2) : Color.white, L.cw * 0.14)
        this.drawFace(c, cg, card.face, L.cw, L.ch)
      } else {
        A.cardBack(cg, { width: L.cw, height: L.ch })
      }
      if (this.focus === i) {
        cg.strokePath(rgb(0x8d78cf), 3, q => q.addRoundedRect(R(-2, -2, L.cw + 4, L.ch + 4), L.cw * 0.16))
      }
    })
  }
  private drawFace(c: CanvasRenderingContext2D, cg: GC, face: number, cw: number, ch: number) {
    const s = Math.min(cw, ch) * 0.86
    if (face < 8) {
      const species = (['cat', 'bunny', 'duck', 'frog', 'panda', 'penguin', 'fox', 'capybara'] as const)[face]
      const gg = cg.copy()
      gg.translateBy((cw - s) / 2, (ch - s) / 2)
      gg.scaleBy(s / 100, s / 100)
      void c
      paintPetGC(gg, { species, fur: NATURAL_FUR[species], stage: 'grown' })
    } else {
      const crop = CROPS[(face - 8) % CROPS.length]
      const gg = cg.copy()
      gg.translateBy(cw / 2, ch / 2)
      gg.scaleBy(s / 70, s / 70)
      drawProduce(gg, crop.id, 0, 8, 1)
    }
  }
  pointer(type: 'down' | 'move' | 'up', x: number, y: number, w: number, h: number) {
    if (type !== 'down') return
    const L = this.layout(w, h)
    const col = Math.floor((x - L.gap / 2) / (L.cw + L.gap))
    const row = Math.floor((y - L.top - L.gap / 2) / (L.ch + L.gap))
    if (col < 0 || col >= L.cols || row < 0 || row >= L.rows) return
    this.flipCard(row * L.cols + col)
  }
  private flipCard(i: number) {
    this.focus = i
    const r = this.b.flip(i)
    if (r.type === 'ignored') return
    this.flipAnim.set(i, this.o.reduceMotion ? 1 : 0)
    this.o.sfx('tap')
    if (r.type === 'mismatch') this.resolveAt = { token: r.token, at: this.time + 0.85 }
    if (r.type === 'matched' || r.type === 'completed') {
      this.o.sfx('good')
      this.cheer = this.time
    }
  }
  key(type: 'down' | 'up', key: string) {
    if (type !== 'down') return
    const n = this.b.cards.length
    if (key === 'ArrowRight') this.focus = (this.focus + 1) % n
    else if (key === 'ArrowLeft') this.focus = (this.focus - 1 + n) % n
    else if (key === 'ArrowDown') this.focus = (this.focus + this.cols) % n
    else if (key === 'ArrowUp') this.focus = (this.focus - this.cols + n) % n
    else if (key === 'Enter' || key === ' ') this.flipCard(this.focus)
  }
  hud(): HudItem[] {
    return [{ label: 'Cặp', value: `${this.b.pairs}/${MEMORY_LEVELS[this.level].pairs}` }, { label: 'Lượt', value: String(this.b.moves) }]
  }
  over() {
    return this.b.complete && !this.resolveAt
  }
  result(completed: boolean): RunResult {
    return { game: 'memory', completed: completed && this.b.complete, level: this.level, moves: this.b.moves, pairs: this.b.pairs, seconds: Math.round(this.time) }
  }
  dispose() {}
}

/** Vẽ pet vào một GC đã biến đổi (dùng hệ 100×100). */
function paintPetGC(g: GC, a: PetAppearance) {
  drawPet(g, 'idle', a, restPose())
}

export const _keep = { paintPet, SPECIES }
