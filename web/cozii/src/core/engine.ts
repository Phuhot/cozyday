// Luật chơi thuần (không I/O). Chế độ chơi trên máy (LocalBackend) chạy trực tiếp các hàm này;
// máy chủ Supabase cài lại đúng các luật này bằng SQL (supabase/migrations) và được kiểm tra chéo bằng test.
import { ECONOMY } from '../content/economy'
import {
  item as catalogItem, defaultOwned, isPetSlot, isThemeSlot, MAX_NUDGE, room as roomDef, ROOMS, roomOfSlot,
  type ItemSlot, type RoomId,
} from '../content/catalog'
import { CROPS, crop as cropDef, cropBySeed, food as foodDef, recipe as recipeDef, TUTORIAL_CROP } from '../content/farm'
import { SERIES, series as seriesDef } from '../content/capsule'
import { CHAPTERS, NPCS, NPC_HOMES, STICKERS, dailyTasksFor, type PassportTask } from '../content/town'
import { NATURAL_FUR, SPECIES, FURS, type FurColor, type PetSpecies } from '../content/pet'
import { dayKey } from './time'
import {
  affectionLevel, rankOf, readyAt, GAME_IDS,
  type GameId, type GameState, type Needs, type Order, type Plot, type PullResult, type RunTicket,
} from './state'
import { checkRun, type RunResult, type RunVerdict } from './games'

export class GameError extends Error {
  readonly code: string
  constructor(code: string, message: string) {
    super(message)
    this.code = code
  }
}

export interface Env {
  now: number
  /** Số ngẫu nhiên [0, 1) — trên máy dùng crypto, trên máy chủ dùng random() của Postgres. */
  rand: () => number
  uuid: () => string
}

const fail = (code: string, msg: string): never => {
  throw new GameError(code, msg)
}

// ---------------- Khởi tạo ----------------

export function newState(id: string, now: number, env: Env, mode: 'local' | 'online' = 'local'): GameState {
  const day = dayKey(now)
  const s: GameState = {
    mode,
    version: 1,
    serverNow: now,
    profile: { id, name: '', friendCode: '', title: null, frame: null, createdAt: now, isAnonymous: true, onboarded: false },
    pet: {
      name: '', species: 'cat', fur: 'cream', wear: {},
      needs: { ...ECONOMY.care.initial, asOf: now }, affection: 0,
    },
    wallet: { coins: ECONOMY.start.coins, tickets: ECONOMY.start.tickets, shards: 0 },
    owned: defaultOwned(),
    stock: { 'seed.radish': 4, 'seed.carrot': 2, 'food.apple': 3, 'seed.sprout': 1 },
    home: { rooms: {} },
    farm: { plots: [], unlocked: ECONOMY.farm.startPlots, freeSeedDay: null, tutorialSeedUsed: false },
    orders: { list: [], rerollDay: day, rerollsUsed: 0, doneDay: day, doneToday: 0 },
    counters: {},
    daily: { day, claimed: [], bonusClaimed: false },
    caps: {},
    passport: { claimed: [] },
    capsule: { pity: {}, last: [], ticketDay: day, ticketsBought: 0 },
    titles: [],
    poses: [],
    badges: [],
    presets: { outfits: Array(ECONOMY.presets.outfits).fill(null), layouts: {} },
    records: {},
    social: { visibility: 'private', shareGarden: true, showSources: true, publishedAt: null },
    onboarding: { storySeen: false, tutorial: {}, tutorialHidden: false },
    runs: [],
  }
  for (const r of ROOMS) s.home.rooms[r.id] = { theme: r.defaultTheme, slots: {} }
  s.home.rooms.study!.slots.seat = { item: 'seat.rug', flip: false, dx: 0 }
  for (let i = 0; i < ECONOMY.farm.maxPlots; i++) s.farm.plots.push(emptyPlot(i))
  while (s.orders.list.length < ECONOMY.orders.active) s.orders.list.push(makeOrder(s, env))
  return s
}

function emptyPlot(idx: number): Plot {
  return { idx, crop: null, plantedAt: 0, growSec: 0, cutPct: 0, selfWatered: false, helps: 0 }
}

// ---------------- Tiện ích ----------------

function owns(s: GameState, id: string) {
  return s.owned.includes(id)
}

function grant(s: GameState, id: string) {
  if (!owns(s, id)) s.owned.push(id)
}

function addStock(s: GameState, id: string, n: number) {
  const v = (s.stock[id] ?? 0) + n
  if (v < 0) fail('stock', 'Không đủ trong kho.')
  if (v > ECONOMY.farm.maxStack) fail('stock_full', 'Kho đã đầy loại này.')
  if (v === 0) delete s.stock[id]
  else s.stock[id] = v
}

function spend(s: GameState, coins: number) {
  if (s.wallet.coins < coins) fail('coins', `Cần ${coins} xu, bạn đang có ${s.wallet.coins} xu.`)
  s.wallet.coins -= coins
}

/** Tăng bộ đếm trọn đời và bộ đếm của ngày (cho nhiệm vụ ngày). */
export function bump(s: GameState, key: string, n: number, env: Env) {
  s.counters[key] = (s.counters[key] ?? 0) + n
  const dk = `d:${dayKey(env.now)}:${key}`
  s.counters[dk] = (s.counters[dk] ?? 0) + n
}

