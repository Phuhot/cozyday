// Nhảy Mây — lõi luật chơi bằng số nguyên, bước cố định 1/60 giây.
// Chuyển từ CloudJumpEngine (Swift) sang số nguyên để máy chủ chạy lại đúng từng lượt (supabase/migrations/*cloud_jump*.sql).
// Mọi phép tính: cộng, trừ, nhân, chia lấy phần nguyên (idiv) và isqrt — không dùng sin/cos để kết quả giống hệt nhau
// trên Safari, Chrome và Postgres.
//
// Đơn vị: 1 đơn vị thế giới = 1000 (mu). Bề ngang 100 đơn vị = 100 000 mu. Trục y hướng lên, mặt đất y = 0.
// Bảo đảm chơi được: khoảng cách giữa hai bệ liền nhau nằm trong tầm nhảy (đã trừ thời gian phản xạ và biên an toàn),
// chướng ngại không chắn hành lang giữa hai bệ liền nhau (mây giông) và chim chỉ bay qua khi bệ dưới là mây chắc.
import { Lcg, idiv, isqrt, tri } from './rng'

export const CJ = {
  W: 100_000,
  G: 64,
  JUMP: 2500,
  MAXX: 1500,
  FOOT: 4000,
  BODY: 12_000,
  PER_METER: 10_000,
  VIEW: 170_000,
  MAX_PLATFORMS: 40,
  MAX_STARS: 10,
  MAX_HAZARDS: 8,
  MAX_GAP: 38_000,
  REACTION: 12,
  REACH_SAFETY: 600,
  KNOCK: -333,
  WARMUP: 120_000,
  STAR_POINTS: 3,
  /** Lượt xếp hạng dài tối đa (tick) để máy chủ chạy lại có giới hạn. */
  MAX_TICKS: 60 * 60 * 15,
  STORM_R: 7000,
  BIRD_R: 5000,
} as const

export interface Platform { id: number; x: number; y: number; w: number; amp: number; period: number; phase: number; fragile: boolean }
export interface Star { id: number; x: number; y: number }
export interface Hazard { id: number; bird: boolean; x: number; y: number; amp: number; period: number; phase: number }

export function lerp(a: number, b: number, d: number): number {
  return a + idiv((b - a) * d, 1000)
}

export function difficulty(y: number): number {
  return Math.min(1000, Math.max(0, idiv(y * 1000, 1_600_000)))
}

export function reach(dy: number): number {
  const disc = CJ.JUMP * CJ.JUMP - 2 * CJ.G * dy
  if (disc < 0) return 0
  const t = idiv(CJ.JUMP + isqrt(disc), CJ.G)
  return CJ.MAXX * Math.max(0, t - CJ.REACTION)
}

export function platformX(p: Platform, time: number): number {
  return p.amp > 0 ? p.x + idiv(p.amp * tri(p.phase + time, p.period), 1024) : p.x
}
export function hazardX(h: Hazard, time: number): number {
  return h.amp > 0 ? h.x + idiv(h.amp * tri(h.phase + time, h.period), 1024) : h.x
}

type Interval = [number, number]

export function freeIntervals(blocked: Interval[], lo: number, hi: number): Interval[] {
  const out: Interval[] = []
  let cursor = lo
  const sorted = [...blocked].sort((a, b) => a[0] - b[0] || a[1] - b[1])
  for (const b of sorted) {
    if (b[0] > cursor) out.push([cursor, Math.min(hi, b[0])])
    cursor = Math.max(cursor, b[1])
    if (cursor >= hi) break
  }
  if (cursor < hi) out.push([cursor, hi])
  return out.filter(i => i[1] > i[0])
}

export type JumpEvent = 'bounce' | 'broke' | 'star' | 'hit' | 'fell'

export class CloudJump {
  time = 0
  petX = 50_000
  petY = 0
  velY: number = CJ.JUMP
  targetX = 50_000
  facingLeft = false
  cameraY = 0
  bestY = 0
  stars = 0
  hits = 0
  landings = 0
  over = false
  platforms: Platform[] = [{ id: 0, x: 50_000, y: 0, w: 100_000, amp: 0, period: 0, phase: 0, fragile: false }]
  starList: Star[] = []
  hazards: Hazard[] = []
  /** Nhật ký điều khiển: [tick, x, tick, x, ...] — nộp lên máy chủ để chạy lại. */
  inputs: number[] = []
  private rng: Lcg
  private nextId = 1
  private topY = 0
  private lastX = 50_000
  private lastW = 100_000
  private lastAmp = 0
  private lastFragile = false
  private prevX = 50_000
  private prevHalf = 50_000

