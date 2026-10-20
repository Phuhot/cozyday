// Vườn Nốt Nhạc — game nhịp điệu 3 làn. Giai điệu tự sáng tác cho Cozii (không dùng nhạc có bản quyền),
// phát bằng Web Audio. Có cue hình ảnh, chơi được khi tắt tiếng, có hiệu chỉnh độ trễ.

export interface Song {
  id: string
  name: string
  bpm: number
  /** [nhịp, cao độ MIDI] */
  notes: [number, number][]
}

const A: [number, number][] = [
  [0, 72], [1, 76], [2, 79], [3, 76], [4, 74], [5, 72], [6, 74], [7, 76], [8, 67], [9, 69], [10, 72], [11, 69], [12, 67], [14, 72],
  [16, 76], [17, 79], [18, 81], [19, 79], [20, 76], [21, 74], [22, 72], [23, 74], [24, 76], [25, 76], [26, 74], [27, 72], [28, 74], [30, 72],
  [32, 72], [32.5, 74], [33, 76], [34, 79], [35, 81], [36, 79], [37, 76], [38, 74], [39, 72], [40, 69], [41, 72], [42, 74], [43, 76], [44, 74], [46, 72],
  [48, 67], [49, 72], [50, 76], [51, 79], [52, 81], [53, 79], [54, 76], [55, 72], [56, 74], [57, 76], [58, 74], [59, 72], [60, 67], [62, 72],
]

const B: [number, number][] = [
  [0, 69], [1.5, 72], [2, 74], [3, 76], [4, 74], [5.5, 72], [6, 69], [8, 67], [9, 69], [10, 72], [11.5, 69], [12, 64], [14, 67],
  [16, 69], [16.5, 72], [17, 74], [18, 76], [19, 79], [20, 76], [21.5, 74], [22, 72], [24, 74], [25, 76], [26, 74], [27, 72], [28, 69], [30, 69],
  [32, 76], [33, 79], [33.5, 81], [34, 79], [35, 76], [36, 74], [37.5, 72], [38, 74], [40, 72], [41, 69], [42, 67], [43, 69], [44, 72], [46, 69],
  [48, 64], [49, 67], [50, 69], [51, 72], [52, 74], [53.5, 76], [54, 74], [55, 72], [56, 69], [57, 72], [58, 74], [59, 72], [60, 69],
]

const C: [number, number][] = [
  [0, 72], [0.5, 72], [1, 79], [1.5, 79], [2, 81], [2.5, 81], [3, 79], [4, 77], [4.5, 77], [5, 76], [5.5, 76], [6, 74], [6.5, 74], [7, 72],
  [8, 79], [8.5, 79], [9, 77], [9.5, 77], [10, 76], [10.5, 76], [11, 74], [12, 79], [12.5, 79], [13, 77], [13.5, 77], [14, 76], [14.5, 76], [15, 74],
  [16, 72], [16.5, 72], [17, 79], [17.5, 79], [18, 81], [18.5, 81], [19, 79], [20, 77], [20.5, 77], [21, 76], [21.5, 76], [22, 74], [22.5, 74], [23, 72],
  [24, 67], [25, 72], [26, 76], [27, 79], [28, 84], [30, 72],
]

export const SONGS: Song[] = [
  { id: 'morning', name: 'Sáng trong vườn', bpm: 96, notes: A },
  { id: 'rain', name: 'Mưa trên mái ngói', bpm: 88, notes: B },
  { id: 'festival', name: 'Nhỏ to ngày hội', bpm: 104, notes: C },
]

export const JUDGE = { perfect: 0.07, good: 0.14 }
export const LEAD_IN = 2.0

export function laneOf(midi: number): 0 | 1 | 2 {
  return midi <= 69 ? 0 : midi <= 74 ? 1 : 2
}

export function midiHz(m: number): number {
  return 440 * Math.pow(2, (m - 69) / 12)
}

export interface Note { t: number; lane: 0 | 1 | 2; midi: number; judged: null | 'perfect' | 'good' | 'miss'; played: boolean }

export class Rhythm {
  readonly song: Song
  time = 0
  notes: Note[]
  combo = 0
  bestCombo = 0
  perfect = 0
  good = 0
  miss = 0
  over = false
  readonly duration: number
  /** Độ trễ người chơi (giây) — cộng vào khi chấm. */
  offset: number

  constructor(song: Song, offsetMs = 0) {
    this.song = song
    this.offset = offsetMs / 1000
    const spb = 60 / song.bpm
    this.notes = song.notes.map(([b, m]) => ({ t: LEAD_IN + b * spb, lane: laneOf(m), midi: m, judged: null, played: false }))
    this.duration = Math.ceil(this.notes[this.notes.length - 1].t + 1.5)
  }

  get total() {
    return this.notes.length
  }
  get accuracy(): number {
    return Math.round(((this.perfect + this.good * 0.6) / this.total) * 100)
  }

  step(dt: number): Note[] {
    if (this.over) return []
    this.time += Math.min(dt, 0.1)
    for (const n of this.notes) {
      if (!n.judged && this.time - this.offset > n.t + JUDGE.good) {
        n.judged = 'miss'
        this.miss += 1
        this.combo = 0
      }
    }
    if (this.time >= this.duration) this.over = true
    return this.notes.filter(n => !n.played && n.t <= this.time + 0.25)
  }

  tap(lane: number): 'perfect' | 'good' | null {
    if (this.over) return null
    const t = this.time - this.offset
    let best: Note | null = null
    for (const n of this.notes) {
      if (n.judged || n.lane !== lane) continue
      const d = Math.abs(n.t - t)
      if (d <= JUDGE.good && (!best || d < Math.abs(best.t - t))) best = n
    }
    if (!best) return null
    const d = Math.abs(best.t - t)
    best.judged = d <= JUDGE.perfect ? 'perfect' : 'good'
    if (best.judged === 'perfect') this.perfect += 1
    else this.good += 1
    this.combo += 1
    this.bestCombo = Math.max(this.bestCombo, this.combo)
    return best.judged
  }
}
