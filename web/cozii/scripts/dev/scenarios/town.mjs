import onboard from './onboard.mjs'
export default async (ctx) => {
  const { page, shot } = ctx
  await onboard(ctx)
  await page.evaluate(() => { location.hash = '#/town' })
  await page.waitForTimeout(900)
  await shot('town')
  await page.evaluate(() => window.scrollTo(0, 900))
  await page.waitForTimeout(300)
  await shot('town-bottom')
}
