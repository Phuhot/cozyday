import { useEffect, useMemo, useRef, useState } from 'react'
import { paintItem, paintPet } from '../art'
import { drawOrder, room as roomDef, SPOTS, type ItemSlot, type RoomId } from '../content/catalog'
import type { PetAppearance, PetMood } from '../content/pet'
import type { PlacedItem, RoomState } from '../core/state'
import { fitCanvas, petPoseAt, useElementWidth, useFrame, useReducedMotion, type PetFx } from './anim'
import { sfx, unlockAudio } from '../app/sound'
import { GC, rgb, Color, pt } from '../art/gc'

export interface Dirt {
  id: number
  x: number
  y: number
  kind: 'dust' | 'leaf' | 'paper' | 'web' | 'mud'
  hp: number
}

interface Props {
  room: RoomId
  state: RoomState
  appearance: PetAppearance
  mood: PetMood
  petName: string
  mode?: 'live' | 'decorate' | 'clean' | 'visit' | 'static'
  activeSlot?: ItemSlot | null
  preview?: { slot: ItemSlot; placed: PlacedItem | null } | null
  previewTheme?: string | null
  onSlotTap?: (slot: ItemSlot) => void
  onPetTap?: () => void
  onStroke?: (d: number) => void
  bubble?: string | null
  dirt?: Dirt[]
  onScrub?: (id: number, amount: number) => void
  hidePet?: boolean
  /** Vẽ một lần (ảnh chụp). */
  canvasRef?: React.RefObject<HTMLCanvasElement | null>
  petFx?: PetFx
}

const W = 125

