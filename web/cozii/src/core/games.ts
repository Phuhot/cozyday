// Kiểm tra kết quả một lượt minigame và tính xu (trước hạn mức ngày).
// Máy chủ dùng đúng các ngưỡng này (đã sinh sang SQL); riêng Nhảy Mây xếp hạng còn được máy chủ chạy lại toàn bộ lượt.
import type { RunTicket } from './state'

export const GAME_INFO = {
  cloudJump: { name: 'Nhảy Mây', blurb: 'Bạn nhỏ tự nảy trên mây. Kéo ngang để đáp lên đám mây kế tiếp.' },
  giftBasket: { name: 'Giỏ Quà', blurb: 'Hứng quà rơi trong 60 giây, né bùn và mây mưa.' },
  memory: { name: 'Lật Thẻ', blurb: 'Lật hai thẻ một lần, tìm cặp bạn nhỏ giống nhau.' },
  rhythm: { name: 'Vườn Nốt Nhạc', blurb: 'Chạm đúng nhịp khi nốt nhạc rơi tới bông hoa.' },
  runner: { name: 'Đường Về Nhà', blurb: 'Bạn nhỏ chạy về nhà. Đổi làn, nhảy qua rào, nhặt dâu.' },
  picnic: { name: 'Xếp Giỏ Picnic', blurb: 'Xếp các món ăn vừa khít chiếc giỏ. Không tính giờ.' },
} as const

export const GAME_RULES = {
  cloudJump: { maxMetersPerSec: 8, minMeters: 15, pointsPerCoin: 10, pointsPerStar: 3 },
  giftBasket: { duration: 60, maxPointsPerSec: 40, minScore: 20, pointsPerCoin: 15 },
  memory: { easy: { pairs: 6, base: 3, fast: 40 }, medium: { pairs: 8, base: 5, fast: 65 }, minSecPerPair: 1.2 },
  rhythm: { minAccuracy: 40, accuracyPerCoin: 10 },
  runner: { maxMetersPerSec: 14, minMeters: 50, metersPerCoin: 25 },
  picnic: { minSeconds: 8, coins: 4, noHintBonus: 2 },
} as const

export type RunResult =
  | { game: 'cloudJump'; completed: boolean; meters: number; stars: number; inputs?: number[] }
  | { game: 'giftBasket'; completed: boolean; score: number; caught: number; bestCombo: number }
  | { game: 'memory'; completed: boolean; level: 'easy' | 'medium'; moves: number; pairs: number; seconds: number }
  | { game: 'rhythm'; completed: boolean; song: string; accuracy: number; hits: number; total: number; duration: number }
  | { game: 'runner'; completed: boolean; meters: number; berries: number }
  | { game: 'picnic'; completed: boolean; puzzle: number; moves: number; hints: number; seconds: number }

export type RunNote = 'rewarded' | 'belowThreshold' | 'notCompleted' | 'implausible' | 'partialCap' | 'dailyCap' | 'practice'

export interface RunVerdict {
  finished: boolean
  valid: boolean
  score: number
  coins: number
  note: RunNote
}

export function memoryScore(level: 'easy' | 'medium', moves: number, seconds: number): number {
  const pairs = GAME_RULES.memory[level].pairs
  return Math.max(pairs * 10, pairs * 100 - Math.max(0, moves - pairs) * 15 - Math.round(seconds))
}

export function picnicScore(moves: number, hints: number, seconds: number): number {
  return Math.max(20, 300 - Math.round(seconds) - hints * 40 - Math.max(0, moves - 6) * 4)
}

export function scoreOf(r: RunResult): number {
  switch (r.game) {
    case 'cloudJump': return Math.floor(r.meters) + r.stars * GAME_RULES.cloudJump.pointsPerStar
    case 'giftBasket': return r.score
    case 'memory': return memoryScore(r.level, r.moves, r.seconds)
    case 'rhythm': return Math.round(r.accuracy * 10)
    case 'runner': return Math.floor(r.meters) + r.berries * 2
    case 'picnic': return picnicScore(r.moves, r.hints, r.seconds)
  }
}

const isInt = (v: unknown, lo: number, hi: number) => typeof v === 'number' && Number.isFinite(v) && v >= lo && v <= hi

