import { useEffect, useRef } from 'react'
import { paintPet, petSprite } from '../art'
import type { PetAppearance, PetMood } from '../content/pet'
import { restPose } from '../content/pet'
import { fitCanvas, petPoseAt, useFrame, useReducedMotion, type PetFx } from './anim'
import { sfx, unlockAudio } from '../app/sound'

interface Props {
  appearance: PetAppearance
  mood?: PetMood
  size: number
  /** Cho phép chạm (nhảy + tim) và vuốt (nựng). */
  interactive?: boolean
  animate?: boolean
  flip?: boolean
  onTap?: () => void
  /** Mỗi đoạn vuốt trên người (px). */
  onStroke?: (distance: number) => void
  label?: string
  fx?: PetFx
}

/** Pet có chuyển động: thở, chớp mắt, vẫy đuôi; chạm để nhảy & thả tim, vuốt để nựng. */
export function PetCanvas({ appearance, mood = 'idle', size, interactive, animate = true, flip, onTap, onStroke, label, fx: fxProp }: Props) {
  const ref = useRef<HTMLCanvasElement>(null)
  const reduce = useReducedMotion()
  const t = useRef(0)
  const fx = useRef<PetFx>({})
  const stroke = useRef<{ x: number; y: number; moved: number; down: boolean; startAt: number } | null>(null)

  const draw = (time: number) => {
    const cv = ref.current
    if (!cv) return
    const c = fitCanvas(cv, size, size)
    c.clearRect(0, 0, size, size)
    paintPet(c, 0, 0, size, appearance, mood, petPoseAt(time, mood, { ...fxProp, ...fx.current }, reduce), flip)
  }

  useFrame(time => {
    t.current = time
    draw(time)
  }, animate && !reduce, 30)

  useEffect(() => {
    draw(t.current)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [appearance, mood, size, reduce, animate, flip])

  const onDown = (e: React.PointerEvent) => {
    if (!interactive) return
    unlockAudio()
    ;(e.target as Element).setPointerCapture?.(e.pointerId)
    stroke.current = { x: e.clientX, y: e.clientY, moved: 0, down: true, startAt: performance.now() }
  }
  const onMove = (e: React.PointerEvent) => {
    const s = stroke.current
    if (!s?.down) return
    const d = Math.hypot(e.clientX - s.x, e.clientY - s.y)
    s.x = e.clientX
    s.y = e.clientY
    s.moved += d
    if (s.moved > 8 && d > 0) {
      fx.current.pettedUntil = t.current + 0.9
      onStroke?.(d)
      if (reduce) draw(t.current)
    }
  }
  const onUp = () => {
    const s = stroke.current
    stroke.current = null
    if (!s) return
    if (s.moved <= 8) {
      fx.current.hopAt = t.current
      fx.current.heartsAt = t.current
      sfx('pop')
      onTap?.()
      if (reduce) draw(t.current)
    }
  }

  return (
    <canvas
      ref={ref}
      style={{ width: size, height: size, touchAction: interactive ? 'none' : 'auto', cursor: interactive ? 'pointer' : 'default' }}
      role={interactive ? 'button' : 'img'}
      aria-label={label ?? 'Bạn nhỏ'}
      tabIndex={interactive ? 0 : -1}
      onKeyDown={e => {
        if (interactive && (e.key === 'Enter' || e.key === ' ')) {
          e.preventDefault()
          fx.current.hopAt = t.current
          fx.current.heartsAt = t.current
          onTap?.()
        }
      }}
      onPointerDown={onDown}
      onPointerMove={onMove}
      onPointerUp={onUp}
      onPointerCancel={onUp}
    />
  )
}

/** Ảnh pet tĩnh (dùng bộ đệm) cho danh sách, thẻ, chân dung NPC. */
export function PetThumb({ appearance, size, mood = 'idle', label }: { appearance: PetAppearance; size: number; mood?: PetMood; label?: string }) {
  const ref = useRef<HTMLCanvasElement>(null)
  useEffect(() => {
    const cv = ref.current
    if (!cv) return
    const c = fitCanvas(cv, size, size)
    c.clearRect(0, 0, size, size)
    c.drawImage(petSprite(appearance, mood, restPose(), size), 0, 0, size, size)
  }, [appearance, size, mood])
  return <canvas ref={ref} style={{ width: size, height: size }} role="img" aria-label={label ?? 'Bạn nhỏ'} />
}

export function drawPetStatic(c: CanvasRenderingContext2D, appearance: PetAppearance, x: number, y: number, size: number, mood: PetMood = 'idle') {
  paintPet(c, x, y, size, appearance, mood, restPose())
}