function capKey(env: Env, kind: string) {
  return `${dayKey(env.now)}|${kind}`
}
/** Giá vốn hạt giống của một quả (giá hạt ÷ sản lượng, làm tròn lên). */
export function unitCost(c: { seedPrice: number; yield: number }): number {
  return Math.ceil(c.seedPrice / c.yield)
}

/**
 * Giá bán `n` quả hôm nay: đủ giá cho tới khi tiền lãi trong ngày chạm ECONOMY.farm.marketProfitPerDay,
 * phần còn lại mua đúng giá vốn (hòa vốn).
 */
export function sellQuote(s: GameState, now: number, c: { sellPrice: number; seedPrice: number; yield: number }, n: number): { coins: number; profit: number; atCost: number } {
  let left = marketProfitLeft(s, now)
  const cost = unitCost(c)
  const margin = Math.max(0, c.sellPrice - cost)
  let coins = 0, profit = 0, atCost = 0
  for (let i = 0; i < n; i++) {
    if (left > 0 || margin === 0) {
      coins += c.sellPrice
      profit += margin
      left -= margin
    } else {
      coins += Math.min(cost, c.sellPrice)
      atCost += 1
    }
  }
  return { coins, profit, atCost }
}

export function marketProfitLeft(s: GameState, now: number): number {
  return Math.max(0, ECONOMY.farm.marketProfitPerDay - (s.caps[`${dayKey(now)}|market:profit`] ?? 0))
}

function capUsed(s: GameState, env: Env, kind: string) {
  return s.caps[capKey(env, kind)] ?? 0
}
function capAdd(s: GameState, env: Env, kind: string, n: number) {
  const k = capKey(env, kind)
  s.caps[k] = (s.caps[k] ?? 0) + n
}

/** Xóa bộ đếm/hạn mức của các ngày cũ (giữ 3 ngày gần nhất). */
function prune(s: GameState, env: Env) {
  const keep = new Set([0, 1, 2].map(d => dayKey(env.now - d * 86400000)))
  for (const k of Object.keys(s.caps)) if (!keep.has(k.split('|')[0])) delete s.caps[k]
  for (const k of Object.keys(s.counters)) if (k.startsWith('d:') && !keep.has(k.slice(2, 12))) delete s.counters[k]
  s.runs = s.runs.filter(r => r.expiresAt > env.now)
}

// ---------------- Nhu cầu & thân thiết ----------------

export function needsAt(n: Needs, now: number): Needs {
  const c = ECONOMY.care
  const hours = Math.min(Math.max(0, (now - n.asOf) / 3600000), c.maxDecayHours)
  const decay = (v: number, perHour: number) => (v > c.floor ? Math.max(c.floor, v - perHour * hours) : v)
  return {
    fullness: decay(n.fullness, c.perHour.fullness),
    cleanliness: decay(n.cleanliness, c.perHour.cleanliness),
    happiness: decay(n.happiness, c.perHour.happiness),
    asOf: Math.max(n.asOf, now),
  }
}

function clamp100(v: number) {
  return Math.max(0, Math.min(100, v))
}

function addAffection(s: GameState, env: Env, n: number): number {
  const left = ECONOMY.care.dailyAffectionCap - capUsed(s, env, 'affection')
  const got = Math.max(0, Math.min(left, n))
  if (got > 0) {
    s.pet.affection += got
    capAdd(s, env, 'affection', got)
  }
  return got
}

export interface CareReward { coins: number; affection: number; note: 'rewarded' | 'notNeeded' | 'kindLimit' | 'dailyLimit' | 'free' }

function careReward(s: GameState, env: Env, kind: 'feed' | 'clean' | 'cuddle', before: number): CareReward {
  const c = ECONOMY.care
  const affection = before < c.affectionBelow ? addAffection(s, env, c.affectionPerCare) : 0
  if (before >= c.needsCareBelow) return { coins: 0, affection, note: 'notNeeded' }
  if (capUsed(s, env, 'care:' + kind) >= c.rewardedPerKindPerDay) return { coins: 0, affection, note: 'kindLimit' }
  const left = c.dailyCoinCap - capUsed(s, env, 'care:coins')
  if (left <= 0) return { coins: 0, affection, note: 'dailyLimit' }
  const coins = Math.min(left, c.coins[kind])
  s.wallet.coins += coins
  capAdd(s, env, 'care:' + kind, 1)
  capAdd(s, env, 'care:coins', coins)
  return { coins, affection, note: 'rewarded' }
}

// ---------------- Đơn hàng ----------------

const ORDER_NPCS = ['bo', 'la', 'moc', 'tra', 'may', 'pip']

export function makeOrder(s: GameState, env: Env): Order {
  const rank = rankOf(s)
  const pool = CROPS.filter(c => c.rank <= rank)
  const kinds = 1 + Math.floor(env.rand() * Math.min(3, pool.length))
  const picked = [...pool]
  const needs: Record<string, number> = {}
  for (let i = 0; i < kinds && picked.length; i++) {
    const c = picked.splice(Math.floor(env.rand() * picked.length), 1)[0]
    const max = c.growSec <= 300 ? 4 : c.growSec <= 2400 ? 3 : 2
    needs[c.produceId] = 1 + Math.floor(env.rand() * max)
  }
  return {
    id: env.uuid(),
    npc: ORDER_NPCS[Math.floor(env.rand() * ORDER_NPCS.length)],
    needs,
    coins: orderCoins(needs),
    createdAt: env.now,
  }
}

