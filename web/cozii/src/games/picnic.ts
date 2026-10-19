// Xếp Giỏ Picnic — xếp các miếng đồ ăn (hình khối ô vuông) vừa khít chiếc giỏ dạng lưới. Không đếm giờ bắt buộc.
// Đề được sinh TỪ LỜI GIẢI: chia các ô của giỏ thành những miếng liền nhau 2–4 ô, nên luôn có ít nhất một cách xếp.
// Miếng được xoay 90°.
import { Lcg } from './rng'

export type Cellxy = [number, number] // [cột, hàng]

export interface Piece {
  id: number
  /** Hình gốc đã chuẩn hóa (cột, hàng ≥ 0). */
  cells: Cellxy[]
  food: number
}

export interface Puzzle {
  cols: number
  rows: number
  /** Ô thuộc giỏ (true) hay thành giỏ/khoảng trống (false). */
  mask: boolean[]
  pieces: Piece[]
  /** Lời giải: id miếng → các ô đặt trong giỏ. */
  solution: Record<number, Cellxy[]>
}

export const PICNIC_FOODS = ['sandwich', 'cake', 'grapes', 'onigiri', 'cookie', 'carrot', 'strawberry', 'cheese', 'pie'] as const

export function normalize(cells: Cellxy[]): Cellxy[] {
  const minC = Math.min(...cells.map(c => c[0]))
  const minR = Math.min(...cells.map(c => c[1]))
  return cells.map(([c, r]) => [c - minC, r - minR] as Cellxy).sort((a, b) => a[1] - b[1] || a[0] - b[0])
}

export function rotate(cells: Cellxy[], times: number): Cellxy[] {
  let out = cells
  for (let i = 0; i < ((times % 4) + 4) % 4; i++) out = normalize(out.map(([c, r]) => [-r, c] as Cellxy))
  return normalize(out)
}

const SHAPES: { cols: number; rows: number; holes: Cellxy[] }[] = [
  { cols: 4, rows: 3, holes: [] },
  { cols: 4, rows: 4, holes: [[0, 0], [3, 0]] },
  { cols: 5, rows: 4, holes: [[0, 0], [4, 0]] },
  { cols: 5, rows: 4, holes: [[0, 0], [4, 0], [0, 3], [4, 3]] },
  { cols: 5, rows: 5, holes: [[0, 0], [4, 0], [0, 4], [4, 4], [2, 2]] },
]

export function generatePuzzle(seed: number, difficulty = 1): Puzzle {
  const r = new Lcg(seed)
  const shape = SHAPES[Math.min(SHAPES.length - 1, Math.max(0, difficulty + r.int(-1, 1)))]
  const { cols, rows } = shape
  const mask = Array.from({ length: cols * rows }, (_, i) => !shape.holes.some(([c, rr]) => c + rr * cols === i))
  const owner = new Array<number>(cols * rows).fill(-1)
  const pieces: Piece[] = []
  const solution: Record<number, Cellxy[]> = {}
  const free = () => mask.map((m, i) => (m && owner[i] < 0 ? i : -1)).filter(i => i >= 0)
  const neighbors = (i: number) => {
    const c = i % cols, rr = Math.floor(i / cols)
    return [[c - 1, rr], [c + 1, rr], [c, rr - 1], [c, rr + 1]]
      .filter(([x, y]) => x >= 0 && y >= 0 && x < cols && y < rows)
      .map(([x, y]) => x + y * cols)
      .filter(j => mask[j] && owner[j] < 0)
  }
  let id = 0
  let guard = 0
  while (free().length > 0 && guard++ < 200) {
    const left = free()
    // Bắt đầu từ ô trống đầu tiên (đọc theo hàng) để không để lại ô lẻ bị cô lập.
    const start = left[0]
    const target = Math.min(left.length, r.int(2, 4))
    const cellsIdx = [start]
    owner[start] = id
    while (cellsIdx.length < target) {
      const options = cellsIdx.flatMap(neighbors).filter((v, k, a) => a.indexOf(v) === k)
      if (!options.length) break
      const pick = options[r.int(0, options.length - 1)]
      owner[pick] = id
      cellsIdx.push(pick)
    }
    const placed = cellsIdx.map(i => [i % cols, Math.floor(i / cols)] as Cellxy)
    pieces.push({ id, cells: rotate(normalize(placed), r.int(0, 3)), food: r.int(0, PICNIC_FOODS.length - 1) })
    solution[id] = placed
    id++
  }
  // Ghép miếng 1 ô (nếu có) vào miếng kề để mọi miếng ≥ 2 ô.
  for (const p of [...pieces]) {
    const cells = solution[p.id]
    if (cells.length > 1) continue
    const [c, rr] = cells[0]
    const nb = [[c - 1, rr], [c + 1, rr], [c, rr - 1], [c, rr + 1]].map(([x, y]) => (x >= 0 && y >= 0 && x < cols && y < rows ? owner[x + y * cols] : -1)).find(o => o >= 0 && o !== p.id)
    if (nb == null) continue
    solution[nb] = [...solution[nb], cells[0]]
    owner[c + rr * cols] = nb
    const target = pieces.find(x => x.id === nb)!
    target.cells = rotate(normalize(solution[nb]), r.int(0, 3))
    delete solution[p.id]
    pieces.splice(pieces.indexOf(p), 1)
  }
  return { cols, rows, mask, pieces, solution }
}

