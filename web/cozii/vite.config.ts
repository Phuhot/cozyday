import { defineConfig, type Plugin } from 'vite'
import react from '@vitejs/plugin-react'
import { readFileSync } from 'node:fs'

/** Sinh service worker có danh sách tài nguyên cần lưu để chơi ngoại tuyến. */
function serviceWorker(): Plugin {
  return {
    name: 'cozii-sw',
    apply: 'build',
    generateBundle(_opts, bundle) {
      const files = Object.keys(bundle).filter(f => !f.endsWith('.map') && f !== 'sw.js')
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

export default defineConfig({
  plugins: [react(), serviceWorker()],
  build: { target: 'es2020', sourcemap: false, chunkSizeWarningLimit: 900 },
  server: { host: true },
})