  constructor(seed: number) {
    this.rng = new Lcg(seed)
    this.generate()
  }

  get meters(): number {
    return idiv(this.bestY, CJ.PER_METER)
  }
  get score(): number {
    return this.meters + this.stars * CJ.STAR_POINTS
  }

  /** Đặt điểm đến theo phần trăm bề ngang (0…1). Ghi vào nhật ký khi đổi. */
  setTarget(frac: number) {
    const x = Math.max(CJ.FOOT, Math.min(CJ.W - CJ.FOOT, Math.round(frac * CJ.W)))
    if (x === this.targetX) return
    this.targetX = x
    const n = this.inputs.length
    if (n >= 2 && this.inputs[n - 2] === this.time) this.inputs[n - 1] = x
    else this.inputs.push(this.time, x)
  }

  /** Áp dụng điều khiển đã ghi (chạy lại). */
  applyInput(x: number) {
    this.targetX = Math.max(CJ.FOOT, Math.min(CJ.W - CJ.FOOT, x))
  }

  tick(): JumpEvent[] {
    if (this.over) return []
    const ev: JumpEvent[] = []
    this.time += 1
    const dx = this.targetX - this.petX
    const move = Math.max(-CJ.MAXX, Math.min(CJ.MAXX, dx))
    this.petX = Math.max(CJ.FOOT, Math.min(CJ.W - CJ.FOOT, this.petX + move))
    if (Math.abs(move) > 50) this.facingLeft = move < 0

    const prev = this.petY
    this.velY -= CJ.G
    this.petY += this.velY
    if (this.velY < 0) {
      for (let i = 0; i < this.platforms.length; i++) {
        const p = this.platforms[i]
        if (prev >= p.y && this.petY <= p.y && Math.abs(this.petX - platformX(p, this.time)) <= idiv(p.w, 2) + CJ.FOOT) {
          this.petY = p.y
          this.velY = CJ.JUMP
          this.landings += 1
          if (p.y > this.bestY) this.bestY = p.y
          ev.push('bounce')
          if (p.fragile) {
            this.platforms.splice(i, 1)
            ev.push('broke')
          }
          break
        }
      }
    }
    const bodyY = this.petY + idiv(CJ.BODY, 2)
    for (let i = 0; i < this.hazards.length; i++) {
      const h = this.hazards[i]
      const hx = this.petX - hazardX(h, this.time)
      const hy = bodyY - h.y
      const r = (h.bird ? CJ.BIRD_R : CJ.STORM_R) + CJ.FOOT
      if (hx * hx + hy * hy < r * r) {
        this.hazards.splice(i, 1)
        this.velY = Math.min(this.velY, CJ.KNOCK)
        this.hits += 1
        ev.push('hit')
        break
      }
    }
    for (let i = this.starList.length - 1; i >= 0; i--) {
      const s = this.starList[i]
      if (Math.abs(s.x - this.petX) <= 7000 && s.y >= this.petY - 3000 && s.y <= this.petY + CJ.BODY + 2000) {
        this.starList.splice(i, 1)
        this.stars += 1
        ev.push('star')
      }
    }
    this.cameraY = Math.max(this.cameraY, this.petY - idiv(CJ.VIEW * 4, 10))
    if (this.petY < this.cameraY - 14_000 || this.time >= CJ.MAX_TICKS) {
      this.over = true
      ev.push('fell')
      return ev
    }
    const floor = this.cameraY - 30_000
    this.platforms = this.platforms.filter(p => p.y >= floor)
    this.starList = this.starList.filter(s => s.y >= floor)
    this.hazards = this.hazards.filter(h => h.y >= floor)
    this.generate()
    return ev
  }

  private generate() {
    while (this.topY < this.cameraY + CJ.VIEW + 60_000 && this.platforms.length < CJ.MAX_PLATFORMS) this.addPlatform()
  }