/** `now` là đồng hồ máy chủ (hoặc máy, khi chơi trên máy). Thời gian thật của lượt = now − startedAt. */
export function checkRun(t: RunTicket, r: RunResult, now: number): RunVerdict {
  const elapsed = Math.max(0, (now - t.startedAt) / 1000)
  const no = (note: RunNote): RunVerdict => ({ finished: note !== 'implausible', valid: note !== 'implausible', score: note === 'implausible' ? 0 : safeScore(r), coins: 0, note })
  if (!r || r.game !== t.game) return { finished: false, valid: false, score: 0, coins: 0, note: 'implausible' }
  if (!r.completed) return { finished: false, valid: true, score: 0, coins: 0, note: 'notCompleted' }
  switch (r.game) {
    case 'cloudJump': {
      const g = GAME_RULES.cloudJump
      if (!isInt(r.meters, 0, 100000) || !isInt(r.stars, 0, 10000)) return no('implausible')
      if (r.meters > g.maxMetersPerSec * elapsed + 5 || r.stars > r.meters / 2 + 5) return no('implausible')
      const score = scoreOf(r)
      if (r.meters < g.minMeters) return { finished: true, valid: true, score, coins: 0, note: 'belowThreshold' }
      return { finished: true, valid: true, score, coins: Math.max(1, Math.floor(score / g.pointsPerCoin)), note: 'rewarded' }
    }
    case 'giftBasket': {
      const g = GAME_RULES.giftBasket
      if (!isInt(r.score, 0, 100000)) return no('implausible')
      if (elapsed < g.duration - 2 || r.score > g.maxPointsPerSec * Math.min(elapsed, g.duration + 1) + 5) return no('implausible')
      if (r.score < g.minScore) return { finished: true, valid: true, score: r.score, coins: 0, note: 'belowThreshold' }
      return { finished: true, valid: true, score: r.score, coins: Math.max(1, Math.floor(r.score / g.pointsPerCoin)), note: 'rewarded' }
    }
    case 'memory': {
      const g = GAME_RULES.memory
      const lv = g[r.level]
      if (!lv) return no('implausible')
      if (r.pairs !== lv.pairs || !isInt(r.moves, lv.pairs, 1000) || !isInt(r.seconds, 0, 36000)) return no('implausible')
      if (elapsed < lv.pairs * g.minSecPerPair || r.seconds > elapsed + 5) return no('implausible')
      let coins = lv.base
      if (r.moves <= lv.pairs * 2) coins += 1
      if (r.moves <= lv.pairs + 3) coins += 1
      if (r.seconds <= lv.fast) coins += 1
      return { finished: true, valid: true, score: scoreOf(r), coins, note: 'rewarded' }
    }
    case 'rhythm': {
      const g = GAME_RULES.rhythm
      if (!isInt(r.accuracy, 0, 100) || !isInt(r.hits, 0, r.total) || !isInt(r.total, 1, 2000) || !isInt(r.duration, 5, 600)) return no('implausible')
      if (elapsed < r.duration - 2) return no('implausible')
      if (r.accuracy < g.minAccuracy) return { finished: true, valid: true, score: scoreOf(r), coins: 0, note: 'belowThreshold' }
      return { finished: true, valid: true, score: scoreOf(r), coins: Math.max(1, Math.floor(r.accuracy / g.accuracyPerCoin)), note: 'rewarded' }
    }
    case 'runner': {
      const g = GAME_RULES.runner
      if (!isInt(r.meters, 0, 100000) || !isInt(r.berries, 0, 10000)) return no('implausible')
      if (r.meters > g.maxMetersPerSec * elapsed + 5 || r.berries > r.meters / 3 + 5) return no('implausible')
      const score = scoreOf(r)
      if (r.meters < g.minMeters) return { finished: true, valid: true, score, coins: 0, note: 'belowThreshold' }
      return { finished: true, valid: true, score, coins: Math.max(1, Math.floor(score / g.metersPerCoin)), note: 'rewarded' }
    }
    case 'picnic': {
      const g = GAME_RULES.picnic
      if (!isInt(r.moves, 1, 1000) || !isInt(r.hints, 0, 50) || !isInt(r.seconds, 0, 36000)) return no('implausible')
      if (elapsed < g.minSeconds || r.seconds > elapsed + 5) return no('implausible')
      return { finished: true, valid: true, score: scoreOf(r), coins: g.coins + (r.hints === 0 ? g.noHintBonus : 0), note: 'rewarded' }
    }
  }
}

function safeScore(r: RunResult): number {
  try {
    const v = scoreOf(r)
    return Number.isFinite(v) ? Math.max(0, Math.floor(v)) : 0
  } catch {
    return 0
  }
}
