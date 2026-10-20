// Chạy thử luồng người chơi trong Chromium (dev) và chụp ảnh. node scripts/dev/flow.mjs <tên-kịch-bản> <thư-mục-ảnh>
import { chromium } from 'playwright-core'
import { mkdirSync } from 'node:fs'
const [scenario = 'onboard', outDir = '/tmp/cozii-shots', width = '428', height = '926'] = process.argv.slice(2)
mkdirSync(outDir, { recursive: true })
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' })
const ctx = await browser.newContext({ viewport: { width: +width, height: +height }, deviceScaleFactor: 2, hasTouch: true, isMobile: +width < 700 })
const page = await ctx.newPage()
const errors = []
page.on('pageerror', e => errors.push('pageerror: ' + e.message))
page.on('console', m => { if (m.type() === 'error') errors.push('console: ' + m.text()) })
const base = process.env.BASE ?? 'http://localhost:5199'
let n = 0
const shot = async name => { await page.waitForTimeout(500); await page.screenshot({ path: `${outDir}/${String(++n).padStart(2, '0')}-${name}.png` }) }
const click = async (sel, opts) => { await page.locator(sel).first().click(opts) }
const text = t => page.getByText(t, { exact: false }).first()
const steps = (await import(`./scenarios/${scenario}.mjs`)).default
try {
  await steps({ page, shot, click, text, base })
} catch (e) {
  errors.push('step failed: ' + e.message)
  await page.screenshot({ path: `${outDir}/zz-fail.png` })
}
console.log(errors.length ? 'ERRORS:\n' + errors.join('\n') : 'OK, no errors')
await browser.close()
