import { CloudJump, platformX, CJ } from '../src/games/cloudJump'

/** "Người chơi máy" Nhảy Mây: nhắm tới bệ cao hơn gần nhất. Dùng để kiểm tra đường đi khả thi và tạo nhật ký thật. */
export function playCloudJump(seed: number, maxTicks = 60 * 60 * 3, skill = 1): CloudJump {
  const e = new CloudJump(seed)
  while (!e.over && e.time < maxTicks + 60 * 60) {
    if (e.time >= maxTicks) {
      // hết giờ chơi: lái ra mép để rơi, kết thúc lượt
      e.setTarget(e.petX < CJ.W / 2 ? 1 : 0)
      e.tick()
      continue
    }
    const above = e.platforms
      .filter(p => p.y > e.bestY && p.id !== 0)
      .sort((a, b) => a.y - b.y)[0]
    const cur = e.platforms.filter(p => p.y <= e.petY + 1000).sort((a, b) => b.y - a.y)[0]
    let tx = e.petX
    if (above && (e.velY > 0 || e.petY > above.y)) tx = platformX(above, e.time)
    else if (cur) tx = platformX(cur, e.time)
    // né chướng ngại gần
    for (const h of e.hazards) {
      if (Math.abs(h.y - (e.petY + CJ.BODY / 2)) < 20000 && Math.abs(h.x - e.petX) < 14000) tx += h.x > e.petX ? -15000 : 15000
    }
    if (skill < 1 && e.time % 997 === 0) tx = (e.time * 7919) % CJ.W
    e.setTarget(Math.max(0, Math.min(1, tx / CJ.W)))
    e.tick()
  }
  return e
}
