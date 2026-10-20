// Service worker của Cozii! (sinh lúc build bởi vite.config.ts).
// Bản mới KHÔNG tự kích hoạt: chờ người chơi bấm "Cập nhật" ở thời điểm an toàn (không giữa ván game / giao dịch).
const VERSION = '__VERSION__'
const CACHE = 'cozii-' + VERSION
const PRECACHE = __PRECACHE__

self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(c => c.addAll(PRECACHE)))
})

self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    for (const k of await caches.keys()) if (k.startsWith('cozii-') && k !== CACHE) await caches.delete(k)
    await self.clients.claim()
  })())
})

self.addEventListener('message', event => {
  if (event.data === 'SKIP_WAITING') self.skipWaiting()
})

self.addEventListener('fetch', event => {
  const req = event.request
  if (req.method !== 'GET') return
  const url = new URL(req.url)
  // Không cache dữ liệu máy chủ (Supabase) hay tài nguyên khác nguồn.
  if (url.origin !== self.location.origin) return
  if (req.mode === 'navigate') {
    event.respondWith((async () => {
      try {
        const res = await fetch(req)
        return res
      } catch {
        const cached = await caches.match('/index.html')
        return cached || new Response('Ngoại tuyến', { status: 503 })
      }
    })())
    return
  }
  event.respondWith((async () => {
    const hit = await caches.match(req)
    if (hit) return hit
    const res = await fetch(req)
    if (res.ok && (url.pathname.startsWith('/assets/') || url.pathname.startsWith('/icons/'))) {
      const c = await caches.open(CACHE)
      c.put(req, res.clone())
    }
    return res
  })())
})
