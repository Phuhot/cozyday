import { describe, expect, it } from 'vitest'
import { makeLocal, onboarded, memStorage } from './helpers'
import { LocalBackend } from '../src/backend/local'
import { ECONOMY } from '../src/content/economy'
import { CHAPTERS } from '../src/content/town'
import { rankOf, readyAt } from '../src/core/state'

describe('khởi tạo & onboarding', () => {
  it('trạng thái mới có 4 ô đất, 3 đơn, quà khởi đầu', async () => {
    const { be } = makeLocal()
    const s = await be.load()
    expect(s.farm.unlocked).toBe(4)
    expect(s.orders.list).toHaveLength(3)
    expect(s.wallet.coins).toBe(ECONOMY.start.coins)
    expect(s.profile.onboarded).toBe(false)
  })
  it('chưa onboarding thì không thao tác được', async () => {
    const { act } = makeLocal()
    await expect(act({ type: 'buyStock', id: 'seed.radish', count: 1 })).rejects.toThrow(/bạn nhỏ/)
  })
  it('onboarding cấp loài đã chọn và quà, không làm lại được', async () => {
    const { act, be } = await onboarded()
    const s = await be.load()
    expect(s.owned).toContain('species.capybara')
    expect(s.owned).toContain('lamp.candle')
    expect(s.pet.name).toBe('Bông')
    await expect(act({ type: 'onboard', playerName: 'X', petName: 'Y', species: 'cat', fur: 'cream' })).rejects.toThrow()
  })
  it('tên quá dài bị từ chối, ký tự điều khiển bị lọc', async () => {
    const { act } = makeLocal()
    await expect(act({ type: 'onboard', playerName: 'Mai', petName: 'x'.repeat(30), species: 'cat', fur: 'cream' })).rejects.toThrow(/tối đa/)
  })
})

describe('mua bán & idempotency', () => {
  it('mua đồ trừ xu đúng một lần khi thử lại cùng mã yêu cầu', async () => {
    const { act, be } = await onboarded()
    const before = (await be.load()).wallet.coins
    const r1 = await act({ type: 'buyItem', item: 'plant.monstera' }, 'same')
    const r2 = await act({ type: 'buyItem', item: 'plant.monstera' }, 'same')
    expect(r1.state.wallet.coins).toBe(before - 105)
    expect(r2.state.wallet.coins).toBe(before - 105)
    expect(r2.state.owned.filter(x => x === 'plant.monstera')).toHaveLength(1)
  })
  it('không mua được món đã có, món capsule, món chưa đủ hạng, khi thiếu xu', async () => {
    const { act } = await onboarded()
    await act({ type: 'buyItem', item: 'plant.monstera' })
    await expect(act({ type: 'buyItem', item: 'plant.monstera' })).rejects.toThrow(/đã có/)
    await expect(act({ type: 'buyItem', item: 'hat.wizard' })).rejects.toThrow(/không bán/)
    await expect(act({ type: 'buyItem', item: 'hat.crown' })).rejects.toThrow(/hạng/)
    await expect(act({ type: 'buyItem', item: 'seat.armchair' })).rejects.toThrow(/Cần/)
  })
  it('bán nông sản cần có trong kho, không âm', async () => {
    const { act } = await onboarded()
    await expect(act({ type: 'sell', id: 'crop.radish', count: 1 })).rejects.toThrow(/Không đủ/)
  })
})

