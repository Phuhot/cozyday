export default async ({ page, base }) => {
  await page.goto(base + '/')
  await page.waitForTimeout(1500)
  await page.getByText('Bỏ qua').click()
  await page.waitForTimeout(800)
  const loc = page.getByRole('button', { name: 'Capybara', exact: true })
  console.log(JSON.stringify(await loc.boundingBox()))
  await loc.screenshot({ path: '/tmp/claude-0/-home-user-cozyday/0b742326-a63d-5499-a78c-b3b6428c2b9c/scratchpad/dbg/el.png' })
}
