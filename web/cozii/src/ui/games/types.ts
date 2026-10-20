import type { RunResult } from '../../core/games'
import type { PetAppearance } from '../../content/pet'

export interface HudItem {
  label: string
  value: string
}

/** Một lượt chơi đang chạy. Khung game (GameShell) gọi step/render bằng một vòng requestAnimationFrame duy nhất,
 *  dừng hẳn khi tạm dừng / vào nền, và vứt bỏ đối tượng khi chơi lại (không giữ callback của lượt cũ). */
export interface GameView {
  /** Tỉ lệ khung (rộng / cao). */
  readonly aspect: number
  step(dt: number): void
  render(c: CanvasRenderingContext2D, w: number, h: number, t: number): void
  pointer(type: 'down' | 'move' | 'up', x: number, y: number, w: number, h: number): void
  key(type: 'down' | 'up', key: string): void
  hud(): HudItem[]
  over(): boolean
  result(completed: boolean): RunResult
  dispose(): void
}

export interface GameOpts {
  seed: number
  appearance: PetAppearance
  reduceMotion: boolean
  variant?: string
  sfx: (name: Parameters<typeof import('../../app/sound').sfx>[0]) => void
}

export const PET_HITBOX_NOTE = 'Hitbox của bạn nhỏ cố định, không phụ thuộc loài hay trang phục.'
