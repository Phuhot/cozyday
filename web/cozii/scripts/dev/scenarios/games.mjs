// Mở từng minigame, bấm Bắt đầu, thao tác vài lần và chụp ảnh lúc đang chơi.
import onboard from './onboard.mjs'
export default async (ctx) => {
  const { page, shot } = ctx
  await onboard({ ...ctx, shot: async () => {} })
  const games = [['memory/easy', 'memory'], ['giftBasket/normal', 'basket'], ['rhythm/morning', 'rhythm'], ['picnic/medium', 'picnic'], ['runner/normal', 'runner'], ['cloudJump/normal', 'cloudjump']]
  for (const [route, name] of games) {
    await page.evaluate(x => { location.hash = x }, '#/game/' + route)
    await page.waitForTimeout(900)
    await shot(name + '-ready')
    await page.getByText('Bắt đầu').first().evaluate(el => el.click())
    await page.waitForTimeout(1200)
    const box = await page.locator('canvas').first().boundingBox()
    if (name === 'memory') {
      const cards = page.locator('.memory-card, [data-card]')
      if (await cards.count()) { await cards.nth(0).click(); await cards.nth(1).click() } else { await page.mouse.click(box.x + box.width * 0.2, box.y + box.height * 0.3); await page.mouse.click(box.x + box.width * 0.5, box.y + box.height * 0.3) }
    } else if (box) {
      for (let i = 0; i < 6; i++) { await page.mouse.click(box.x + box.width * (0.2 + 0.12 * i), box.y + box.height * 0.7); await page.waitForTimeout(250) }
    }
    await page.waitForTimeout(1500)
    await shot(name + '-play')
    await page.keyboard.press('Escape')
    await page.evaluate(() => { location.hash = '#/place/playground' })
    await page.waitForTimeout(700)
  }
}
