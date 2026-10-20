// Giỏ Quà — chuyển từ GiftBasketEngine (Swift). Rộng 100, y hướng lên, giỏ ở đáy, lượt dài đúng 60 giây chạy.
// Mỗi món chỉ được xử lý một lần (cờ `resolved`).
import { Lcg } from './rng'

export type DropKind = 'apple' | 'cherry' | 'star' | 'gift' | 'mud' | 'rain'
export const isGood = (k: DropKind) => k !== 'mud' && k !== 'rain'
export const dropPoints = (k: DropKind) => (k === 'gift' ? 5 : k === 'star' ? 2 : isGood(k) ? 1 : 0)
export const dropRadius = (k: DropKind) => (k === 'gift' ? 5.5 : 4.5)

export interface Drop { id: number; kind: DropKind; x: number; y: number; speed: number; resolved: boolean }

export type BasketEvent =
  | { type: 'caught'; kind: DropKind; points: number; combo: number }
  | { type: 'bad'; kind: DropKind; lost: number }
  | { type: 'missed'; kind: DropKind }
  | { type: 'finished' }

export const BASKET = { duration: 60, width: 100, basketY: 15, half: 11, maxSpeed: 220, maxItems: 16, badPenalty: 3, step: 1 / 120 }

export function multiplier(combo: number) {
  return 1 + Math.min(2, Math.floor(Math.max(0, combo - 1) / 8))
}

export class GiftBasket {
  time = 0
  score = 0
  combo = 0
  bestCombo = 0
  caught = 0
  bad = 0
  missedGood = 0
  basketX = 50
  targetX = 50
  items: Drop[] = []
  over = false
  private rng: Lcg
  private nextSpawn = 0.6
  private nextId = 1
  readonly viewHeight: number

  constructor(seed: number, viewHeight = 170) {
    this.rng = new Lcg(seed)
    this.viewHeight = viewHeight
  }

  get remaining() {
    return Math.max(0, BASKET.duration - this.time)
  }

  setTarget(frac: number) {
    this.targetX = Math.min(Math.max(frac * 100, BASKET.half), 100 - BASKET.half)
  }

  step(dt: number): BasketEvent[] {
    if (this.over) return []
    const ev: BasketEvent[] = []
    let left = Math.min(dt, 0.1)
    while (left > 1e-9 && !this.over) {
      const s = Math.min(BASKET.step, left, BASKET.duration - this.time)
      left -= BASKET.step
      if (s > 0) {
        this.time += s
        const dx = this.targetX - this.basketX
        this.basketX += Math.max(-BASKET.maxSpeed * s, Math.min(BASKET.maxSpeed * s, dx))
        while (this.time >= this.nextSpawn) {
          if (this.items.length < BASKET.maxItems) this.spawn()
          this.nextSpawn += this.interval(this.nextSpawn)
        }
        for (const it of this.items) {
          if (it.resolved) continue
          const prev = it.y
          it.y -= it.speed * s
          if (prev > BASKET.basketY && it.y <= BASKET.basketY && Math.abs(it.x - this.basketX) <= BASKET.half + dropRadius(it.kind) * 0.6) {
            it.resolved = true
            ev.push(this.apply(it.kind))
          } else if (it.y < -8) {
            it.resolved = true
            if (isGood(it.kind)) {
              this.missedGood += 1
              ev.push({ type: 'missed', kind: it.kind })
            }
          }
        }
        this.items = this.items.filter(i => !i.resolved)
      }
      if (this.time >= BASKET.duration - 1e-9) {
        this.over = true
        ev.push({ type: 'finished' })
      }
    }
    return ev
  }

  private apply(kind: DropKind): BasketEvent {
    if (isGood(kind)) {
      this.combo += 1
      this.bestCombo = Math.max(this.bestCombo, this.combo)
      this.caught += 1
      const points = dropPoints(kind) * multiplier(this.combo)
      this.score += points
      return { type: 'caught', kind, points, combo: this.combo }
    }
    this.bad += 1
    this.combo = 0
    const lost = Math.min(this.score, BASKET.badPenalty)
    this.score -= lost
    return { type: 'bad', kind, lost }
  }

  private interval(t: number) {
    const k = Math.min(1, t / BASKET.duration)
    return 0.85 + (0.42 - 0.85) * k
  }

  private spawn() {
    const r = this.rng
    const k = Math.min(1, this.time / BASKET.duration)
    const roll = r.float()
    const bad = 0.12 + (0.26 - 0.12) * k
    let kind: DropKind
    if (roll < bad) kind = r.float() < 0.5 ? 'mud' : 'rain'
    else if (roll < bad + 0.06) kind = 'gift'
    else if (roll < bad + 0.2) kind = 'star'
    else kind = r.float() < 0.5 ? 'apple' : 'cherry'
    const speed = (42 + (85 - 42) * k) * (0.9 + r.float() * 0.25)
    const x = 8 + r.float() * 84
    this.items.push({ id: this.nextId++, kind, x, y: this.viewHeight + 8, speed, resolved: false })
  }
}
