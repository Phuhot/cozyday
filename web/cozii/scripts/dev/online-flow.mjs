// Chạy thử chế độ online với HAI người chơi dev (cần `npm run dev:online` ở cổng 5199).
// node scripts/dev/online-flow.mjs <thư-mục-ảnh>
import { chromium } from 'playwright-core'
import { mkdirSync } from 'node:fs'
import onboard from './scenarios/onboard.mjs'
const outDir = process.argv[2] ?? '/tmp/cozii-online'
mkdirSync(outDir, { recursive: true })
const base = process.env.BASE ?? 'http://localhost:5199'
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' })
const errors = []
let n = 0
async function player(tag) {
  const ctx = await browser.newContext({ viewport: { width: 428, height: 926 }, deviceScaleFactor: 2, hasTouch: true, isMobile: true })
  const page = await ctx.newPage()
  page.on('pageerror', e => errors.push(`${tag} pageerror: ${e.message}`))
  page.on('console', m => { if (m.type() === 'error') errors.push(`${tag} console: ${m.text()}`) })
  page.on('dialog', d => d.accept())
  const shot = async name => { await page.waitForTimeout(500); await page.screenshot({ path: `${outDir}/${String(++n).padStart(2, '0')}-${tag}-${name}.png` }) }
  const nav = async h => { await page.evaluate(x => { location.hash = x }, h); await page.waitForTimeout(900) }
  return { page, shot, nav, text: t => page.getByText(t, { exact: false }).first() }
}
try {
  const A = await player('A')
  const B = await player('B')
  await onboard({ ...A, base, shot: async () => {} })
  await onboard({ ...B, base, shot: async () => {} })
  // A: gieo hạt để B tưới giúp
  await A.nav('#/farm')
  await A.page.locator('.plot').first().evaluate(el => el.click())
  await A.page.waitForTimeout(400)
  await A.page.locator('.sheet .tile').filter({ hasText: 'Hạt mầm hướng dẫn' }).evaluate(el => el.click()).catch(() => {})
  await A.page.waitForTimeout(500)
  await A.page.keyboard.press('Escape')
  // gieo thêm một cây thường (lâu hơn) nếu có
  await A.page.locator('.plot').nth(1).evaluate(el => el.click())
  await A.page.waitForTimeout(400)
  await A.shot('farm-seeds')
  await A.page.locator('.sheet .tile').nth(1).evaluate(el => el.click()).catch(() => {})
  await A.page.waitForTimeout(600)
  await A.shot('farm')
  // A: để chế độ bạn bè và đăng nhà
  await A.nav('#/friends')
  await A.page.getByText('Chỉ bạn bè', { exact: false }).first().evaluate(el => el.click()).catch(() => {})
  await A.page.locator('input[name=vis]').nth(1).check({ force: true })
  await A.page.waitForTimeout(600)
  await A.page.getByRole('button', { name: 'Đăng nhà' }).evaluate(el => el.click())
  await A.page.waitForTimeout(900)
  await A.shot('friends-published')
  const codeA = (await A.page.locator('.bold[style*="letter-spacing"]').first().textContent())?.trim()
  console.log('friend code A =', codeA)
  // B: gửi lời mời
  await B.nav('#/friends')
  await B.page.getByLabel('Mã bạn bè').fill(codeA)
  await B.page.getByRole('button', { name: 'Mời' }).evaluate(el => el.click())
  await B.page.waitForTimeout(900)
  await B.shot('friends-sent')
  // A: đồng ý
  await A.nav('#/town'); await A.nav('#/friends')
  await A.page.waitForTimeout(600)
  await A.shot('friends-request')
  await A.page.getByRole('button', { name: 'Đồng ý' }).evaluate(el => el.click())
  await A.page.waitForTimeout(900)
  await A.shot('friends-accepted')
  // B: thăm A, khen, tưới giúp
  await B.nav('#/town'); await B.nav('#/friends')
  await B.shot('friends-list')
  await B.page.getByRole('button', { name: 'Thăm' }).first().evaluate(el => el.click())
  await B.page.waitForTimeout(1500)
  await B.shot('visit')
  await B.page.locator('.pill').filter({ hasText: /./ }).nth(0).evaluate(el => el.click()).catch(() => {})
  const stickers = B.page.locator('.row.wrap .pill')
  if (await stickers.count()) await stickers.first().evaluate(el => el.click())
  await B.page.waitForTimeout(800)
  await B.shot('visit-compliment')
  const help = B.page.locator('button.plot:not([disabled])')
  console.log('helpable plots:', await help.count())
  if (await help.count()) { await help.first().evaluate(el => el.click()); await B.page.waitForTimeout(1000) }
  await B.page.mouse.wheel(0, 600)
  await B.shot('visit-helped')
  // A: hộp thư
  await A.nav('#/home')
  await A.page.getByRole('button', { name: 'Hộp thư' }).evaluate(el => el.click())
  await A.page.waitForTimeout(900)
  await A.shot('mail')
  // B: Nhảy Mây xếp hạng
  await B.nav('#/game/cloudJump/weekly')
  await B.shot('cloudjump-ready')
  await B.text('Bắt đầu').evaluate(el => el.click())
  // Lái thử: đưa bạn nhỏ qua lại để leo vài tầng mây, rồi dạt hẳn về mép để rơi.
  const box = await B.page.locator('canvas').first().boundingBox()
  const xs = [0.3, 0.7, 0.45, 0.2, 0.8, 0.55, 0.35, 0.65, 0.5, 0.25, 0.75, 0.4, 0.6]
  for (let i = 0; i < 26; i++) {
    await B.page.mouse.move(box.x + box.width * xs[i % xs.length], box.y + box.height * 0.6)
    await B.page.mouse.down(); await B.page.waitForTimeout(450); await B.page.mouse.up()
    if (i === 8) await B.shot('cloudjump-play')
  }
  await B.page.mouse.move(box.x + 2, box.y + box.height * 0.6)
  await B.page.mouse.down()
  await B.page.waitForSelector('text=Xong lượt!', { timeout: 60000 }).catch(() => {})
  await B.page.mouse.up()
  await B.page.waitForTimeout(1500)
  await B.shot('cloudjump-result')
  await B.nav('#/place/playground')
  await B.shot('playground-online')
  await B.page.getByText('Bảng xếp hạng Nhảy Mây').scrollIntoViewIfNeeded()
  await B.shot('leaderboard')
} catch (e) {
  errors.push('step failed: ' + e.message)
}
console.log(errors.length ? 'ERRORS:\n' + errors.join('\n') : 'OK, no errors')
await browser.close()