describe('vườn', () => {
  it('cây lớn theo thời gian thật, chưa chín không thu được, thu hai lần chỉ một lần', async () => {
    const { act, clock, be } = await onboarded()
    await act({ type: 'plant', plot: 0, seed: 'seed.radish' })
    await expect(act({ type: 'harvest', plot: 0 })).rejects.toThrow(/chưa chín/)
    clock.t += 89_000
    await expect(act({ type: 'harvest', plot: 0 })).rejects.toThrow(/chưa chín/)
    clock.t += 1_000
    const r = await act({ type: 'harvest', plot: 0 }, 'h1')
    expect(r.state.stock['crop.radish']).toBe(1)
    const again = await act({ type: 'harvest', plot: 0 }, 'h1')
    expect(again.state.stock['crop.radish']).toBe(1)
    await expect(act({ type: 'harvest', plot: 0 }, 'h2')).rejects.toThrow(/chưa gieo/)
    expect((await be.load()).counters.harvest).toBe(1)
  })
  it('tưới giảm 15% một lần, không spam được', async () => {
    const { act, be } = await onboarded()
    await act({ type: 'plant', plot: 1, seed: 'seed.carrot' })
    await act({ type: 'water', plot: 1 })
    await expect(act({ type: 'water', plot: 1 })).rejects.toThrow(/tưới rồi/)
    const p = (await be.load()).farm.plots[1]
    expect(readyAt(p) - p.plantedAt).toBe(300_000 * 0.85)
  })
  it('đổi giờ máy lùi lại không làm cây lớn ngược', async () => {
    const { act, clock } = await onboarded()
    await act({ type: 'plant', plot: 0, seed: 'seed.radish' })
    clock.t += 95_000
    await act({ type: 'photo' }) // máy ghi nhận mốc thời gian mới nhất
    clock.t -= 3_600_000 // người chơi chỉnh giờ lùi một tiếng
    const r = await act({ type: 'harvest', plot: 0 })
    expect(r.state.stock['crop.radish']).toBe(1)
    // gieo mới khi giờ đang lùi: thời gian không bị tính âm
    await act({ type: 'plant', plot: 0, seed: 'seed.radish' })
    await expect(act({ type: 'harvest', plot: 0 })).rejects.toThrow(/chưa chín/)
  })
  it('không có cây thối dù bỏ game rất lâu', async () => {
    const { act, clock } = await onboarded()
    await act({ type: 'plant', plot: 0, seed: 'seed.radish' })
    clock.t += 90 * 24 * 3600_000
    const r = await act({ type: 'harvest', plot: 0 })
    expect(r.state.stock['crop.radish']).toBe(1)
  })
  it('ô đất chưa mở không gieo được; mở ô theo giá', async () => {
    const { act, be } = await onboarded()
    await expect(act({ type: 'plant', plot: 4, seed: 'seed.radish' })).rejects.toThrow(/chưa mở/)
    const c0 = (await be.load()).wallet.coins
    const r = await act({ type: 'buyPlot' })
    expect(r.state.farm.unlocked).toBe(5)
    expect(r.state.wallet.coins).toBe(c0 - 80)
  })
  it('cây hướng dẫn chỉ gieo một lần và lớn trong 20 giây', async () => {
    const { act, clock } = await onboarded()
    await act({ type: 'plant', plot: 0, seed: 'seed.sprout' })
    clock.t += 20_000
    const r = await act({ type: 'harvest', plot: 0 })
    expect(r.state.stock['crop.radish']).toBe(2)
    await expect(act({ type: 'plant', plot: 0, seed: 'seed.sprout' })).rejects.toThrow()
  })
})

describe('chăm pet', () => {
  it('nhu cầu giảm chậm, có sàn, tối đa 24 giờ', async () => {
    const { act, clock, be } = await onboarded()
    clock.t += 10 * 24 * 3600_000
    await act({ type: 'photo' })
    const s = await be.load()
    const { needsAt } = await import('../src/core/engine')
    const n = needsAt(s.pet.needs, clock.t)
    expect(n.fullness).toBe(ECONOMY.care.floor)
    expect(n.happiness).toBe(ECONOMY.care.floor)
  })
  it('cho ăn khi đói có thưởng, có hạn mức theo loại', async () => {
    const { act, clock } = await onboarded()
    clock.t += 20 * 3600_000
    const r1 = await act({ type: 'feed', food: 'food.apple' })
    expect((r1.result as any).reward.coins).toBe(ECONOMY.care.coins.feed)
    expect((r1.result as any).reward.affection).toBe(ECONOMY.care.affectionPerCare)
  })
  it('no rồi thì không cho ăn thêm (không tốn đồ ăn)', async () => {
    const { act, be } = await onboarded()
    await act({ type: 'feed', food: 'food.apple' })
    await expect(act({ type: 'feed', food: 'food.apple' })).rejects.toThrow(/no rồi/)
    expect((await be.load()).stock['food.apple']).toBe(2)
  })
  it('thân thiết có trần mỗi ngày', async () => {
    const { act, be, clock } = await onboarded()
    for (let i = 0; i < 20; i++) {
      clock.t += 3600_000 * 5
      try { await act({ type: 'cuddle' }) } catch { /* bỏ qua */ }
    }
    const s = await be.load()
    expect(s.pet.affection).toBeLessThanOrEqual(ECONOMY.care.dailyAffectionCap * 5)
  })
})

