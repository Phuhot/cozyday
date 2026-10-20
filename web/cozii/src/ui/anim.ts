import { useEffect, useRef, useState } from 'react'
import { restPose, type PetMood, type PetPose } from '../content/pet'

function readMotionPref(): 'system' | 'reduce' | 'full' {
  try {
    const v = localStorage.getItem('cozii:motion')
    return v === 'reduce' || v === 'full' ? v : 'system'
  } catch {
    return 'system'
  }
}

let motionPref = readMotionPref()
const listeners = new Set<() => void>()

export function setMotionPref(v: 'system' | 'reduce' | 'full') {
  motionPref = v
  try {
    localStorage.setItem('cozii:motion', v)
  } catch {
    /* bỏ qua */
  }
  listeners.forEach(l => l())
}
export function getMotionPref() {
  return motionPref
}

export function prefersReducedMotion(): boolean {
  if (motionPref === 'reduce') return true
  if (motionPref === 'full') return false
  return typeof matchMedia !== 'undefined' && matchMedia('(prefers-reduced-motion: reduce)').matches
}

export function useReducedMotion(): boolean {
  const [v, setV] = useState(prefersReducedMotion)
  useEffect(() => {
    const mq = typeof matchMedia !== 'undefined' ? matchMedia('(prefers-reduced-motion: reduce)') : null
    const on = () => setV(prefersReducedMotion())
    mq?.addEventListener?.('change', on)
    listeners.add(on)
    return () => {
      mq?.removeEventListener?.('change', on)
      listeners.delete(on)
    }
  }, [])
  return v
}

/** Gọi `cb(tGiây, dtGiây)` mỗi khung hình khi `active`; tự dừng khi tab ẩn. Giới hạn ~`fps`. */
export function useFrame(cb: (t: number, dt: number) => void, active = true, fps = 60) {
  const ref = useRef(cb)
  ref.current = cb
  useEffect(() => {
    if (!active) return
    let raf = 0
    let last = performance.now()
    let acc = 0
    const minDt = 1000 / fps - 1
    const start = performance.now()
    const loop = (now: number) => {
      raf = requestAnimationFrame(loop)
      const d = now - last
      acc += d
      last = now
      if (acc < minDt) return
      const dt = Math.min(acc, 100) / 1000
      acc = 0
      ref.current((now - start) / 1000, dt)
    }
    raf = requestAnimationFrame(loop)
    return () => cancelAnimationFrame(raf)
  }, [active, fps])
}

export interface PetFx {
  /** thời điểm (giây, cùng đồng hồ với t) bắt đầu nhảy / thả tim / nựng tới khi nào */
  hopAt?: number
  heartsAt?: number
  pettedUntil?: number
  lifted?: boolean
  walking?: boolean
}

/** Tư thế theo thời gian — chuyển từ PetView.pose của bản iOS. */
export function petPoseAt(t: number, mood: PetMood, fx: PetFx, reduce: boolean): PetPose {
  const p = restPose()
  if (reduce) {
    if (fx.pettedUntil && fx.pettedUntil > t) p.petted = 1
    p.lifted = !!fx.lifted
    if (fx.heartsAt != null && t - fx.heartsAt < 1.4) p.hearts = 0.5
    return p
  }
  const TAU = Math.PI * 2
  p.breath = Math.sin((t * TAU) / 3.2)
  p.blink = t % 4.3 < 0.14
  p.tail = Math.sin((t * TAU) / (mood === 'happy' ? 0.9 : 1.9))
  const ep = t % 6.7
  p.ear = ep < 0.3 ? Math.sin((ep / 0.3) * Math.PI) : 0
  p.look = mood === 'focus' ? 0 : Math.sin(t / 3.1) * 0.8
  if (mood === 'happy') p.tilt = Math.sin((t * TAU) / 1.6) * 3
  if (fx.walking) {
    p.walk = (t * TAU) / 0.55
    p.hop = Math.abs(Math.sin((t * TAU) / 0.55)) * 1.6
  }
  if (fx.hopAt != null) {
    const d = t - fx.hopAt
    if (d >= 0 && d < 0.7) p.hop = Math.abs(Math.sin((d / 0.35) * Math.PI)) * 9
  }
  if (fx.heartsAt != null) {
    const d = t - fx.heartsAt
    if (d >= 0 && d < 1.4) p.hearts = d / 1.4
  }
  p.z = (t / 2.4) % 1
  if (fx.pettedUntil != null && fx.pettedUntil > t) {
    p.petted = Math.min(1, (fx.pettedUntil - t) / 0.3)
    p.tilt = Math.sin((t * TAU) / 0.7) * 5
    p.tail = Math.sin((t * TAU) / 0.5)
  }
  if (fx.lifted) {
    p.lifted = true
    p.hop = 7
    p.tilt = Math.sin((t * TAU) / 1.2) * 7
    p.walk = null
  }
  return p
}

/** Chuẩn bị canvas theo tỉ lệ điểm ảnh của màn hình (giới hạn 2× để tiết kiệm bộ nhớ). */
export function fitCanvas(cv: HTMLCanvasElement, cssW: number, cssH: number): CanvasRenderingContext2D {
  const dpr = Math.min(2, window.devicePixelRatio || 1)
  const w = Math.max(1, Math.round(cssW * dpr)), h = Math.max(1, Math.round(cssH * dpr))
  if (cv.width !== w || cv.height !== h) {
    cv.width = w
    cv.height = h
  }
  const c = cv.getContext('2d')!
  c.setTransform(dpr, 0, 0, dpr, 0, 0)
  return c
}

export function useElementWidth<T extends HTMLElement>(): [React.RefObject<T | null>, number] {
  const ref = useRef<T | null>(null)
  const [w, setW] = useState(0)
  useEffect(() => {
    const el = ref.current
    if (!el) return
    const ro = new ResizeObserver(() => setW(el.clientWidth))
    ro.observe(el)
    setW(el.clientWidth)
    return () => ro.disconnect()
  }, [])
  return [ref, w]
}
