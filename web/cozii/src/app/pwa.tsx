import { useEffect, useState } from 'react'
import { useRoute } from './router'
import { useGame } from './game'

let waiting: ServiceWorker | null = null
const subs = new Set<() => void>()

export function registerSW() {
  if (!('serviceWorker' in navigator) || import.meta.env.DEV) return
  window.addEventListener('load', async () => {
    try {
      const reg = await navigator.serviceWorker.register('/sw.js')
      const check = (w: ServiceWorker | null) => {
        if (!w) return
        w.addEventListener('statechange', () => {
          if (w.state === 'installed' && navigator.serviceWorker.controller) {
            waiting = w
            subs.forEach(f => f())
          }
        })
      }
      if (reg.waiting && navigator.serviceWorker.controller) {
        waiting = reg.waiting
        subs.forEach(f => f())
      }
      reg.addEventListener('updatefound', () => check(reg.installing))
      // Kiểm tra bản mới khi quay lại app (không dò liên tục).
      document.addEventListener('visibilitychange', () => {
        if (!document.hidden) void reg.update().catch(() => {})
      })
      let reloaded = false
      navigator.serviceWorker.addEventListener('controllerchange', () => {
        if (reloaded) return
        reloaded = true
        location.reload()
      })
    } catch {
      /* không có service worker vẫn chơi được (khi có mạng) */
    }
  })
}

/** Báo có bản mới; chỉ cập nhật khi người chơi bấm, và không cho bấm khi đang chơi game hay đang gửi thao tác. */
export function UpdatePrompt() {
  const [has, setHas] = useState(!!waiting)
  const route = useRoute()
  const { busy, pending } = useGame()
  useEffect(() => {
    const f = () => setHas(true)
    subs.add(f)
    return () => {
      subs.delete(f)
    }
  }, [])
  if (!has || route.path[0] === 'game') return null
  const unsafe = busy || !!pending
  return (
    <div className="toasts" style={{ top: 'auto', bottom: 'calc(96px + var(--safe-b))' }}>
      <div className="toast" style={{ display: 'flex', gap: 10, alignItems: 'center', background: '#3e3550' }}>
        <span>Có bản Cozii! mới.</span>
        <button className="btn small" disabled={unsafe} onClick={() => waiting?.postMessage('SKIP_WAITING')}>Cập nhật</button>
        <button className="btn small ghost" style={{ color: '#fff' }} onClick={() => setHas(false)}>Để sau</button>
      </div>
    </div>
  )
}
