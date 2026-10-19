// Đường Về Nhà — bạn nhỏ tự chạy về nhà trên con đường 3 làn. Đổi làn, nhảy qua rào thấp, tránh xe hàng, nhặt dâu.
// Bảo đảm luôn có đường đi: mỗi hàng chướng ngại có ít nhất một làn không có vật cao; khoảng cách giữa hai hàng đủ để
// đổi hai làn (mỗi lần đổi làn 0,15 giây) hoặc nhảy (0,55 giây) ở tốc độ hiện tại.
import { Lcg } from './rng'

export type Cell = 'none' | 'fence' | 'cart' | 'berry'
export interface Row { id: number; z: number; cells: [Cell, Cell, Cell]; hit?: boolean; taken?: [boolean, boolean, boolean] }
export type RunnerEvent = 'hit' | 'berry' | 'jump' | 'lane' | 'over'

export const RUNNER = {
  lanes: 3,
  startSpeed: 7,
  maxSpeed: 13,
  /** Giây để đạt tốc độ tối đa. */
  rampSec: 120,
  laneSec: 0.15,
  jumpSec: 0.55,
  hearts: 3,
  invulnSec: 1.0,
  /** Thời gian phản ứng tối thiểu giữa hai hàng (giây). */
  minGapSec: 0.65,
  view: 42,
}

export class Runner {
  time = 0
  dist = 0
  lane = 1
  laneX = 1
  jumpT = -1
  hearts = RUNNER.hearts
  berries = 0
  over = false
  rows: Row[] = []
  private invulnUntil = -1
  private rng: Lcg
  private nextZ = 18
  private nextId = 1

  constructor(seed: number) {
    this.rng = new Lcg(seed)
    this.fill()
  }

  get speed() {
    return RUNNER.startSpeed + (RUNNER.maxSpeed - RUNNER.startSpeed) * Math.min(1, this.time / RUNNER.rampSec)
  }
  get meters() {
    return Math.floor(this.dist)
  }
  get airborne() {
    return this.jumpT >= 0 && this.jumpT < RUNNER.jumpSec
  }
  get jumpHeight() {
    if (!this.airborne) return 0
    const k = this.jumpT / RUNNER.jumpSec
    return 4 * k * (1 - k)
  }
  get invulnerable() {
    return this.time < this.invulnUntil
  }

  move(dir: -1 | 1): boolean {
    if (this.over) return false
    const next = Math.max(0, Math.min(RUNNER.lanes - 1, this.lane + dir))
    if (next === this.lane) return false
    this.lane = next
    return true
  }

  jump(): boolean {
    if (this.over || this.airborne) return false
    this.jumpT = 0
    return true
  }

  step(dt: number): RunnerEvent[] {
    if (this.over) return []
    const ev: RunnerEvent[] = []
    let left = Math.min(dt, 0.1)
    while (left > 1e-9 && !this.over) {
      const s = Math.min(1 / 120, left)
      left -= s
      this.time += s
      const prev = this.dist
      this.dist += this.speed * s
      const laneSpeed = 1 / RUNNER.laneSec
      if (this.laneX < this.lane) this.laneX = Math.min(this.lane, this.laneX + laneSpeed * s)
      else if (this.laneX > this.lane) this.laneX = Math.max(this.lane, this.laneX - laneSpeed * s)
      if (this.jumpT >= 0) {
        this.jumpT += s
        if (this.jumpT >= RUNNER.jumpSec) this.jumpT = -1
      }
      const at = Math.round(this.laneX)
      for (const r of this.rows) {
        if (r.z <= prev || r.z > this.dist) continue
        const c = r.cells[at]
        if (c === 'berry' && !r.taken?.[at]) {
          r.taken = r.taken ?? [false, false, false]
          r.taken[at] = true
          this.berries += 1
          ev.push('berry')
        } else if ((c === 'cart' || (c === 'fence' && this.jumpHeight < 0.9)) && !this.invulnerable) {
          r.hit = true
          this.hearts -= 1
          this.invulnUntil = this.time + RUNNER.invulnSec
          ev.push('hit')
          if (this.hearts <= 0) {
            this.over = true
            ev.push('over')
          }
        }
      }
    }
    this.rows = this.rows.filter(r => r.z > this.dist - 4)
    this.fill()
    return ev
  }

  private fill() {
    while (this.nextZ < this.dist + RUNNER.view + 20) {
      const v = RUNNER.startSpeed + (RUNNER.maxSpeed - RUNNER.startSpeed) * Math.min(1, (this.nextZ / RUNNER.startSpeed) / RUNNER.rampSec)
      this.rows.push(this.makeRow(this.nextZ))
      const minGap = Math.max(v * RUNNER.minGapSec, 6)
      this.nextZ += minGap + this.rng.int(0, Math.round(v * 6)) / 10
    }
  }

  private makeRow(z: number): Row {
    const r = this.rng
    const difficulty = Math.min(1, z / 900)
    const cells: [Cell, Cell, Cell] = ['none', 'none', 'none']
    const kind = r.int(0, 99)
    if (kind < 22) {
      // hàng dâu
      const lane = r.int(0, 2)
      cells[lane] = 'berry'
    } else {
      const blocked = r.int(0, 99) < 35 + difficulty * 35 ? 2 : 1
      const free = r.int(0, 2)
      const lanes = [0, 1, 2].filter(l => l !== free)
      for (let i = 0; i < blocked; i++) {
        const l = lanes.splice(r.int(0, lanes.length - 1), 1)[0]
        cells[l] = r.int(0, 99) < 45 ? 'fence' : 'cart'
      }
      if (r.int(0, 99) < 35) cells[free] = 'berry'
    }
    return { id: this.nextId++, z, cells }
  }
}

/** Kiểm tra (cho test): mỗi hàng có ít nhất một làn không có xe hàng. */
export function rowPassable(row: Row): boolean {
  return row.cells.some(c => c !== 'cart')
}