export interface Placement { piece: number; rot: number; col: number; row: number }

export class PicnicBoard {
  readonly puzzle: Puzzle
  placements = new Map<number, Placement>()
  moves = 0
  hints = 0

  constructor(p: Puzzle) {
    this.puzzle = p
  }

  cellsOf(pl: Placement): Cellxy[] {
    const piece = this.puzzle.pieces.find(x => x.id === pl.piece)!
    return rotate(piece.cells, pl.rot).map(([c, r]) => [c + pl.col, r + pl.row] as Cellxy)
  }

  occupied(except?: number): Map<number, number> {
    const m = new Map<number, number>()
    for (const [id, pl] of this.placements) {
      if (id === except) continue
      for (const [c, r] of this.cellsOf(pl)) m.set(c + r * this.puzzle.cols, id)
    }
    return m
  }

  fits(pl: Placement): boolean {
    const { cols, rows, mask } = this.puzzle
    const occ = this.occupied(pl.piece)
    return this.cellsOf(pl).every(([c, r]) => c >= 0 && r >= 0 && c < cols && r < rows && mask[c + r * cols] && !occ.has(c + r * cols))
  }

  place(pl: Placement): boolean {
    if (!this.fits(pl)) return false
    this.placements.set(pl.piece, pl)
    this.moves += 1
    return true
  }

  remove(piece: number) {
    this.placements.delete(piece)
  }

  get solved(): boolean {
    const occ = this.occupied()
    return this.puzzle.mask.every((m, i) => !m || occ.has(i))
  }

  /** Gợi ý: đặt một miếng chưa đúng vào vị trí trong lời giải (gỡ miếng đang chiếm chỗ). */
  hint(): number | null {
    for (const piece of this.puzzle.pieces) {
      const target = this.puzzle.solution[piece.id]
      const key = new Set(target.map(([c, r]) => c + r * this.puzzle.cols))
      const cur = this.placements.get(piece.id)
      if (cur && this.cellsOf(cur).every(([c, r]) => key.has(c + r * this.puzzle.cols))) continue
      for (let rot = 0; rot < 4; rot++) {
        const shape = rotate(piece.cells, rot)
        const minC = Math.min(...target.map(t => t[0]))
        const minR = Math.min(...target.map(t => t[1]))
        const norm = normalize(target)
        if (JSON.stringify(norm) !== JSON.stringify(shape)) continue
        // gỡ các miếng đang đè lên chỗ này
        const occ = this.occupied(piece.id)
        for (const k of key) {
          const other = occ.get(k)
          if (other != null) this.placements.delete(other)
        }
        this.placements.set(piece.id, { piece: piece.id, rot, col: minC, row: minR })
        this.hints += 1
        return piece.id
      }
    }
    return null
  }
}

/** Bộ giải (dùng trong test): kiểm tra đề có lời giải bằng quay lui. */
export function solvable(p: Puzzle): boolean {
  const b = new PicnicBoard(p)
  const pieces = [...p.pieces].sort((x, y) => y.cells.length - x.cells.length)
  const go = (k: number): boolean => {
    if (k === pieces.length) return b.solved
    const piece = pieces[k]
    for (let rot = 0; rot < 4; rot++) for (let row = 0; row < p.rows; row++) for (let col = 0; col < p.cols; col++) {
      const pl = { piece: piece.id, rot, col, row }
      if (b.fits(pl)) {
        b.placements.set(piece.id, pl)
        if (go(k + 1)) return true
        b.placements.delete(piece.id)
      }
    }
    return false
  }
  return go(0)
}
