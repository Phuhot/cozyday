// Mô phỏng kinh tế Cozii! bằng CHÍNH luật chơi trong src/core/engine.ts (không phải công thức ước lượng).
// Bốn kiểu người chơi chơi 30 ngày; in bảng Markdown để dán vào docs/ECONOMY_VI.md.
// Chạy: npm run sim:economy
import * as engine from '../src/core/engine'
import { apply, newState, GameError, type Action, type Env } from '../src/core/engine'
import { rankOf, readyAt, affectionLevel, type GameState, type GameId } from '../src/core/state'
import { ECONOMY } from '../src/content/economy'
import { CROPS, RECIPES } from '../src/content/farm'
import { ITEMS, roomOfSlot, isThemeSlot, isPetSlot } from '../src/content/catalog'
import { SERIES } from '../src/content/capsule'
import { CHAPTERS, NPC_HOMES, STICKERS, dailyTasksFor } from '../src/content/town'
import { Rhythm, SONGS } from '../src/games/rhythm'
import type { RunResult } from '../src/core/games'
import { dayKey } from '../src/core/time'

type Source = 'farm' | 'orders' | 'games' | 'care' | 'daily' | 'passport' | 'social' | 'other'
const SOURCE: Partial<Record<Action['type'], Source>> = {
  sell: 'farm', completeOrder: 'orders', finishRun: 'games', feed: 'care', clean: 'care', cuddle: 'care',
  claimDaily: 'daily', claimChapter: 'passport', visitNpc: 'social', npcHelpWater: 'social', npcCompliment: 'social',
}

interface Persona {
  key: string
  name: string
  /** Giờ bắt đầu các phiên trong ngày (giờ Việt Nam), độ dài (phút) và số lượt minigame trong phiên. */
  sessions: { hour: number; minutes: number; runs: number }[]
  /** Trình độ minigame (0..1). */
  skill: number
  /** Có mua vé capsule bằng xu không. */
  buysTickets: boolean
}

const PERSONAS: Persona[] = [
  { key: 'p10', name: '10 phút/ngày', sessions: [{ hour: 20, minutes: 10, runs: 1 }], skill: 0.4, buysTickets: false },
  { key: 'p30', name: '30 phút/ngày', sessions: [{ hour: 8, minutes: 8, runs: 1 }, { hour: 13, minutes: 8, runs: 1 }, { hour: 21, minutes: 14, runs: 2 }], skill: 0.55, buysTickets: true },
  { key: 'gamer', name: 'Chơi game giỏi (45 phút)', sessions: [{ hour: 12, minutes: 15, runs: 4 }, { hour: 20, minutes: 30, runs: 8 }], skill: 0.95, buysTickets: true },
  { key: 'farmer', name: 'Mê làm vườn (6 lần ghé ngắn)', sessions: [7, 10, 13, 16, 19, 22].map((hour, i) => ({ hour, minutes: 4, runs: i === 3 ? 1 : 0 })), skill: 0.5, buysTickets: false },
]

const GAMES: GameId[] = ['cloudJump', 'giftBasket', 'memory', 'rhythm', 'runner', 'picnic']

function makeEnv(clock: { t: number }, seed: number): Env {
  let x = seed
  let n = 0
  return {
    get now() { return clock.t },
    rand: () => ((x = (x * 48271) % 2147483647) / 2147483647),
    uuid: () => `sim-${seed}-${++n}`,
  }
}

