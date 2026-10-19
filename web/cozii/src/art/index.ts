import { GC } from './gc'
import { drawPet } from './ported/PetPainter'
import { ItemPainter } from './ported/ItemPainter'
import type { PetAppearance, PetMood, PetPose } from '../content/pet'
import { restPose, appearanceKey } from '../content/pet'

export { GC }

/** Vẽ thú cưng (hệ 100×100) vào vùng (x, y, size) của canvas. */
export function paintPet(
  c: CanvasRenderingContext2D, x: number, y: number, size: number,
  appearance: PetAppearance, mood: PetMood = 'idle', pose: PetPose = restPose(), flip = false,
) {
  const g = new GC(c)
  g.translateBy(x, y)
  if (flip) {
    g.translateBy(size, 0)
    g.scaleBy(-1, 1)
  }
  g.scaleBy(size / 100, size / 100)
  drawPet(g, mood, appearance, pose)
}

/** Vẽ một món đồ: đồ thường 100×100, tường & sàn 125×100 — co vừa khung (w, h). */
export function paintItem(c: CanvasRenderingContext2D, id: string, x: number, y: number, w: number, h: number, scene: boolean, flip = false) {
  const g = new GC(c)
  const width = scene ? 125 : 100
  const k = Math.min(w / width, h / 100)
  g.translateBy(x + (w - width * k) / 2, y + (h - 100 * k) / 2)
  if (flip) {
    g.translateBy(width * k, 0)
    g.scaleBy(-1, 1)
  }
  g.scaleBy(k, k)
  ItemPainter.draw(id, g)
}

// Bộ đệm ảnh thú cưng theo (ngoại hình, tư thế, cỡ) — dùng trong game và danh sách. Giới hạn số ảnh.
const spriteCache = new Map<string, HTMLCanvasElement>()
const MAX_SPRITES = 48

export function petSprite(appearance: PetAppearance, mood: PetMood, pose: PetPose, px: number, poseKey = 'rest'): HTMLCanvasElement {
  const dpr = Math.min(2, globalThis.devicePixelRatio || 1)
  const size = Math.round(px * dpr)
  const key = `${appearanceKey(appearance)}#${mood}#${poseKey}#${size}`
  const hit = spriteCache.get(key)
  if (hit) {
    spriteCache.delete(key)
    spriteCache.set(key, hit)
    return hit
  }
  const cv = document.createElement('canvas')
  cv.width = size
  cv.height = size
  const c = cv.getContext('2d')!
  paintPet(c, 0, 0, size, appearance, mood, pose)
  spriteCache.set(key, cv)
  while (spriteCache.size > MAX_SPRITES) {
    const first = spriteCache.keys().next().value
    if (first === undefined) break
    spriteCache.delete(first)
  }
  return cv
}

export function clearSpriteCache() {
  spriteCache.clear()
}
