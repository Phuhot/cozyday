// Kiểm tra các minigame: luôn có đường đi / lời giải, mỗi món chỉ tính một lần, chạy lại cho cùng kết quả.
import { describe, expect, it } from 'vitest'
import { Runner, RUNNER, rowPassable } from '../src/games/runner'
import { generatePuzzle, solvable, PicnicBoard } from '../src/games/picnic'
import { GiftBasket, BASKET } from '../src/games/basket'
import { MemoryBoard, MEMORY_LEVELS } from '../src/games/memory'
import { CloudJump, CJ, replayCloudJump, validInputs, reach } from '../src/games/cloudJump'
import { Rhythm, SONGS, JUDGE } from '../src/games/rhythm'
import { TUTORIAL, currentStep } from '../src/core/tutorial'
import { playCloudJump } from './bots'
import { onboarded } from './helpers'

describe('Đường Về Nhà', () => {
  it('mọi hàng đều chừa ít nhất một làn trống, khoảng cách đủ để đổi hai làn', () => {
    for (let seed = 1; seed <= 40; seed++) {
      const r = new Runner(seed)
      let last = -Infinity
      for (let t = 0; t < 180 * 60; t++) {
        r.step(1 / 60)
        for (const row of r.rows) {
          expect(rowPassable(row)).toBe(true)
          expect(row.cells.some(c => c === 'none' || c === 'berry')).toBe(true)
          if (row.z > last) {
            if (last > -Infinity) expect(row.z - last).toBeGreaterThanOrEqual(Math.min(6, RUNNER.startSpeed * RUNNER.minGapSec) - 1e-9)
            last = row.z
          }
        }
        if (r.over) break
      }
    }
  })

  it('người chơi phản xạ đúng luôn chạy được 3 phút không mất tim (không có thế thua bắt buộc)', () => {
    for (let seed = 1; seed <= 25; seed++) {
      const r = new Runner(seed)
      for (let t = 0; t < 180 * 120; t++) {
        const next = r.rows.filter(x => x.z > r.dist).sort((a, b) => a.z - b.z)[0]
        if (next) {
          const safe = [0, 1, 2].filter(l => next.cells[l] === 'none' || next.cells[l] === 'berry')
          const target = safe.sort((a, b) => Math.abs(a - r.lane) - Math.abs(b - r.lane))[0]
          if (target !== r.lane) r.move(target > r.lane ? 1 : -1)
        }
        r.step(1 / 120)
      }
      expect(r.hearts, `seed ${seed}`).toBe(RUNNER.hearts)
      expect(r.over).toBe(false)
    }
  })

  it('bước thời gian lớn (tab bị treo) bị giới hạn, không nhảy cóc qua chướng ngại', () => {
    const r = new Runner(7)
    r.step(30)
    expect(r.time).toBeLessThanOrEqual(0.1 + 1e-9)
  })
})

describe('Xếp Giỏ Picnic', () => {
  it('đề sinh ra luôn giải được, ở mọi độ khó', () => {
    for (const difficulty of [0, 1, 2]) {
      for (let seed = 1; seed <= 60; seed++) {
        const p = generatePuzzle(seed * 7919 + difficulty, difficulty)
        expect(solvable(p), `seed ${seed} difficulty ${difficulty}`).toBe(true)
        const cells = p.mask.filter(Boolean).length
        expect(p.pieces.reduce((n, x) => n + x.cells.length, 0)).toBe(cells)
        // lời giải lưu kèm phủ kín giỏ, không chồng nhau, mỗi miếng 2–5 ô
        const cover = new Set<number>()
        for (const piece of p.pieces) {
          const sol = p.solution[piece.id]
          expect(sol.length).toBe(piece.cells.length)
          expect(piece.cells.length).toBeGreaterThanOrEqual(2)
          for (const [c, r] of sol) {
            expect(p.mask[c + r * p.cols]).toBe(true)
            expect(cover.has(c + r * p.cols)).toBe(false)
            cover.add(c + r * p.cols)
          }
        }
        expect(cover.size).toBe(cells)
      }
    }
  })

  it('đặt theo gợi ý đến hết thì xong; miếng không vừa bị từ chối', () => {
    const p = generatePuzzle(12345, 1)
    const b = new PicnicBoard(p)
    expect(b.place({ piece: p.pieces[0].id, rot: 0, col: -1, row: 0 })).toBe(false)
    let guard = 0
    while (!b.solved && guard++ < 50) expect(b.hint()).not.toBeNull()
    expect(b.solved).toBe(true)
    expect(b.hints).toBeGreaterThan(0)
  })
})

describe('Giỏ Quà', () => {
  it('mỗi món chỉ được xử lý một lần, điểm không âm, đúng 60 giây', () => {
    for (let seed = 1; seed <= 20; seed++) {
      const g = new GiftBasket(seed)
      const seen = new Set<number>()
      let events = 0
      let t = 0
      while (!g.over) {
        g.setTarget(((Math.sin(t * 0.7 + seed) + 1) / 2))
        const before = new Set(g.items.map(i => i.id))
        const ev = g.step(1 / 60)
        events += ev.filter(e => e.type === 'caught' || e.type === 'bad').length
        for (const id of before) if (!g.items.some(i => i.id === id)) {
          expect(seen.has(id)).toBe(false)
          seen.add(id)
        }
        expect(g.score).toBeGreaterThanOrEqual(0)
        t += 1 / 60
      }
      expect(events).toBe(g.caught + g.bad)
      expect(g.time).toBeCloseTo(BASKET.duration, 6)
      expect(g.step(1)).toEqual([])
    }
  })
})