/** Kết quả một lượt chơi "hợp lý" theo trình độ, và số giây thật lượt đó mất. */
function playResult(game: GameId, skill: number, i: number): { r: RunResult; sec: number } {
  const jitter = 0.85 + ((i * 7919) % 30) / 100
  switch (game) {
    case 'cloudJump': {
      const meters = Math.round((40 + 260 * skill) * jitter)
      return { r: { game, completed: true, meters, stars: Math.floor(meters / 15) }, sec: Math.max(30, Math.round(meters / 3)) }
    }
    case 'giftBasket': return { r: { game, completed: true, score: Math.round((40 + 120 * skill) * jitter), caught: 40, bestCombo: 10 }, sec: 62 }
    case 'memory': {
      const level = skill > 0.7 ? 'medium' : 'easy'
      const pairs = level === 'medium' ? 8 : 6
      const sec = Math.round((level === 'medium' ? 90 : 60) * (1.3 - skill * 0.6))
      return { r: { game, completed: true, level, moves: Math.round(pairs * (2.2 - skill)), pairs, seconds: sec }, sec: sec + 2 }
    }
    case 'rhythm': {
      const song = SONGS[i % SONGS.length]
      const duration = new Rhythm(song).duration
      const total = song.notes.length
      const accuracy = Math.min(100, Math.round((45 + 50 * skill) * jitter))
      return { r: { game, completed: true, song: song.id, accuracy, hits: Math.round((total * accuracy) / 100), total, duration }, sec: duration + 1 }
    }
    case 'runner': {
      const meters = Math.round((150 + 900 * skill) * jitter)
      return { r: { game, completed: true, meters, berries: Math.floor(meters / 30) }, sec: Math.round(meters / 9) + 2 }
    }
    case 'picnic': {
      const sec = Math.round(120 - 80 * skill)
      return { r: { game, completed: true, puzzle: i, moves: 7, hints: skill > 0.6 ? 0 : 1, seconds: sec }, sec: sec + 2 }
    }
  }
}

interface Report {
  persona: Persona
  minutesPerDay: number
  earned: Record<Source, number>
  spent: Record<string, number>
  missing: string[]
  coinsAt: Record<number, number>
  rankDay: Record<number, number>
  itemsAt: Record<number, number>
  pulls: number
  ticketsBought: number
  plotsAt: Record<number, number>
  affectionLevel: number
  gameCapHitDays: number
}

