// Chụp ảnh một URL bằng Chromium có sẵn (dev). node scripts/dev/shot.mjs <url> <out.png> [width] [height]
import { chromium } from 'playwright-core'
const [url, out, w = '900', h = '1200'] = process.argv.slice(2)
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' })
const page = await browser.newPage({ viewport: { width: +w, height: +h }, deviceScaleFactor: 1 })
const errors = []
page.on('pageerror', e => errors.push(String(e)))
page.on('console', m => { if (m.type() === 'error') errors.push(m.text()) })
await page.goto(url, { waitUntil: 'networkidle' })
await page.waitForTimeout(800)
await page.screenshot({ path: out, fullPage: true })
if (errors.length) console.log('ERRORS:\n' + errors.join('\n'))
await browser.close()
