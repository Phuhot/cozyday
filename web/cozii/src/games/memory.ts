// Lật Thẻ — chuyển từ MemoryBoard (Swift). Mỗi lần mở tối đa hai thẻ; cặp sai khóa bàn tới khi được úp lại,
// mã `token` bảo đảm lệnh úp trễ của lần trước (hay của bàn cũ) không làm hỏng bàn hiện tại.
import { Lcg } from './rng'

export type CardState = 'down' | 'up' | 'matched'
export interface Card { id: number; face: number; state: CardState }
export type FlipResult = { type: 'ignored' } | { type: 'opened' } | { type: 'matched' } | { type: 'mismatch'; token: number } | { type: 'completed' }

export const MEMORY_LEVELS = { easy: { pairs: 6, cols: 3 }, medium: { pairs: 8, cols: 4 } } as const
export type MemoryLevel = keyof typeof MEMORY_LEVELS
/** Số mặt thẻ có thể dùng (loài pet + nông sản). */
export const FACE_COUNT = 14

function shuffle<T>(a: T[], r: Lcg): T[] {
  const out = [...a]
  for (let i = out.length - 1; i > 0; i--) {
    const j = r.int(0, i)
    ;[out[i], out[j]] = [out[j], out[i]]
  }
  return out
}

export class MemoryBoard {
  readonly level: MemoryLevel
  cards: Card[]
  moves = 0
  pairs = 0
  pending: { a: number; b: number; token: number } | null = null
  private tokenCounter = 0

  constructor(level: MemoryLevel, seed: number) {
    this.level = level
    const r = new Lcg(seed)
    const n = MEMORY_LEVELS[level].pairs
    const faces = shuffle(Array.from({ length: FACE_COUNT }, (_, i) => i), r).slice(0, n)
    const deck = shuffle([...faces, ...faces], r)
    this.cards = deck.map((face, id) => ({ id, face, state: 'down' }))
  }

  get complete() {
    return this.pairs === MEMORY_LEVELS[this.level].pairs
  }
  get locked() {
    return this.pending !== null
  }
  openUnmatched(): number[] {
    return this.cards.filter(c => c.state === 'up').map(c => c.id)
  }

  flip(i: number): FlipResult {
    if (this.complete || this.locked || i < 0 || i >= this.cards.length || this.cards[i].state !== 'down') return { type: 'ignored' }
    const open = this.openUnmatched()
    if (open.length >= 2) return { type: 'ignored' }
    this.cards[i].state = 'up'
    if (open.length === 0) return { type: 'opened' }
    const first = open[0]
    this.moves += 1
    if (this.cards[first].face === this.cards[i].face) {
      this.cards[first].state = 'matched'
      this.cards[i].state = 'matched'
      this.pairs += 1
      return this.complete ? { type: 'completed' } : { type: 'matched' }
    }
    this.tokenCounter += 1
    this.pending = { a: first, b: i, token: this.tokenCounter }
    return { type: 'mismatch', token: this.tokenCounter }
  }

  resolveMismatch(token: number): boolean {
    const p = this.pending
    if (!p || p.token !== token) return false
    this.cards[p.a].state = 'down'
    this.cards[p.b].state = 'down'
    this.pending = null
    return true
  }
}