export function orderCoins(needs: Record<string, number>): number {
  let sum = 0
  for (const [pid, n] of Object.entries(needs)) sum += (CROPS.find(c => c.produceId === pid)?.sellPrice ?? 0) * n
  return Math.max(5, Math.round((sum * ECONOMY.orders.rewardMultiplier) / 5) * 5)
}

// ---------------- Hộ chiếu ----------------

export function derived(s: GameState, key: string): number {
  if (key.startsWith('derived:')) {
    const k = key.slice(8)
    switch (k) {
      case 'harvest_kinds':
        return Object.keys(s.counters).filter(x => x.startsWith('harvest_kind:')).length
      case 'homes_visited':
        return Object.keys(s.counters).filter(x => x.startsWith('home_visited:')).length
      case 'furniture_bought':
        return s.owned.filter(id => {
          const it = catalogItem(id)
          return it && !isPetSlot(it.slot) && it.source !== 'starter'
        }).length
      case 'wearing':
        return Object.values(s.pet.wear).filter(Boolean).length
      case 'affection_level':
        return affectionLevel(s.pet.affection)
      case 'games_distinct':
        return GAME_IDS.filter(g => (s.counters['game:' + g] ?? 0) > 0).length
    }
    return 0
  }
  if (key.startsWith('best:')) return s.records[key.slice(5) as GameId]?.best ?? 0
  return s.counters[key] ?? 0
}

export function taskDone(s: GameState, t: PassportTask): boolean {
  return derived(s, t.key) >= t.target
}

// ---------------- Lượt chơi ----------------

const RULES_VERSION = 1

// ---------------- Các thao tác ----------------

export type Action =
  | { type: 'onboard'; playerName: string; petName: string; species: PetSpecies; fur: FurColor }
  | { type: 'setNames'; playerName?: string; petName?: string }
  | { type: 'storySeen' }
  | { type: 'tutorial'; step: string; status: 'done' | 'skipped' | 'later' | 'reset' }
  | { type: 'tutorialHidden'; hidden: boolean }
  | { type: 'place'; room: RoomId; slot: ItemSlot; item: string | null; flip?: boolean; dx?: number }
  | { type: 'theme'; room: RoomId; item: string }
  | { type: 'saveLayout'; room: RoomId; index: number; name: string }
  | { type: 'applyLayout'; room: RoomId; index: number }
  | { type: 'equip'; slot: 'species' | 'fur' | 'hat' | 'glasses' | 'neck' | 'outfit' | 'back'; item: string | null }
  | { type: 'saveOutfit'; index: number; name: string }
  | { type: 'applyOutfit'; index: number }
  | { type: 'buyItem'; item: string }
  | { type: 'buyStock'; id: string; count: number }
  | { type: 'sell'; id: string; count: number }
  | { type: 'cook'; recipe: string; count: number }
  | { type: 'feed'; food: string }
  | { type: 'freeMeal' }
  | { type: 'clean' }
  | { type: 'cuddle' }
  | { type: 'plant'; plot: number; seed: string }
  | { type: 'water'; plot: number }
  | { type: 'harvest'; plot: number }
  | { type: 'buyPlot' }
  | { type: 'freeSeeds' }
  | { type: 'completeOrder'; order: string }
  | { type: 'rerollOrder'; order: string }
  | { type: 'claimChapter'; chapter: number }
  | { type: 'claimDaily'; task: string }
  | { type: 'startRun'; game: GameId; weekly?: boolean }
  | { type: 'finishRun'; run: string; result: RunResult }
  | { type: 'buyTicket' }
  | { type: 'openCapsule'; series: string }
  | { type: 'exchangeShards'; item: string }
  | { type: 'claimSeries'; series: string }
  | { type: 'setTitle'; title: string | null }
  | { type: 'photo' }
  | { type: 'sharePreview' }
  | { type: 'setPrivacy'; visibility?: 'private' | 'friends' | 'public'; shareGarden?: boolean; showSources?: boolean }
  | { type: 'visitNpc'; npc: string }
  | { type: 'npcCompliment'; npc: string; sticker: string }
  | { type: 'npcHelpWater'; npc: string }

export type ActionResult = Record<string, unknown> | undefined

export function apply(s: GameState, a: Action, env: Env): ActionResult {
  prune(s, env)
  s.serverNow = env.now
  if (!s.profile.onboarded && a.type !== 'onboard' && a.type !== 'storySeen' && a.type !== 'tutorial' && a.type !== 'tutorialHidden') {
    fail('not_onboarded', 'Hãy chọn bạn nhỏ trước đã.')
  }
  const r = run(s, a, env)
  s.version += 1
  return r
}

function cleanName(raw: string, max: number, what: string): string {
  const v = raw.replace(/[\u0000-\u001f\u007f<>]/g, '').replace(/\s+/g, ' ').trim()
  if (v.length < 1) fail('name', `Hãy đặt ${what}.`)
  if ([...v].length > max) fail('name', `${what[0].toUpperCase() + what.slice(1)} tối đa ${max} ký tự.`)
  return v
}

