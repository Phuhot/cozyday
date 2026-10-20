// Xuất icon PWA từ hình vẽ bằng code (vịt con đội mây — cùng ý tưởng icon CozyDay). Cần `npm run dev` ở cổng 5199.
import { chromium } from 'playwright-core'
import { mkdirSync } from 'node:fs'
mkdirSync('public/icons', { recursive: true })
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' })
const page = await browser.newPage({ viewport: { width: 800, height: 800 } })
for (const [name, size, mask] of [['icon-192', 192, false], ['icon-512', 512, false], ['icon-maskable-512', 512, true], ['apple-touch-icon', 180, false]]) {
  await page.goto(`http://localhost:5199/gallery.html?m=icon&size=${size}${mask ? '&maskable=1' : ''}`)
  await page.waitForTimeout(500)
  await page.locator('#icon').screenshot({ path: `public/icons/${name}.png` })
}
await browser.close()