/** Một căn phòng với đồ đặt theo vị trí cố định và bạn nhỏ đi lại (tắt khi Giảm chuyển động). */
export function RoomCanvas(p: Props) {
  const [wrapRef, width] = useElementWidth<HTMLDivElement>()
  const cvRef = useRef<HTMLCanvasElement>(null)
  const reduce = useReducedMotion()
  const layer = useRef<HTMLCanvasElement | null>(null)
  const t = useRef(0)
  const fx = useRef<PetFx>({})
  const home = useRef<number | null>(null)
  const cycleStart = useRef(0)
  const lift = useRef<{ dx: number; dy: number } | null>(null)
  const pointer = useRef<{ x: number; y: number; moved: number; onPet: boolean; timer: number | null; startX: number; startY: number } | null>(null)
  const petRect = useRef({ x: 0, y: 0, s: 0 })
  const [bubblePos, setBubblePos] = useState({ x: 50, y: 30 })

  const def = roomDef(p.room)
  const h = width * 0.8
  const k = width / W

  const slots = useMemo(() => {
    const s = { ...p.state.slots }
    if (p.preview) {
      if (p.preview.placed) s[p.preview.slot] = p.preview.placed
      else delete s[p.preview.slot]
    }
    return s
  }, [p.state.slots, p.preview])
  const theme = p.previewTheme ?? p.state.theme

  // Lớp tĩnh: tường & sàn + đồ đạc — chỉ vẽ lại khi bố cục đổi.
  useEffect(() => {
    if (!width) return
    const dpr = Math.min(2, window.devicePixelRatio || 1)
    const cv = layer.current ?? document.createElement('canvas')
    layer.current = cv
    cv.width = Math.round(width * dpr)
    cv.height = Math.round(h * dpr)
    const c = cv.getContext('2d')!
    c.setTransform(dpr, 0, 0, dpr, 0, 0)
    c.clearRect(0, 0, width, h)
    paintItem(c, theme, 0, 0, width, h, true)
    for (const slot of drawOrder(def)) {
      const pl = slots[slot]
      const spot = SPOTS[slot]!
      if (!pl) continue
      paintItem(c, pl.item, (spot.x + pl.dx) * k, spot.y * k, spot.size * k, spot.size * k, false, pl.flip)
    }
    draw(t.current)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [width, theme, slots, p.room])

  useEffect(() => {
    home.current = null
  }, [p.room])

  const canWander = !reduce && (p.mode === 'live' || p.mode === 'visit') && (p.mood === 'idle' || p.mood === 'happy') && !lift.current

  function petSpot(time: number) {
    const a = home.current ?? def.petHome
    const b = a > 0.45 ? a - 0.24 : a + 0.26
    const goesLeft = b < a
    if (!canWander) return { x: a, walking: false, left: false }
    const tt = (time - cycleStart.current) % 26
    const ease = (v: number) => v * v * (3 - 2 * v)
    if (tt < 9) return { x: a, walking: false, left: false }
    if (tt < 12) return { x: a + (b - a) * ease((tt - 9) / 3), walking: true, left: goesLeft }
    if (tt < 21) return { x: b, walking: false, left: tt > 19 ? !goesLeft : goesLeft }
    if (tt < 24) return { x: b - (b - a) * ease((tt - 21) / 3), walking: true, left: !goesLeft }
    return { x: a, walking: false, left: false }
  }

  function draw(time: number) {
    const cv = cvRef.current
    if (!cv || !width || !layer.current) return
    const c = fitCanvas(cv, width, h)
    c.clearRect(0, 0, width, h)
    c.drawImage(layer.current, 0, 0, width, h)
    if (p.dirt?.length) drawDirt(c, p.dirt, k)
    if (!p.hidePet) {
      const sp = petSpot(time)
      const size = width * 0.3
      let x = width * sp.x
      let y = h * 0.86 - size
      if (lift.current) {
        x += lift.current.dx
        y += Math.max(-h * 0.5, Math.min(h * 0.08, lift.current.dy))
      }
      petRect.current = { x, y, s: size }
      const pose = petPoseAt(time, p.mood, { ...p.petFx, ...fx.current, walking: sp.walking, lifted: !!lift.current }, reduce)
      paintPet(c, x, y, size, p.appearance, p.mood, pose, sp.left)
    }
    if (p.mode === 'decorate' && p.activeSlot) {
      const s = SPOTS[p.activeSlot]!
      const g = new GC(c)
      g.scaleBy(k, k)
      g.strokePath(rgb(0x8d78cf), 1.2 / Math.max(0.5, k / 4), q => q.addRoundedRect({ x: s.x + 1, y: s.y + 1, width: s.size - 2, height: s.size - 2 } as never, 4))
    }
  }

  useFrame(time => {
    t.current = time
    draw(time)
    if (p.bubble) {
      const r = petRect.current
      setBubblePos(prev => {
        const nx = ((r.x + r.s / 2) / width) * 100
        const ny = (r.y / h) * 100 + 4
        return Math.abs(prev.x - nx) > 0.5 || Math.abs(prev.y - ny) > 0.5 ? { x: nx, y: ny } : prev
      })
    }
  }, !!width && (!reduce || !!p.dirt?.length), 30)

  useEffect(() => {
    if (reduce) draw(t.current)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [reduce, p.dirt, p.mood, p.appearance, p.hidePet, p.activeSlot, p.mode])

  useEffect(() => {
    if (p.canvasRef && cvRef.current) (p.canvasRef as React.MutableRefObject<HTMLCanvasElement | null>).current = cvRef.current
  })

  const hitPet = (x: number, y: number) => {
    const r = petRect.current
    return x > r.x + r.s * 0.12 && x < r.x + r.s * 0.88 && y > r.y + r.s * 0.15 && y < r.y + r.s * 0.95
  }

  const local = (e: React.PointerEvent) => {
    const rect = cvRef.current!.getBoundingClientRect()
    return { x: e.clientX - rect.left, y: e.clientY - rect.top }
  }

  const onDown = (e: React.PointerEvent) => {
    unlockAudio()
    const { x, y } = local(e)
    const onPet = !p.hidePet && (p.mode === 'live' || p.mode === 'visit') && hitPet(x, y)
    if (p.mode !== 'clean' && !onPet) return
    cvRef.current?.setPointerCapture?.(e.pointerId)
    const st = { x, y, moved: 0, onPet, timer: null as number | null, startX: x, startY: y }
    if (onPet && p.mode === 'live') {
      st.timer = window.setTimeout(() => {
        if (pointer.current && pointer.current.moved < 8) {
          lift.current = { dx: 0, dy: 0 }
          sfx('swish')
        }
      }, 380)
    }
    pointer.current = st
  }

  const onMove = (e: React.PointerEvent) => {
    const st = pointer.current
    if (!st) return
    const { x, y } = local(e)
    const d = Math.hypot(x - st.x, y - st.y)
    st.moved += d
    st.x = x
    st.y = y
    if (lift.current) {
      lift.current = { dx: x - st.startX, dy: y - st.startY }
      return
    }
    if (p.mode === 'clean' && p.dirt && p.onScrub) {
      for (const dd of p.dirt) {
        if (Math.hypot(x - dd.x * k, y - dd.y * k) < 9 * k) p.onScrub(dd.id, d)
      }
      return
    }
    if (st.onPet && st.moved > 8) {
      if (st.timer) {
        clearTimeout(st.timer)
        st.timer = null
      }
      fx.current.pettedUntil = t.current + 0.9
      p.onStroke?.(d)
    }
  }

  const onUp = () => {
    const st = pointer.current
    pointer.current = null
    if (!st) return
    if (st.timer) clearTimeout(st.timer)
    if (lift.current) {
      const r = petRect.current
      home.current = Math.min(0.68, Math.max(0.02, r.x / width))
      cycleStart.current = t.current
      lift.current = null
      fx.current.hopAt = t.current
      return
    }
    if (st.onPet && st.moved <= 8) {
      fx.current.hopAt = t.current
      fx.current.heartsAt = t.current
      sfx('pop')
      p.onPetTap?.()
    }
  }

  return (
    <div ref={wrapRef} className="room-wrap" style={{ aspectRatio: '1.25' }}>
      <canvas
        ref={cvRef}
        style={{ width: '100%', height: '100%', touchAction: p.mode === 'clean' ? 'none' : 'pan-y' }}
        role="img"
        aria-label={`${def.name} của ${p.petName}`}
        onPointerDown={onDown}
        onPointerMove={onMove}
        onPointerUp={onUp}
        onPointerCancel={onUp}
      />
      {p.mode === 'decorate' && p.onSlotTap && (
        <div className="room-overlay">
          {def.slots.map(slot => {
            const s = SPOTS[slot]!
            const pl = slots[slot]
            return (
              <button
                key={slot}
                className={'slot-hit editing' + (p.activeSlot === slot ? ' active' : '')}
                style={{ left: `${((s.x + (pl?.dx ?? 0)) / W) * 100}%`, top: `${s.y}%`, width: `${(s.size / W) * 100}%`, height: `${s.size}%` }}
                aria-label={`Vị trí ${slot}`}
                onClick={() => {
                  sfx('tap')
                  p.onSlotTap!(slot)
                }}
              />
            )
          })}
        </div>
      )}
      {p.bubble && !p.hidePet && (
        <div className="bubble" style={{ left: `${bubblePos.x}%`, top: `${bubblePos.y}%` }} aria-live="polite">{p.bubble}</div>
      )}
    </div>
  )
}

function drawDirt(c: CanvasRenderingContext2D, dirt: Dirt[], k: number) {
  const g = new GC(c)
  g.scaleBy(k, k)
  for (const d of dirt) {
    const a = Math.max(0.25, Math.min(1, d.hp / 60))
    const s = 7
    switch (d.kind) {
      case 'dust':
        g.circle(d.x - 2, d.y, s * 0.55, rgb(0xb8b0a6).opacity(0.75 * a))
        g.circle(d.x + 2.5, d.y - 1, s * 0.45, rgb(0xc9c1b6).opacity(0.75 * a))
        g.circle(d.x + 0.5, d.y + 2, s * 0.4, rgb(0xa9a196).opacity(0.7 * a))
        break
      case 'leaf':
        g.rotated(35, pt(d.x, d.y), r => r.ellipse(d.x - s * 0.6, d.y - s * 0.3, s * 1.2, s * 0.6, rgb(0xd29a52).opacity(a)))
        g.strokePath(rgb(0xa8743a).opacity(a), 0.4, q => { q.move(pt(d.x - 3, d.y - 2)); q.addLine(pt(d.x + 3, d.y + 2)) })
        break
      case 'paper':
        g.rotated(-15, pt(d.x, d.y), r => r.rect(d.x - 3.5, d.y - 2.8, 7, 5.6, Color.white.opacity(0.95 * a), 1))
        g.strokePath(rgb(0xc8bfb2).opacity(a), 0.35, q => { q.move(pt(d.x - 2.5, d.y - 0.5)); q.addLine(pt(d.x + 2, d.y - 1.2)) })
        break
      case 'web': {
        const col = rgb(0x8c8496).opacity(0.85 * a)
        g.strokePath(col, 0.35, q => {
          for (let i = 0; i < 6; i++) {
            const an = (i / 6) * Math.PI * 2
            q.move(pt(d.x, d.y))
            q.addLine(pt(d.x + Math.cos(an) * 6, d.y + Math.sin(an) * 6))
          }
          for (const r of [2, 4, 6]) q.addEllipse({ x: d.x - r, y: d.y - r, width: r * 2, height: r * 2 } as never)
        })
        break
      }
      case 'mud':
        g.ellipse(d.x - 4, d.y - 2.2, 8, 4.4, rgb(0x8a6448).opacity(0.75 * a))
        g.circle(d.x + 4.5, d.y + 1, 1.2, rgb(0x8a6448).opacity(0.7 * a))
        g.circle(d.x - 4.8, d.y + 1.6, 0.9, rgb(0x8a6448).opacity(0.7 * a))
        break
    }
  }
}