function run(s: GameState, a: Action, env: Env): ActionResult {
  const now = env.now
  const rank = rankOf(s)
  switch (a.type) {
    case 'onboard': {
      if (s.profile.onboarded) fail('done', 'Bạn đã có bạn nhỏ rồi.')
      if (!SPECIES.includes(a.species)) fail('species', 'Loài không hợp lệ.')
      if (!FURS.includes(a.fur)) fail('fur', 'Màu lông không hợp lệ.')
      s.profile.name = cleanName(a.playerName, 20, 'tên của bạn')
      s.pet.name = cleanName(a.petName, 16, 'tên cho bạn nhỏ')
      s.pet.species = a.species
      s.pet.fur = a.fur
      grant(s, 'species.' + a.species)
      grant(s, 'fur.' + a.fur)
      grant(s, 'fur.' + NATURAL_FUR[a.species])
      grant(s, 'lamp.candle') // món quà đầu tiên bạn nhỏ mang theo
      s.pet.needs = { ...ECONOMY.care.initial, asOf: now }
      s.profile.onboarded = true
      bump(s, 'named', 1, env)
      return { gift: 'lamp.candle' }
    }
    case 'setNames': {
      if (a.playerName != null) s.profile.name = cleanName(a.playerName, 20, 'tên của bạn')
      if (a.petName != null) s.pet.name = cleanName(a.petName, 16, 'tên cho bạn nhỏ')
      return
    }
    case 'storySeen':
      s.onboarding.storySeen = true
      return
    case 'tutorial':
      if (a.status === 'reset') delete s.onboarding.tutorial[a.step]
      else s.onboarding.tutorial[a.step] = a.status
      return
    case 'tutorialHidden':
      s.onboarding.tutorialHidden = a.hidden
      return

    // ---- Nhà ----
    case 'place': {
      const r = roomDef(a.room)
      if (!r) fail('room', 'Phòng không tồn tại.')
      if (rank < r.rank) fail('locked', `${r.name} mở ở hạng thị trấn ${r.rank}.`)
      if (!r.slots.includes(a.slot)) fail('slot', 'Vị trí này không thuộc phòng.')
      const rs = s.home.rooms[a.room]!
      if (a.item == null) {
        delete rs.slots[a.slot]
        return
      }
      const it = catalogItem(a.item)
      if (!it || it.slot !== a.slot) fail('item', 'Món này không đặt được ở đây.')
      if (!owns(s, a.item)) fail('not_owned', 'Bạn chưa có món này.')
      const dx = Math.max(-MAX_NUDGE, Math.min(MAX_NUDGE, Math.round((a.dx ?? 0) * 2) / 2))
      const prev = rs.slots[a.slot]
      rs.slots[a.slot] = { item: a.item, flip: !!a.flip, dx }
      if (!prev || prev.item !== a.item) bump(s, 'place_item', 1, env)
      return
    }
    case 'theme': {
      const r = roomDef(a.room)
      if (rank < r.rank) fail('locked', `${r.name} mở ở hạng thị trấn ${r.rank}.`)
      const it = catalogItem(a.item)
      if (!it || it.slot !== r.themeSlot) fail('item', 'Đây không phải tường & sàn của phòng này.')
      if (!owns(s, a.item)) fail('not_owned', 'Bạn chưa có mẫu tường này.')
      const rs = s.home.rooms[a.room]!
      if (rs.theme !== a.item) bump(s, 'theme_changed', 1, env)
      rs.theme = a.item
      return
    }
    case 'saveLayout': {
      const r = roomDef(a.room)
      if (rank < r.rank) fail('locked', 'Phòng chưa mở.')
      if (a.index < 0 || a.index >= ECONOMY.presets.layoutsPerRoom) fail('index', 'Ô lưu không hợp lệ.')
      const rs = s.home.rooms[a.room]!
      const list = s.presets.layouts[a.room] ?? Array(ECONOMY.presets.layoutsPerRoom).fill(null)
      list[a.index] = { name: cleanName(a.name || `Bố cục ${a.index + 1}`, 24, 'tên bố cục'), theme: rs.theme, slots: JSON.parse(JSON.stringify(rs.slots)) }
      s.presets.layouts[a.room] = list
      bump(s, 'layout_saved', 1, env)
      return
    }
    case 'applyLayout': {
      const p = s.presets.layouts[a.room]?.[a.index]
      if (!p) fail('empty', 'Ô lưu này còn trống.')
      const missing = [p!.theme, ...Object.values(p!.slots).map(x => x!.item)].filter(id => !owns(s, id))
      if (missing.length) fail('not_owned', 'Bố cục có món bạn không còn sở hữu.')
      s.home.rooms[a.room] = { theme: p!.theme, slots: JSON.parse(JSON.stringify(p!.slots)) }
      return
    }

    // ---- Pet ----
    case 'equip': {
      if (a.slot === 'species' || a.slot === 'fur') {
        if (!a.item) fail('item', 'Phải chọn một lựa chọn.')
        const it = catalogItem(a.item!)
        if (!it || it.slot !== a.slot) fail('item', 'Món không hợp lệ.')
        if (!owns(s, a.item!)) fail('not_owned', 'Bạn chưa có lựa chọn này.')
        const v = a.item!.split('.')[1]
        if (a.slot === 'species') s.pet.species = v as PetSpecies
        else s.pet.fur = v as FurColor
        return
      }
      if (a.item == null) {
        delete s.pet.wear[a.slot]
        return
      }
      const it = catalogItem(a.item)
      if (!it || it.slot !== a.slot) fail('item', 'Món không hợp lệ.')
      if (!owns(s, a.item)) fail('not_owned', 'Bạn chưa có món này.')
      s.pet.wear[a.slot] = a.item
      return
    }
    case 'saveOutfit': {
      if (a.index < 0 || a.index >= ECONOMY.presets.outfits) fail('index', 'Ô lưu không hợp lệ.')
      s.presets.outfits[a.index] = {
        name: cleanName(a.name || `Bộ ${a.index + 1}`, 24, 'tên bộ đồ'),
        species: s.pet.species, fur: s.pet.fur, wear: { ...s.pet.wear },
      }
      return
    }
    case 'applyOutfit': {
      const p = s.presets.outfits[a.index]
      if (!p) fail('empty', 'Ô lưu này còn trống.')
      const ids = ['species.' + p!.species, 'fur.' + p!.fur, ...Object.values(p!.wear).filter(Boolean) as string[]]
      if (ids.some(id => !owns(s, id))) fail('not_owned', 'Bộ đồ có món bạn chưa có.')
      s.pet.species = p!.species
      s.pet.fur = p!.fur
      s.pet.wear = { ...p!.wear }
      return
    }

    // ---- Mua bán ----
    case 'buyItem': {
      const it = catalogItem(a.item)
      if (!it || it.source !== 'shop') fail('item', 'Món này không bán ở cửa hàng.')
      if (owns(s, a.item)) fail('owned', 'Bạn đã có món này rồi.')
      if (rank < it!.rank) fail('rank', `Mở bán ở hạng thị trấn ${it!.rank}.`)
      spend(s, it!.price)
      grant(s, a.item)
      bump(s, 'buy', 1, env)
      return { item: a.item }
    }
    case 'buyStock': {
      const n = Math.floor(a.count)
      if (!(n >= 1 && n <= 10)) fail('count', 'Mỗi lần mua 1–10.')
      let price = 0
      if (a.id.startsWith('seed.')) {
        const c = cropBySeed(a.id)
        if (!c || c.id === TUTORIAL_CROP.id) fail('item', 'Không có hạt này.')
        if (rank < c!.rank) fail('rank', `Hạt này mở ở hạng ${c!.rank}.`)
        price = c!.seedPrice
      } else {
        const f = foodDef(a.id)
        if (!f || f.price <= 0) fail('item', 'Món này không bán sẵn.')
        price = f!.price
      }
      spend(s, price * n)
      addStock(s, a.id, n)
      return
    }
    case 'sell': {
      const c = CROPS.find(x => x.produceId === a.id)
      const n = Math.floor(a.count)
      if (!c) fail('item', 'Chỉ bán được nông sản.')
      if (!(n >= 1 && n <= 99)) fail('count', 'Số lượng không hợp lệ.')
      const quote = sellQuote(s, now, c!, n)
      addStock(s, a.id, -n)
      s.wallet.coins += quote.coins
      capAdd(s, env, 'market:profit', quote.profit)
      bump(s, 'sell', n, env)
      return { coins: quote.coins, atCost: quote.atCost }
    }
    case 'cook': {
      const r = recipeDef(a.recipe)
      const n = Math.floor(a.count)
      if (!r) fail('recipe', 'Không có công thức này.')
      if (rank < r!.rank) fail('rank', `Công thức mở ở hạng ${r!.rank}.`)
      if (!(n >= 1 && n <= 10)) fail('count', 'Mỗi lần nấu 1–10 phần.')
      for (const [id, k] of Object.entries(r!.needs)) if ((s.stock[id] ?? 0) < k * n) fail('stock', 'Chưa đủ nguyên liệu.')
      for (const [id, k] of Object.entries(r!.needs)) addStock(s, id, -k * n)
      addStock(s, r!.output, r!.count * n)
      bump(s, 'cook', n, env)
      return
    }

    // ---- Chăm sóc ----
    case 'feed': {
      const f = foodDef(a.food)
      if (!f) fail('food', 'Không có món này.')
      const n = needsAt(s.pet.needs, now)
      if (n.fullness >= ECONOMY.care.fullEnough) fail('full', `${s.pet.name} no rồi, để lát nữa nhé.`)
      addStock(s, a.food, -1)
      const before = n.fullness
      n.fullness = clamp100(n.fullness + f!.fullness)
      n.happiness = clamp100(n.happiness + f!.happiness)
      s.pet.needs = n
      bump(s, 'feed', 1, env)
      return { reward: careReward(s, env, 'feed', before) }
    }
    case 'freeMeal': {
      const n = needsAt(s.pet.needs, now)
      if (n.fullness >= ECONOMY.care.needsCareBelow) fail('not_hungry', 'Bữa cơ bản chỉ có khi bạn nhỏ đói.')
      n.fullness = Math.max(n.fullness, ECONOMY.care.freeMealTo)
      s.pet.needs = n
      bump(s, 'feed', 1, env)
      return { reward: { coins: 0, affection: 0, note: 'free' } }
    }
    case 'clean': {
      const n = needsAt(s.pet.needs, now)
      if (n.cleanliness >= ECONOMY.care.cleanEnough) fail('clean', 'Nhà đang sạch bong rồi.')
      const before = n.cleanliness
      n.cleanliness = ECONOMY.care.cleanTo
      s.pet.needs = n
      bump(s, 'clean', 1, env)
      return { reward: careReward(s, env, 'clean', before) }
    }
    case 'cuddle': {
      const n = needsAt(s.pet.needs, now)
      const before = n.happiness
      n.happiness = clamp100(n.happiness + ECONOMY.care.cuddleGain)
      s.pet.needs = n
      bump(s, 'cuddle', 1, env)
      return { reward: careReward(s, env, 'cuddle', before) }
    }

    // ---- Vườn ----
    case 'plant': {
      const p = plotAt(s, a.plot)
      if (p.crop) fail('busy', 'Ô này đang có cây.')
      const c = cropBySeed(a.seed)
      if (!c) fail('seed', 'Không có hạt này.')
      if (c!.id === TUTORIAL_CROP.id) {
        if (s.farm.tutorialSeedUsed) fail('seed', 'Hạt hướng dẫn chỉ gieo được một lần.')
        s.farm.tutorialSeedUsed = true
      }
      addStock(s, a.seed, -1)
      Object.assign(p, { crop: c!.id, plantedAt: now, growSec: c!.growSec, cutPct: 0, selfWatered: false, helps: 0 })
      bump(s, 'plant', 1, env)
      return
    }
    case 'water': {
      const p = plotAt(s, a.plot)
      if (!p.crop) fail('empty', 'Ô này chưa gieo gì.')
      if (now >= readyAt(p)) fail('ready', 'Cây đã chín, thu hoạch thôi.')
      if (p.selfWatered) fail('watered', 'Vụ này đã tưới rồi. Cây vẫn đang lớn đều.')
      p.selfWatered = true
      p.cutPct = Math.min(ECONOMY.farm.maxCutPct, p.cutPct + ECONOMY.farm.selfWaterCutPct)
      bump(s, 'water', 1, env)
      return
    }
    case 'harvest': {
      const p = plotAt(s, a.plot)
      if (!p.crop) fail('empty', 'Ô này chưa gieo gì.')
      if (now < readyAt(p)) fail('not_ready', 'Cây chưa chín. Máy chủ chưa xác nhận thu hoạch.')
      const c = cropDef(p.crop!)!
      addStock(s, c.produceId, c.yield)
      bump(s, 'harvest', 1, env)
      bump(s, 'harvest_kind:' + (c.id === TUTORIAL_CROP.id ? 'radish' : c.id), 1, env)
      Object.assign(p, emptyPlot(p.idx))
      return { produce: c.produceId, count: c.yield }
    }
    case 'buyPlot': {
      if (s.farm.unlocked >= ECONOMY.farm.maxPlots) fail('max', 'Vườn đã đủ 12 ô.')
      const next = s.farm.unlocked + 1
      const def = ECONOMY.farm.plotPrices.find(x => x.plot === next)!
      if (rank < def.rank) fail('rank', `Ô đất này mở ở hạng ${def.rank}.`)
      spend(s, def.price)
      s.farm.unlocked = next
      bump(s, 'plot_bought', 1, env)
      return
    }
    case 'freeSeeds': {
      const today = dayKey(now)
      if (s.farm.freeSeedDay === today) fail('used', 'Hôm nay bạn đã nhận gói hạt miễn phí rồi.')
      const hasSeeds = Object.keys(s.stock).some(k => k.startsWith('seed.') && k !== 'seed.sprout')
      const planted = s.farm.plots.some(p => p.crop)
      if (s.wallet.coins >= 10 || hasSeeds || planted) fail('not_needed', 'Gói hạt miễn phí dành cho lúc hết xu và vườn trống.')
      s.farm.freeSeedDay = today
      addStock(s, ECONOMY.farm.freeSeedPack.seed, ECONOMY.farm.freeSeedPack.count)
      return
    }

    // ---- Đơn hàng ----
    case 'completeOrder': {
      const o = s.orders.list.find(x => x.id === a.order)
      if (!o) fail('order', 'Đơn này không còn nữa.')
      const today = dayKey(now)
      if (s.orders.doneDay !== today) {
        s.orders.doneDay = today
        s.orders.doneToday = 0
      }
      if (s.orders.doneToday >= ECONOMY.orders.maxCompletedPerDay) fail('cap', 'Hôm nay Bé Bơ nhận đủ đơn rồi. Mai quay lại nhé.')
      for (const [id, n] of Object.entries(o!.needs)) if ((s.stock[id] ?? 0) < n) fail('stock', 'Chưa đủ nông sản cho đơn này.')
      for (const [id, n] of Object.entries(o!.needs)) addStock(s, id, -n)
      s.wallet.coins += o!.coins
      s.orders.doneToday += 1
      bump(s, 'order', 1, env)
      s.orders.list = s.orders.list.filter(x => x.id !== o!.id)
      s.orders.list.push(makeOrder(s, env))
      return { coins: o!.coins }
    }
    case 'rerollOrder': {
      const i = s.orders.list.findIndex(x => x.id === a.order)
      if (i < 0) fail('order', 'Đơn này không còn nữa.')
      const today = dayKey(now)
      if (s.orders.rerollDay !== today) {
        s.orders.rerollDay = today
        s.orders.rerollsUsed = 0
      }
      if (s.orders.rerollsUsed >= ECONOMY.orders.freeRerollsPerDay) fail('cap', 'Hôm nay đã đổi đủ 3 đơn.')
      s.orders.rerollsUsed += 1
      s.orders.list[i] = makeOrder(s, env)
      return
    }

    // ---- Hộ chiếu & nhiệm vụ ngày ----
    case 'claimChapter': {
      const ch = CHAPTERS.find(c => c.id === a.chapter)
      if (!ch) fail('chapter', 'Không có chương này.')
      if (s.passport.claimed.includes(ch!.id)) fail('claimed', 'Chương này đã đóng dấu.')
      if (ch!.id > 1 && !s.passport.claimed.includes(ch!.id - 1)) fail('order', 'Hãy hoàn thành chương trước.')
      if (!ch!.tasks.every(t => taskDone(s, t))) fail('incomplete', 'Còn nhiệm vụ chưa xong.')
      s.passport.claimed.push(ch!.id)
      s.wallet.coins += ch!.reward.coins
      s.wallet.tickets += ch!.reward.tickets
      if (ch!.reward.title && !s.titles.includes(ch!.reward.title)) s.titles.push(ch!.reward.title)
      // Mở thêm hàng đơn phù hợp hạng mới: thay đơn cũ không đổi, chỉ đơn mới mới dùng cây mới.
      return { coins: ch!.reward.coins, tickets: ch!.reward.tickets, rank: rankOf(s) }
    }
    case 'claimDaily': {
      const today = dayKey(now)
      if (s.daily.day !== today) s.daily = { day: today, claimed: [], bonusClaimed: false }
      const tasks = dailyTasksFor(s.profile.id, today)
      const t = tasks.find(x => x.id === a.task)
      if (!t) fail('task', 'Nhiệm vụ này không có trong hôm nay.')
      if (s.daily.claimed.includes(t!.id)) fail('claimed', 'Đã nhận rồi.')
      if ((s.counters[`d:${today}:${t!.key}`] ?? 0) < t!.target) fail('incomplete', 'Chưa xong nhiệm vụ.')
      s.daily.claimed.push(t!.id)
      s.wallet.coins += ECONOMY.daily.coinsPerTask
      let tickets = 0
      if (!s.daily.bonusClaimed && tasks.every(x => s.daily.claimed.includes(x.id))) {
        s.daily.bonusClaimed = true
        s.wallet.tickets += ECONOMY.daily.allDoneTickets
        tickets = ECONOMY.daily.allDoneTickets
      }
      return { coins: ECONOMY.daily.coinsPerTask, tickets }
    }

    // ---- Sân chơi ----
    case 'startRun': {
      if (!GAME_IDS.includes(a.game)) fail('game', 'Không có trò này.')
      const open = s.runs.filter(r => r.expiresAt > now)
      if (open.length >= 5) s.runs = open.slice(-4)
      const t: RunTicket = {
        id: env.uuid(), game: a.game, seed: Math.floor(env.rand() * 2147483646) + 1, rulesVersion: RULES_VERSION,
        startedAt: now, expiresAt: now + ECONOMY.games.runTtlSec * 1000, weekly: !!a.weekly, ranked: false,
      }
      s.runs.push(t)
      return { run: t }
    }
    case 'finishRun': {
      const t = s.runs.find(r => r.id === a.run)
      if (!t) fail('run', 'Lượt chơi đã hết hạn hoặc đã nộp.')
      s.runs = s.runs.filter(r => r.id !== a.run)
      const verdict = checkRun(t!, a.result, now)
      return finishReward(s, env, t!, verdict)
    }

    // ---- Capsule ----
    case 'buyTicket': {
      const today = dayKey(now)
      if (s.capsule.ticketDay !== today) {
        s.capsule.ticketDay = today
        s.capsule.ticketsBought = 0
      }
      if (s.capsule.ticketsBought >= ECONOMY.capsule.maxTicketBuysPerDay) fail('cap', 'Hôm nay đã đổi đủ vé.')
      spend(s, ECONOMY.capsule.ticketPriceCoins)
      s.capsule.ticketsBought += 1
      s.wallet.tickets += 1
      return
    }
    case 'openCapsule': {
      const se = seriesDef(a.series)
      if (!se) fail('series', 'Không có bộ này.')
      if (s.wallet.tickets < 1) fail('tickets', 'Bạn cần một vé capsule.')
      s.wallet.tickets -= 1
      const pull = pullCapsule(s, se!.id, env)
      bump(s, 'capsule_pull', 1, env)
      return { pull }
    }
    case 'exchangeShards': {
      const hit = SERIES.flatMap(x => x.items.map(i => ({ s: x, i }))).find(x => x.i.id === a.item)
      if (!hit) fail('item', 'Món này không đổi bằng mảnh được.')
      if (owns(s, a.item)) fail('owned', 'Bạn đã có món này.')
      const cost = ECONOMY.capsule.shardCost[hit!.i.rarity]
      if (s.wallet.shards < cost) fail('shards', `Cần ${cost} mảnh.`)
      s.wallet.shards -= cost
      grant(s, a.item)
      return
    }
    case 'claimSeries': {
      const se = seriesDef(a.series)
      if (!se) fail('series', 'Không có bộ này.')
      if (!se!.items.every(i => owns(s, i.id))) fail('incomplete', 'Chưa đủ 8 món của bộ.')
      if (owns(s, se!.reward.item)) fail('claimed', 'Đã nhận quà hoàn thành bộ.')
      grant(s, se!.reward.item)
      if (!s.titles.includes(se!.reward.title)) s.titles.push(se!.reward.title)
      if (!s.poses.includes(se!.reward.pose)) s.poses.push(se!.reward.pose)
      return { item: se!.reward.item }
    }

    case 'setTitle': {
      if (a.title != null && !s.titles.includes(a.title)) fail('title', 'Bạn chưa có danh hiệu này.')
      s.profile.title = a.title
      return
    }
    case 'photo':
      bump(s, 'photo', 1, env)
      return
    case 'sharePreview':
      bump(s, 'share_preview', 1, env)
      return
    case 'setPrivacy': {
      if (a.visibility) s.social.visibility = a.visibility
      if (a.shareGarden != null) s.social.shareGarden = a.shareGarden
      if (a.showSources != null) s.social.showSources = a.showSources
      return
    }

    // ---- Nhà NPC (thay thế khi chưa có bạn thật; không có xu) ----
    case 'visitNpc': {
      if (!NPC_HOMES.some(h => h.npc === a.npc)) fail('npc', 'Không có nhà này.')
      if (capUsed(s, env, 'visit:npc:' + a.npc) === 0) {
        capAdd(s, env, 'visit:npc:' + a.npc, 1)
        bump(s, 'visit', 1, env)
        bump(s, 'visit_npc', 1, env)
      }
      if (!s.counters['home_visited:npc:' + a.npc]) s.counters['home_visited:npc:' + a.npc] = 1
      return
    }
    case 'npcCompliment': {
      if (!NPCS.some(n => n.id === a.npc)) fail('npc', 'Không có NPC này.')
      if (!STICKERS.some(x => x.id === a.sticker)) fail('sticker', 'Lời khen không hợp lệ.')
      if (capUsed(s, env, 'compliment:npc:' + a.npc) > 0) fail('cap', 'Hôm nay bạn đã khen nhà này rồi.')
      capAdd(s, env, 'compliment:npc:' + a.npc, 1)
      bump(s, 'compliment', 1, env)
      return
    }
    case 'npcHelpWater': {
      if (!NPC_HOMES.some(h => h.npc === a.npc)) fail('npc', 'Không có nhà này.')
      if (capUsed(s, env, 'help:npc:' + a.npc) > 0) fail('cap', 'Hôm nay bạn đã tưới giúp vườn này rồi.')
      capAdd(s, env, 'help:npc:' + a.npc, 1)
      bump(s, 'help_water', 1, env)
      return
    }
  }
}

