import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from 'react'
import type { Action, ActionResult } from '../core/engine'
import type { GameState } from '../core/state'
import { BackendError, type Backend, type SocialApi } from '../backend/types'
import { uuid } from '../backend/local'
import { sfx } from './sound'

export interface Toast {
  id: number
  text: string
  tone: 'info' | 'good' | 'warn'
}

interface PendingAction {
  action: Action
  requestId: string
}

export interface GameCtx {
  state: GameState
  backend: Backend
  social: SocialApi | null
  /** Gửi một thao tác. Trả về kết quả, hoặc null nếu bị từ chối (đã hiện thông báo). */
  act: (a: Action, opts?: { quiet?: boolean; requestId?: string }) => Promise<ActionResult | null>
  busy: boolean
  online: boolean
  /** Giờ máy chủ ước tính (ms) — dùng để hiển thị đếm ngược. */
  serverNow: () => number
  toast: (text: string, tone?: Toast['tone']) => void
  toasts: Toast[]
  dismissToast: (id: number) => void
  reload: () => Promise<void>
  /** Có thao tác chưa gửi được vì mất mạng (sẽ thử lại cùng mã yêu cầu). */
  pending: PendingAction | null
  retryPending: () => Promise<void>
}

const Ctx = createContext<GameCtx | null>(null)

export function useGame(): GameCtx {
  const v = useContext(Ctx)
  if (!v) throw new Error('useGame ngoài GameProvider')
  return v
}

const PENDING_KEY = 'cozii:pending'

export function GameProvider({ backend, social, initial, children }: { backend: Backend; social: SocialApi | null; initial: GameState; children: ReactNode }) {
  const [state, setState] = useState(initial)
  const [busy, setBusy] = useState(false)
  const [online, setOnline] = useState(typeof navigator === 'undefined' ? true : navigator.onLine)
  const [toasts, setToasts] = useState<Toast[]>([])
  const [pending, setPending] = useState<PendingAction | null>(() => {
    try {
      const raw = localStorage.getItem(PENDING_KEY)
      return raw ? (JSON.parse(raw) as PendingAction) : null
    } catch {
      return null
    }
  })
  const offset = useRef(initial.serverNow - Date.now())
  const lastToast = useRef<{ text: string; at: number }>({ text: '', at: 0 })
  const toastId = useRef(1)
  const inflight = useRef(false)

  const toast = useCallback((text: string, tone: Toast['tone'] = 'info') => {
    // Không dồn thông báo trùng lặp liên tục.
    const now = Date.now()
    if (lastToast.current.text === text && now - lastToast.current.at < 2500) return
    lastToast.current = { text, at: now }
    const id = toastId.current++
    setToasts(t => [...t.slice(-2), { id, text, tone }])
    setTimeout(() => setToasts(t => t.filter(x => x.id !== id)), tone === 'warn' ? 4200 : 2800)
  }, [])

  const dismissToast = useCallback((id: number) => setToasts(t => t.filter(x => x.id !== id)), [])

  const accept = useCallback((s: GameState) => {
    offset.current = s.serverNow - Date.now()
    setState(s)
  }, [])

  const savePending = (p: PendingAction | null) => {
    setPending(p)
    try {
      if (p) localStorage.setItem(PENDING_KEY, JSON.stringify(p))
      else localStorage.removeItem(PENDING_KEY)
    } catch {
      /* bỏ qua */
    }
  }

  const send = useCallback(async (a: Action, requestId: string, quiet: boolean): Promise<ActionResult | null> => {
    setBusy(true)
    inflight.current = true
    try {
      const r = await backend.act(a, requestId)
      accept(r.state)
      setOnline(true)
      return r.result ?? {}
    } catch (e) {
      if (e instanceof BackendError && e.network) {
        // Giữ lại để thử lại đúng mã yêu cầu: máy chủ chỉ xử lý một lần.
        savePending({ action: a, requestId })
        setOnline(false)
        if (!quiet) toast('Mất kết nối. Thao tác sẽ được gửi lại khi có mạng.', 'warn')
        return null
      }
      if (!quiet) {
        toast(e instanceof Error ? e.message : 'Có lỗi xảy ra.', 'warn')
        sfx('nope')
      }
      return null
    } finally {
      inflight.current = false
      setBusy(false)
    }
  }, [backend, accept, toast])

  const act = useCallback(async (a: Action, opts?: { quiet?: boolean; requestId?: string }) => {
    if (pending && pending.requestId !== opts?.requestId) {
      toast('Đang chờ gửi lại thao tác trước khi mất mạng.', 'warn')
      return null
    }
    const r = await send(a, opts?.requestId ?? uuid(), !!opts?.quiet)
    if (r && pending?.requestId === opts?.requestId) savePending(null)
    return r
  }, [send, pending, toast])

  const retryPending = useCallback(async () => {
    if (!pending || inflight.current) return
    const r = await send(pending.action, pending.requestId, true)
    if (r) {
      savePending(null)
      toast('Đã gửi lại thao tác còn dở.', 'good')
    }
  }, [pending, send, toast])

  const reload = useCallback(async () => {
    try {
      accept(await backend.load())
      setOnline(true)
    } catch (e) {
      if (e instanceof BackendError && e.network) setOnline(false)
    }
  }, [backend, accept])

  useEffect(() => {
    const on = () => {
      setOnline(true)
      void retryPending()
      void reload()
    }
    const off = () => setOnline(false)
    window.addEventListener('online', on)
    window.addEventListener('offline', off)
    return () => {
      window.removeEventListener('online', on)
      window.removeEventListener('offline', off)
    }
  }, [retryPending, reload])

  // Khi quay lại tab sau một lúc: lấy trạng thái mới (không polling liên tục).
  useEffect(() => {
    let hiddenAt = 0
    const vis = () => {
      if (document.hidden) hiddenAt = Date.now()
      else if (hiddenAt && Date.now() - hiddenAt > 60_000) void reload()
    }
    document.addEventListener('visibilitychange', vis)
    return () => document.removeEventListener('visibilitychange', vis)
  }, [reload])

  useEffect(() => {
    if (pending && online) void retryPending()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const value = useMemo<GameCtx>(() => ({
    state, backend, social, act, busy, online,
    serverNow: () => Date.now() + offset.current,
    toast, toasts, dismissToast, reload, pending, retryPending,
  }), [state, backend, social, act, busy, online, toast, toasts, dismissToast, reload, pending, retryPending])

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>
}
