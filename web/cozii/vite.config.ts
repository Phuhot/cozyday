import { defineConfig, type Plugin } from 'vite'
import react from '@vitejs/plugin-react'
import { readFileSync } from 'node:fs'

/** Sinh service worker có danh sách tài nguyên cần lưu để chơi ngoại tuyến. */
function serviceWorker(): Plugin {
  return {
    name: 'cozii-sw',
    apply: 'build',
    generateBundle(_opts, bundle) {
      const files = Object.keys(bundle).filter(f => !f.endsWith('.map') && f !== 'sw.js' && !f.includes('cyrillic'))
      const precache = ['/', '/index.html', '/manifest.webmanifest', '/icons/icon-192.png', '/icons/icon-512.png', ...files.filter(f => f !== 'index.html').map(f => '/' + f)]
      const version = Date.now().toString(36)
      const src = readFileSync(new URL('./src/sw-template.js', import.meta.url), 'utf8')
        .replace('__VERSION__', version)
        .replace('__PRECACHE__', JSON.stringify([...new Set(precache)]))
      this.emitFile({ type: 'asset', fileName: 'sw.js', source: src })
      this.emitFile({ type: 'asset', fileName: 'version.json', source: JSON.stringify({ version }) })
    },
  }
}

/**
 * Chỉ khi chạy `npm run dev` với COZII_DEV_API=1: phục vụ /api/cozii ngay trong máy chủ dev bằng chính server/api.ts
 * (cần DATABASE_URL trỏ tới Postgres cục bộ). Bản build không chứa phần này; trên Vercel hàm nằm ở api/cozii.js.
 */
function devApi(): Plugin {
  return {
    name: 'cozii-dev-api',
    apply: 'serve',
    configureServer(server) {
      if (process.env.COZII_DEV_API !== '1') return
      server.middlewares.use('/api/cozii', async (req, res) => {
        const mod = await server.ssrLoadModule('/server/api.ts')
        await mod.default(req, res)
      })
    },
  }
}

export default defineConfig({
  plugins: [react(), serviceWorker(), devApi()],
  build: { target: 'es2020', sourcemap: false, chunkSizeWarningLimit: 900 },
  server: { host: true },
})