  private addPlatform() {
    const r = this.rng
    const d = difficulty(this.topY)
    const early = this.topY < CJ.WARMUP
    const dy = r.int(early ? 18_000 : lerp(20_000, 28_000, d), early ? 24_000 : lerp(28_000, CJ.MAX_GAP, d))
    const w = (early ? 32_000 : lerp(26_000, 14_000, d)) + r.int(-2000, 2000)
    const moving = !early && r.chance(lerp(200, 500, d))
    const amp = moving ? lerp(8000, 18_000, d) : 0
    const period = moving ? lerp(377, 222, d) : 0
    const maxDX = Math.max(4000, idiv(reach(dy) * CJ.REACH_SAFETY, 1000) - amp)
    const edge = idiv(w, 2) + amp + 2000
    const lo = Math.max(edge, this.lastX - maxDX)
    const hi = Math.min(CJ.W - edge, this.lastX + maxDX)
    const x = lo < hi ? r.int(lo, hi) : Math.min(Math.max(this.lastX, edge), CJ.W - edge)
    const y = this.topY + dy
    const phase = moving ? r.int(0, period - 1) : 0
    const fragile = !early && !this.lastFragile && r.chance(lerp(80, 280, d))

    if (!early && this.hazards.length < CJ.MAX_HAZARDS && r.chance(lerp(180, 500, d))) {
      this.addHazard(this.prevX, this.prevHalf, this.lastX, this.topY, idiv(this.lastW, 2) + this.lastAmp, this.lastFragile, x, y, idiv(w, 2) + amp, d)
    }

    this.platforms.push({ id: this.nextId, x, y, w, amp, period, phase, fragile })
    this.nextId += 1
    this.topY = y
    this.prevX = this.lastX
    this.prevHalf = idiv(this.lastW, 2) + this.lastAmp
    this.lastX = x
    this.lastW = w
    this.lastAmp = amp
    this.lastFragile = fragile
    if (this.starList.length < CJ.MAX_STARS && r.chance(300)) {
      const sx = Math.min(Math.max(x + r.int(-10_000, 10_000), 8000), CJ.W - 8000)
      this.starList.push({ id: this.nextId, x: sx, y: y + r.int(18_000, 32_000) })
      this.nextId += 1
    }
  }

  private addHazard(zx: number, zHalf: number, ax: number, ay: number, aHalf: number, aFragile: boolean, bx: number, by: number, bHalf: number, d: number) {
    const r = this.rng
    const midY = ay + idiv((by - ay) * r.int(450, 700), 1000)
    const wantsBird = d > 150 && !aFragile && r.chance(500)
    const bm = 12_000
    const sm = 14_000
    if (wantsBird) {
      const lanes = freeIntervals([[ax - aHalf - bm, ax + aHalf + bm], [zx - zHalf - bm, zx + zHalf + bm]], 6000, CJ.W - 6000)
        .filter(l => l[1] - l[0] >= 24_000)
      if (lanes.length) {
        let best = lanes[0]
        for (const l of lanes) if (l[1] - l[0] > best[1] - best[0]) best = l
        const half = idiv(best[1] - best[0], 2)
        const v = lerp(450, 800, d)
        const period = Math.max(60, idiv(4 * half, v))
        this.hazards.push({ id: this.nextId, bird: true, x: best[0] + half, y: midY, amp: half, period, phase: r.int(0, period - 1) })
        this.nextId += 1
        return
      }
    }
    const lo = Math.min(ax - aHalf, bx - bHalf) - sm
    const hi = Math.max(ax + aHalf, bx + bHalf) + sm
    const lanes = freeIntervals([[lo, hi], [zx - zHalf - sm, zx + zHalf + sm]], 8000, CJ.W - 8000)
    if (!lanes.length) return
    const lane = lanes[r.int(0, lanes.length - 1)]
    const x = r.int(lane[0], lane[1])
    this.hazards.push({ id: this.nextId, bird: false, x, y: midY, amp: 0, period: 0, phase: 0 })
    this.nextId += 1
  }
}

/** Chạy lại một lượt từ seed + nhật ký điều khiển (giống hệt hàm SQL cozii_cj_replay). */
export function replayCloudJump(seed: number, inputs: number[], maxTicks: number = CJ.MAX_TICKS): { meters: number; stars: number; ticks: number; over: boolean } {
  const e = new CloudJump(seed)
  let i = 0
  while (!e.over && e.time < maxTicks) {
    while (i + 1 < inputs.length && inputs[i] <= e.time) {
      e.applyInput(inputs[i + 1])
      i += 2
    }
    e.tick()
  }
  return { meters: e.meters, stars: e.stars, ticks: e.time, over: e.over }
}

/** Kiểm tra nhật ký hợp lệ: số nguyên, tick tăng dần, giới hạn độ dài. */
export function validInputs(inputs: unknown): inputs is number[] {
  if (!Array.isArray(inputs) || inputs.length % 2 !== 0 || inputs.length > 40_000) return false
  let last = -1
  for (let i = 0; i < inputs.length; i += 2) {
    const t = inputs[i], x = inputs[i + 1]
    if (!Number.isInteger(t) || !Number.isInteger(x) || t <= last || t < 0 || t > CJ.MAX_TICKS || x < 0 || x > CJ.W) return false
    last = t
  }
  return true
}