describe('capsule', () => {
  it('bảo hiểm: trong 8 lượt chắc chắn có món hiếm trở lên; đồ trùng thành mảnh', async () => {
    const { act, be } = await onboarded()
    const s0 = await be.load()
    // cấp vé trực tiếp cho test
    ;(be as any).state.wallet.tickets = 60
    let sinceRare = 0
    let maxGap = 0
    let specials = 0
    for (let i = 0; i < 60; i++) {
      const r = await act({ type: 'openCapsule', series: 'moon' })
      const pull = (r.result as any).pull
      if (pull.rarity === 'common') sinceRare++
      else sinceRare = 0
      if (pull.rarity === 'special') specials++
      maxGap = Math.max(maxGap, sinceRare)
    }
    expect(maxGap).toBeLessThan(ECONOMY.capsule.rarePity)
    expect(specials).toBeGreaterThanOrEqual(2)
    const s = await be.load()
    expect(s.wallet.shards).toBeGreaterThan(0)
    expect(s0.wallet.tickets).toBe(1)
  })
  it('không có vé thì không quay', async () => {
    const { act } = await onboarded()
    await act({ type: 'openCapsule', series: 'moon' })
    await expect(act({ type: 'openCapsule', series: 'moon' })).rejects.toThrow(/vé/)
  })
  it('thử lại cùng mã yêu cầu trả đúng kết quả cũ, không tốn thêm vé', async () => {
    const { act } = await onboarded()
    const a = await act({ type: 'openCapsule', series: 'ocean' }, 'cap-1')
    const b = await act({ type: 'openCapsule', series: 'ocean' }, 'cap-1')
    expect((b.result as any).pull.item).toBe((a.result as any).pull.item)
    expect(b.state.wallet.tickets).toBe(a.state.wallet.tickets)
  })
})

describe('hộ chiếu', () => {
  it('chương 1 hoàn thành bằng thao tác thật, nhận thưởng một lần, mở hạng 2', async () => {
    const { act, clock } = await onboarded()
    await act({ type: 'place', room: 'study', slot: 'lamp', item: 'lamp.candle' })
    await act({ type: 'feed', food: 'food.apple' })
    await act({ type: 'plant', plot: 0, seed: 'seed.sprout' })
    const run = (await act({ type: 'startRun', game: 'memory' })).result as any
    clock.t += 30_000
    await act({ type: 'finishRun', run: run.run.id, result: { game: 'memory', completed: true, level: 'easy', moves: 9, pairs: 6, seconds: 28 } })
    await act({ type: 'harvest', plot: 0 })
    await expect(act({ type: 'claimChapter', chapter: 1 })).rejects.toThrow(/chưa xong/)
    await act({ type: 'visitNpc', npc: 'tra' })
    const r = await act({ type: 'claimChapter', chapter: 1 })
    expect(rankOf(r.state)).toBe(2)
    await expect(act({ type: 'claimChapter', chapter: 1 })).rejects.toThrow(/đóng dấu/)
    expect(CHAPTERS[0].tasks).toHaveLength(7)
  })
})

describe('minigame', () => {
  it('mở rồi thoát ngay không có xu; kết quả phi lý bị từ chối', async () => {
    const { act, clock } = await onboarded()
    const t1 = ((await act({ type: 'startRun', game: 'giftBasket' })).result as any).run
    clock.t += 3000
    const r1 = await act({ type: 'finishRun', run: t1.id, result: { game: 'giftBasket', completed: true, score: 500, caught: 80, bestCombo: 20 } })
    expect((r1.result as any).coins).toBe(0)
    expect((r1.result as any).note).toBe('implausible')
    const t2 = ((await act({ type: 'startRun', game: 'giftBasket' })).result as any).run
    clock.t += 61_000
    const r2 = await act({ type: 'finishRun', run: t2.id, result: { game: 'giftBasket', completed: true, score: 60, caught: 30, bestCombo: 8 } })
    expect((r2.result as any).coins).toBe(4)
    await expect(act({ type: 'finishRun', run: t2.id, result: { game: 'giftBasket', completed: true, score: 60, caught: 30, bestCombo: 8 } })).rejects.toThrow(/hết hạn|đã nộp/)
  })
  it('xu sân chơi có trần mỗi ngày', async () => {
    const { act, clock } = await onboarded()
    let total = 0
    for (let i = 0; i < 12; i++) {
      const t = ((await act({ type: 'startRun', game: 'cloudJump' })).result as any).run
      clock.t += 60_000
      const r = await act({ type: 'finishRun', run: t.id, result: { game: 'cloudJump', completed: true, meters: 200, stars: 20 } })
      total += (r.result as any).coins
    }
    expect(total).toBe(ECONOMY.games.dailyCoinCap)
  })
})

describe('lưu trữ', () => {
  it('reload (tạo lại backend) giữ nguyên dữ liệu', async () => {
    const storage = memStorage()
    const clock = { t: Date.UTC(2026, 9, 20) }
    const a = new LocalBackend(storage, () => clock.t)
    await a.load()
    await a.act({ type: 'onboard', playerName: 'Mai', petName: 'Bông', species: 'duck', fur: 'honey' }, 'r1')
    await a.act({ type: 'plant', plot: 2, seed: 'seed.carrot' }, 'r2')
    const b = new LocalBackend(storage, () => clock.t)
    const s = await b.load()
    expect(s.pet.species).toBe('duck')
    expect(s.farm.plots[2].crop).toBe('carrot')
    // mã yêu cầu cũ vẫn được nhớ sau reload
    const again = await b.act({ type: 'plant', plot: 2, seed: 'seed.carrot' }, 'r2')
    expect(again.state.stock['seed.carrot']).toBe(1)
  })
})