function simulate(p: Persona, days = 30): Report {
  const start = Date.UTC(2026, 9, 20, 0, 0, 0) - 7 * 3600e3 // 00:00 giờ VN
  const clock = { t: start + 19 * 3600e3 }
  const env = makeEnv(clock, 12345 + p.key.length)
  const s: GameState = newState('sim-' + p.key, clock.t, env)
  const earned: Record<Source, number> = { farm: 0, orders: 0, games: 0, care: 0, daily: 0, passport: 0, social: 0, other: 0 }
  const spent: Record<string, number> = { seeds: 0, food: 0, plots: 0, shop: 0, tickets: 0 }
  const rep: Report = { persona: p, minutesPerDay: p.sessions.reduce((n, x) => n + x.minutes, 0), earned, spent, missing: [], coinsAt: {}, rankDay: {}, itemsAt: {}, pulls: 0, ticketsBought: 0, plotsAt: {}, affectionLevel: 1, gameCapHitDays: 0 }
  let runN = 0
  let capDay = ''

  const act = (a: Action): Record<string, unknown> | null => {
    const before = s.wallet.coins
    try {
      const r = apply(s, a, env) ?? {}
      const d = s.wallet.coins - before
      if (d > 0) earned[SOURCE[a.type] ?? 'other'] += d
      else if (d < 0) {
        const k = a.type === 'buyStock' ? (a.id.startsWith('seed.') ? 'seeds' : 'food') : a.type === 'buyPlot' ? 'plots' : a.type === 'buyTicket' ? 'tickets' : 'shop'
        spent[k] -= d
      }
      return r
    } catch (e) {
      if (e instanceof GameError) return null
      throw e
    }
  }

  act({ type: 'onboard', playerName: 'Sim', petName: 'Bông', species: 'capybara', fur: 'cocoa' })
  for (const step of ['pet', 'place', 'feed', 'plant', 'game', 'harvest', 'visit', 'passport']) act({ type: 'tutorial', step, status: 'skipped' })

  const plantAll = (nextVisitMs: number) => {
    const rank = rankOf(s)
    const options = CROPS.filter(c => c.rank <= rank)
    // cây lâu nhất vẫn chín trước lần ghé sau (người chơi thật hay chọn thế); nếu không có thì cây nhanh nhất
    const fits = options.filter(c => c.growSec * 1000 * 0.85 <= nextVisitMs).sort((a, b) => b.growSec - a.growSec)
    // trồng trước những gì đơn hàng đang cần mà kho chưa đủ (người chơi thật nhìn bảng đơn rồi gieo)
    const want: string[] = []
    for (const [id, n] of Object.entries(orderNeeds())) {
      const c = options.find(x => x.produceId === id)
      const growing = s.farm.plots.filter(pl => pl.crop === c?.id).length * (c?.yield ?? 1)
      for (let k = (s.stock[id] ?? 0) + growing; c && k < n; k += c.yield) want.push(c.id)
    }
    for (const plot of s.farm.plots) {
      if (plot.idx >= s.farm.unlocked || plot.crop) continue
      const wanted = want.shift()
      // ô đầu tiên trồng loại khác (để có đủ nguyên liệu nấu ăn, đủ loại cây cho hộ chiếu)
      const fit = (wanted ? CROPS.find(c => c.id === wanted) : undefined) ?? (plot.idx === 0 && fits.length > 1 ? fits[fits.length - 1] : fits[0]) ?? options[0]
      if ((s.stock[fit.seedId] ?? 0) <= 0) {
        if (!act({ type: 'buyStock', id: fit.seedId, count: 4 })) act({ type: 'freeSeeds' })
      }
      const seed = (s.stock[fit.seedId] ?? 0) > 0 ? fit.seedId : Object.keys(s.stock).find(k => k.startsWith('seed.') && s.stock[k] > 0 && k !== 'seed.sprout')
      if (seed) {
        act({ type: 'plant', plot: plot.idx, seed })
        act({ type: 'water', plot: plot.idx })
      }
    }
  }

  const orderNeeds = () => {
    const need: Record<string, number> = {}
    for (const o of s.orders.list) for (const [id, n] of Object.entries(o.needs)) need[id] = (need[id] ?? 0) + n
    return need
  }

  const useItem = (id: string) => {
    const it = ITEMS.find(x => x.id === id)!
    if (isPetSlot(it.slot)) {
      if (it.slot !== 'species' && it.slot !== 'fur') act({ type: 'equip', slot: it.slot, item: id })
      return
    }
    const r = roomOfSlot(it.slot)
    if (!r) return
    if (isThemeSlot(it.slot)) act({ type: 'theme', room: r.id, item: id })
    else act({ type: 'place', room: r.id, slot: it.slot, item: id })
  }

  const session = (minutes: number, nextVisitMs: number, runs: number) => {
    const end = clock.t + minutes * 60e3
    const today = dayKey(clock.t)
    // vườn
    for (const plot of s.farm.plots) if (plot.crop && readyAt(plot) <= clock.t) act({ type: 'harvest', plot: plot.idx })
    // nấu một món nếu đủ nông sản, đơn hàng trước rồi mới bán
    for (const o of [...s.orders.list]) act({ type: 'completeOrder', order: o.id })
    const r = RECIPES.find(x => x.rank <= rankOf(s) && Object.entries(x.needs).every(([id, n]) => (s.stock[id] ?? 0) >= n))
    if (r) act({ type: 'cook', recipe: r.id, count: 1 })
    const keep = orderNeeds()
    for (const [id, n] of Object.entries(s.stock)) {
      const extra = n - Math.max(4, keep[id] ?? 0)
      if (id.startsWith('crop.') && extra > 0) act({ type: 'sell', id, count: Math.min(99, extra) })
    }
    plantAll(nextVisitMs)
    // chăm
    if (s.pet.needs.fullness < ECONOMY.care.needsCareBelow) {
      const food = Object.keys(s.stock).find(k => k.startsWith('food.') && s.stock[k] > 0)
      if (food) act({ type: 'feed', food })
      else if (!act({ type: 'buyStock', id: 'food.apple', count: 2 }) || !act({ type: 'feed', food: 'food.apple' })) act({ type: 'freeMeal' })
    }
    if (s.pet.needs.cleanliness < ECONOMY.care.needsCareBelow) act({ type: 'clean' })
    act({ type: 'cuddle' })
    // ghé NPC
    const home = NPC_HOMES[(clock.t / 864e5 | 0) % NPC_HOMES.length]
    act({ type: 'visitNpc', npc: home.npc })
    act({ type: 'npcCompliment', npc: home.npc, sticker: STICKERS[0].id })
    act({ type: 'npcHelpWater', npc: home.npc })
    clock.t += 60e3
    // minigame
    for (let i = 0; i < runs; i++) {
      const game = GAMES[runN++ % GAMES.length]
      const start = act({ type: 'startRun', game }) as { run?: { id: string } } | null
      if (!start?.run) continue
      const { r: result, sec } = playResult(game, p.skill, runN)
      clock.t += sec * 1000
      const res = act({ type: 'finishRun', run: start.run.id, result }) as { note?: string } | null
      if (res?.note === 'dailyCap' && capDay !== today) {
        capDay = today
        rep.gameCapHitDays += 1
      }
    }
    // nhiệm vụ ngày, hộ chiếu
    for (const t of dailyTasksFor(s.profile.id, today)) act({ type: 'claimDaily', task: t.id })
    for (const ch of CHAPTERS) if (!s.passport.claimed.includes(ch.id)) act({ type: 'claimChapter', chapter: ch.id })
    // tiêu xu: mở ô đất, mua nội thất rẻ nhất chưa có (giữ lại 60 xu), vé capsule
    while (act({ type: 'buyPlot' })) { /* mở hết ô đủ tiền */ }
    // còn ô mở được ở hạng hiện tại thì để dành tiền cho ô đất trước
    const nextPlot = ECONOMY.farm.plotPrices.find(x => x.plot === s.farm.unlocked + 1)
    const reserve = nextPlot && nextPlot.rank <= rankOf(s) ? nextPlot.price : 60
    if (p.buysTickets && s.wallet.coins > reserve + ECONOMY.capsule.ticketPriceCoins && act({ type: 'buyTicket' })) rep.ticketsBought += 1
    const shop = ITEMS.filter(i => i.source === 'shop' && i.slot !== 'species' && !s.owned.includes(i.id) && i.rank <= rankOf(s)).sort((a, b) => a.price - b.price)
    for (const it of shop) {
      if (s.wallet.coins - it.price < reserve) break
      if (act({ type: 'buyItem', item: it.id })) useItem(it.id)
    }
    // việc nhỏ người chơi hay làm: lưu bố cục, chụp ảnh, xem trước nhà
    if (s.wallet.coins >= 0 && (s.counters.layout_saved ?? 0) === 0 && s.owned.length > 30) act({ type: 'saveLayout', room: 'study', index: 0, name: 'Yêu thích' })
    if (Number(today.slice(-2)) % 7 === 0) { act({ type: 'photo' }); act({ type: 'sharePreview' }) }
    while (s.wallet.tickets > 0 && act({ type: 'openCapsule', series: SERIES[0].id })) rep.pulls += 1
    clock.t = Math.max(clock.t, end)
  }

  // đặt các món quà khởi đầu (như bước hướng dẫn)
  for (const id of [...s.owned]) {
    const it = ITEMS.find(x => x.id === id)
    if (it && !isPetSlot(it.slot) && !isThemeSlot(it.slot) && !Object.values(s.home.rooms).some(r => Object.values(r?.slots ?? {}).some(x => x?.item === id))) useItem(id)
  }
  for (let d = 0; d < days; d++) {
    const dayStart = start + (d + 1) * 864e5
    const times = p.sessions.map(x => ({ at: dayStart + x.hour * 3600e3, minutes: x.minutes }))
    times.forEach((x, i) => {
      clock.t = Math.max(clock.t, x.at)
      const next = times[i + 1]?.at ?? dayStart + 864e5 + p.sessions[0].hour * 3600e3
      session(x.minutes, next - (x.at + x.minutes * 60e3), p.sessions[i].runs)
    })
    const day = d + 1
    const rank = rankOf(s)
    for (let k = 2; k <= rank; k++) if (rep.rankDay[k] == null) rep.rankDay[k] = day
    if ([1, 3, 7, 14, 30].includes(day)) {
      rep.coinsAt[day] = s.wallet.coins
      rep.itemsAt[day] = s.owned.length
      rep.plotsAt[day] = s.farm.unlocked
    }
  }
  rep.coinsAt[31] = s.wallet.coins
  if (process.argv.includes('--debug')) console.error(p.key, 'thu hoạch', s.counters.harvest, 'bán', s.counters.sell, 'gieo', s.counters.plant, 'đơn', s.counters.order, 'kho', JSON.stringify(s.stock))
  const { taskDone } = engine
  for (const ch of CHAPTERS) if (!s.passport.claimed.includes(ch.id)) rep.missing.push(...ch.tasks.filter(t => !taskDone(s, t)).map(t => t.text))
  rep.affectionLevel = affectionLevel(s.pet.affection)
  return rep
}