function plotAt(s: GameState, idx: number): Plot {
  if (!Number.isInteger(idx) || idx < 0 || idx >= s.farm.unlocked) fail('plot', 'Ô đất này chưa mở.')
  return s.farm.plots[idx]
}

export function pullCapsule(s: GameState, seriesId: string, env: Env): PullResult {
  const se = seriesDef(seriesId)!
  const cfg = ECONOMY.capsule
  const pity = s.capsule.pity[seriesId] ?? { sinceRare: 0, sinceSpecial: 0 }
  pity.sinceRare += 1
  pity.sinceSpecial += 1
  let rarity: 'common' | 'rare' | 'special'
  if (pity.sinceSpecial >= cfg.specialPity) rarity = 'special'
  else if (pity.sinceRare >= cfg.rarePity) rarity = env.rand() * (cfg.rates.rare + cfg.rates.special) < cfg.rates.special ? 'special' : 'rare'
  else {
    const roll = env.rand() * 100
    rarity = roll < cfg.rates.special ? 'special' : roll < cfg.rates.special + cfg.rates.rare ? 'rare' : 'common'
  }
  const tier = se.items.filter(i => i.rarity === rarity)
  const pick = tier[Math.floor(env.rand() * tier.length)]
  if (rarity === 'special') {
    pity.sinceSpecial = 0
    pity.sinceRare = 0
  } else if (rarity === 'rare') pity.sinceRare = 0
  s.capsule.pity[seriesId] = pity
  const duplicate = owns(s, pick.id)
  let shards = 0
  if (duplicate) {
    shards = cfg.shardsForDuplicate[rarity]
    s.wallet.shards += shards
  } else grant(s, pick.id)
  const res: PullResult = { requestId: env.uuid(), series: seriesId, item: pick.id, rarity, duplicate, shards, at: env.now }
  s.capsule.last = [res, ...s.capsule.last].slice(0, 10)
  return res
}

