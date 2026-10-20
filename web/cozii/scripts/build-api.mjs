// Đóng gói server/api.ts (cùng luật chơi trong src/) thành một file api/cozii.js cho Vercel Serverless Functions.
// File sinh ra được commit vào repo để Vercel nhận diện hàm mà không cần cấu hình thêm; test kiểm tra nó luôn khớp nguồn.
import { build } from 'esbuild'
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs'
import { createHash } from 'node:crypto'

const out = 'api/cozii.js'
mkdirSync('api', { recursive: true })
const r = await build({
  entryPoints: ['server/api.ts'],
  bundle: true,
  platform: 'node',
  format: 'esm',
  target: 'node20',
  external: ['pg'],
  write: false,
  legalComments: 'none',
  logLevel: 'warning',
})
const code = r.outputFiles[0].text
const hash = createHash('sha256').update(code).digest('hex').slice(0, 16)
const banner = `// SINH TỰ ĐỘNG từ server/api.ts bằng \`npm run build:api\` — đừng sửa tay. sha:${hash}\n`
let prev = ''
try { prev = readFileSync(out, 'utf8') } catch { /* chưa có */ }
if (process.argv.includes('--check')) {
  if (prev !== banner + code) {
    console.error(`build-api: ${out} đã cũ so với server/ — chạy \`npm run build:api\` rồi commit.`)
    process.exit(1)
  }
  console.log('build-api: khớp nguồn')
} else if (prev !== banner + code) {
  writeFileSync(out, banner + code)
  console.log(`build-api: đã ghi ${out} (${(code.length / 1024).toFixed(0)} KB)`)
} else console.log('build-api: không đổi')