const reports = PERSONAS.map(p => simulate(p))
const out: string[] = []
const total = (r: Report) => Object.values(r.earned).reduce((a, b) => a + b, 0)
out.push('| Kiểu người chơi | Phút/ngày | Xu/ngày (ròng sau tiền hạt) | Xu/phút | Vườn (bán − hạt) | Đơn hàng | Minigame | Chăm pet | Nhiệm vụ ngày | Hộ chiếu |')
out.push('|---|---|---|---|---|---|---|---|---|---|')
for (const r of reports) {
  const e = r.earned
  const net = total(r) - r.spent.seeds
  out.push(`| ${r.persona.name} | ${r.minutesPerDay} | ${Math.round(net / 30)} | ${(net / 30 / r.minutesPerDay).toFixed(1)} | ${Math.round((e.farm - r.spent.seeds) / 30)} | ${Math.round(e.orders / 30)} | ${Math.round(e.games / 30)} | ${Math.round(e.care / 30)} | ${Math.round(e.daily / 30)} | ${e.passport} (cả 30 ngày) |`)
}
out.push('')
out.push('| Kiểu người chơi | Lên hạng 2 / 3 / 4 / 5 / 6 (ngày) | Ô đất ngày 7 / 30 | Món sở hữu ngày 1 / 7 / 14 / 30 | Chi: nội thất & đồ / ô đất / đồ ăn / vé | Lượt capsule | Ngày chạm trần xu minigame | Bậc thân thiết |')
out.push('|---|---|---|---|---|---|---|---|')
for (const r of reports) {
  const ranks = [2, 3, 4, 5, 6].map(k => r.rankDay[k] ?? '–').join(' / ')
  out.push(`| ${r.persona.name} | ${ranks} | ${r.plotsAt[7]} / ${r.plotsAt[30]} | ${r.itemsAt[1]} / ${r.itemsAt[7]} / ${r.itemsAt[14]} / ${r.itemsAt[30]} | ${r.spent.shop} / ${r.spent.plots} / ${r.spent.food} / ${r.spent.tickets} | ${r.pulls} | ${r.gameCapHitDays}/30 | ${r.affectionLevel} |`)
}
const shopItems = ITEMS.filter(i => i.source === 'shop')
out.push('')
out.push(`Cửa hàng có ${shopItems.length} món, tổng ${shopItems.reduce((n, i) => n + i.price, 0)} xu. Đồ chỉ có trong capsule: ${ITEMS.filter(i => i.source === 'capsule').length} món.`)
if (process.argv.includes('--debug')) for (const r of reports) console.error(r.persona.name, 'xu cuối:', r.coinsAt[31], 'việc hộ chiếu còn thiếu:', r.missing.join('; '))
console.log(out.join('\n'))