function finishReward(s: GameState, env: Env, t: RunTicket, v: RunVerdict) {
  const g = t.game
  const rec = s.records[g] ?? { best: 0, runs: 0 }
  if (v.finished) {
    rec.runs += 1
    bump(s, 'game_finished', 1, env)
    bump(s, 'game:' + g, 1, env)
  }
  let newBest = false
  if (v.valid && v.score > rec.best) {
    rec.best = v.score
    newBest = true
  }
  s.records[g] = rec
  let coins = 0
  let note = v.note
  let affection = 0
  if (v.finished && v.valid) {
    // Chơi cùng pet: vui vẻ tăng, thân thiết tăng nhẹ (trong hạn mức).
    const n = needsAt(s.pet.needs, env.now)
    n.happiness = clamp100(n.happiness + ECONOMY.care.playGain)
    s.pet.needs = n
    affection = addAffection(s, env, ECONOMY.care.affectionPerGame)
    if (v.coins > 0) {
      const left = ECONOMY.games.dailyCoinCap - capUsed(s, env, 'games:coins')
      coins = Math.max(0, Math.min(left, v.coins, ECONOMY.games.maxCoinsPerRun))
      if (coins < v.coins) note = coins === 0 ? 'dailyCap' : 'partialCap'
      if (coins > 0) {
        s.wallet.coins += coins
        capAdd(s, env, 'games:coins', coins)
      }
    }
  }
  return { score: v.score, valid: v.valid, finished: v.finished, coins, earned: v.coins, note, newBest, best: rec.best, affection }
}

export { RULES_VERSION }
