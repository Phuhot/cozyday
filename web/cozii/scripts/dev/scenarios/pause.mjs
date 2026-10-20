// Kiểm tra: chuyển nền thì tự tạm dừng (Giỏ Quà đứng yên thời gian), chơi lại nhiều lần không chồng vòng lặp.
import onboard from './onboard.mjs'
export default async (ctx) => {
  const { page, shot } = ctx
  await onboard({ ...ctx, shot: async () => {} })
  const remaining = async () => Number((await page.locator('.hud').first().innerText()).match(/Còn\s*(\d+)/)?.[1] ?? NaN)
  await page.evaluate(() => { location.hash = '#/game/giftBasket/normal' })
  await page.waitForTimeout(800)
  await page.getByText('Bắt đầu').first().evaluate(el => el.click())
  await page.waitForFunction(() => /Còn\s*5\d/.test(document.querySelector('.hud')?.textContent ?? '') && !document.querySelector('.count-big'), null, { timeout: 15000 })
  await page.evaluate(() => { Object.defineProperty(document, 'hidden', { configurable: true, get: () => true }); document.dispatchEvent(new Event('visibilitychange')) })
  await page.waitForTimeout(300)
  const paused = await page.getByRole('heading', { name: 'Tạm dừng' }).count()
  const t1 = await remaining()
  await page.waitForTimeout(3000)
  const t2 = await remaining()
  await shot('paused')
  console.log('PAUSE overlay:', paused, '| còn giây trước/sau 3 s ẩn:', t1, t2)
  if (!paused || t1 !== t2) throw new Error('không tự tạm dừng')
  // tiếp tục rồi đo tốc độ đồng hồ sau 3 lần chơi lại
  await page.evaluate(() => { Object.defineProperty(document, 'hidden', { configurable: true, get: () => false }) })
  for (let i = 0; i < 3; i++) {
    await page.evaluate(() => { location.hash = '#/place/playground' })
    await page.waitForTimeout(400)
    await page.evaluate(() => { location.hash = '#/game/giftBasket/normal' })
    await page.waitForTimeout(600)
    await page.getByText('Bắt đầu').first().evaluate(el => el.click())
    await page.waitForTimeout(500)
  }
  await page.waitForFunction(() => /Còn\s*5\d/.test(document.querySelector('.hud')?.textContent ?? '') && !document.querySelector('.count-big'), null, { timeout: 15000 })
  const a = await remaining()
  await page.waitForTimeout(5000)
  const b = await remaining()
  console.log('sau 3 lần chơi lại, 5 s thật trôi:', a - b, 'giây trong game')
  if (a - b > 6 || a - b < 4) throw new Error('đồng hồ game chạy sai tốc độ (vòng lặp bị chồng?)')
}