describe('Lật Thẻ', () => {
  it('khi đang chờ úp lại thì không lật thêm; mã cũ không úp nhầm lượt mới', () => {
    const b = new MemoryBoard('easy', 99)
    const faceOf = (i: number) => b.cards[i].face
    const a = 0
    const other = b.cards.findIndex((c, i) => i !== a && c.face !== faceOf(a))
    b.flip(a)
    const r = b.flip(other)
    expect(r.type).toBe('mismatch')
    const third = b.cards.findIndex((c, i) => i !== a && i !== other && c.state === 'down')
    expect(b.flip(third).type).toBe('ignored')
    expect(b.resolveMismatch(999)).toBe(false)
    expect(b.resolveMismatch((r as { token: number }).token)).toBe(true)
    expect(b.resolveMismatch((r as { token: number }).token)).toBe(false)
  })

  it('nhớ hoàn hảo thì số lượt bằng số cặp, lật lại thẻ đã ghép bị bỏ qua', () => {
    for (const level of ['easy', 'medium'] as const) {
      const b = new MemoryBoard(level, 5)
      const byFace = new Map<number, number[]>()
      b.cards.forEach(c => byFace.set(c.face, [...(byFace.get(c.face) ?? []), c.id]))
      for (const [x, y] of byFace.values()) {
        b.flip(x)
        b.flip(y)
        expect(b.flip(x).type).toBe('ignored')
      }
      expect(b.complete).toBe(true)
      expect(b.moves).toBe(MEMORY_LEVELS[level].pairs)
    }
  })
})

describe('Nhảy Mây', () => {
  it('khoảng cách giữa các tầng mây phía trên luôn nhỏ hơn độ cao nhảy tối đa', () => {
    const maxJump = Math.floor((CJ.JUMP * CJ.JUMP) / (2 * CJ.G))
    expect(CJ.MAX_GAP).toBeLessThan(maxJump)
    expect(reach(CJ.MAX_GAP)).toBeGreaterThan(0)
    for (let seed = 1; seed <= 12; seed++) {
      const e = new CloudJump(seed * 31)
      for (let t = 0; t < 60 * 60 && !e.over; t++) {
        if (t % 30 === 0) {
          const ys = [...new Set(e.platforms.filter(p => p.y >= e.petY).map(p => p.y))].sort((a, b) => a - b)
          for (let i = 1; i < ys.length; i++) expect(ys[i] - ys[i - 1]).toBeLessThanOrEqual(CJ.MAX_GAP)
        }
        // lái theo tầng mây cao hơn gần nhất
        const above = e.platforms.filter(p => p.y > e.petY).sort((a, b) => a.y - b.y)[0]
        if (above) e.setTarget(above.x / CJ.W)
        e.tick()
      }
    }
  })

  it('người chơi giỏi (bot) leo được trên mọi seed thử; chạy lại nhật ký cho đúng kết quả', () => {
    for (let seed = 1; seed <= 20; seed++) {
      const e = playCloudJump(seed * 104729, 60 * 60)
      expect(e.over).toBe(true)
      expect(e.meters, `seed ${seed}`).toBeGreaterThan(80)
      expect(validInputs(e.inputs)).toBe(true)
      const r = replayCloudJump(seed * 104729, e.inputs)
      expect(r).toMatchObject({ meters: e.meters, stars: e.stars, over: true })
    }
  })

  it('nhật ký sai định dạng bị loại', () => {
    expect(validInputs([10, 500, 5, 600])).toBe(false)
    expect(validInputs([10, -1])).toBe(false)
    expect(validInputs([1.5, 100])).toBe(false)
    expect(validInputs('x')).toBe(false)
  })
})

describe('Vườn Nốt Nhạc', () => {
  it('chạm đúng nhịp (kể cả khi có độ trễ đã hiệu chỉnh) đạt 100%', () => {
    for (const offsetMs of [0, 120]) {
      const g = new Rhythm(SONGS[0], offsetMs)
      const dt = 1 / 240
      const pending = [...g.notes]
      while (!g.over) {
        g.step(dt)
        for (const n of pending.filter(n => !n.judged && g.time - offsetMs / 1000 >= n.t)) g.tap(n.lane)
      }
      expect(g.miss).toBe(0)
      expect(g.accuracy).toBeGreaterThanOrEqual(99)
    }
  })

  it('chạm lung tung không ghi điểm, không chấm một nốt hai lần', () => {
    const g = new Rhythm(SONGS[0])
    let hits = 0
    while (!g.over) {
      g.step(1 / 30)
      for (const lane of [0, 1, 2]) if (g.tap(lane)) hits += 1
    }
    expect(g.perfect + g.good).toBe(hits)
    expect(g.perfect + g.good + g.miss).toBe(g.total)
    expect(JUDGE.good).toBeGreaterThan(JUDGE.perfect)
  })
})

describe('Hướng dẫn', () => {
  it('bỏ qua / để sau / làm lại được lưu, và tiếp tục đúng bước sau khi tải lại', async () => {
    const h = await onboarded()
    let s = await h.be.load()
    expect(currentStep(s)?.id).toBe('place')
    s = (await h.act({ type: 'tutorial', step: 'place', status: 'skipped' })).state
    expect(currentStep(s)?.id).toBe('feed')
    // tải lại (backend mới trên cùng bộ nhớ)
    const { LocalBackend } = await import('../src/backend/local')
    const again = await new LocalBackend(h.storage, () => h.clock.t).load()
    expect(currentStep(again)?.id).toBe('feed')
    s = (await h.act({ type: 'tutorial', step: 'place', status: 'reset' })).state
    expect(currentStep(s)?.id).toBe('place')
    for (const step of TUTORIAL) s = (await h.act({ type: 'tutorial', step: step.id, status: 'skipped' })).state
    expect(currentStep(s)).toBeNull()
  })
})
