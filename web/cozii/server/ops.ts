// Các thao tác của máy chủ Cozii!. Luật chơi dùng CHÍNH bộ luật TypeScript của chế độ chơi trên máy (src/core/engine.ts),
// chạy trong giao dịch Postgres có khóa dòng tài khoản, nên online và offline không lệch luật.
import { randomInt, randomUUID } from 'node:crypto'
import type pg from 'pg'
import { apply, bump, GameError, newState, type Action, type Env } from '../src/core/engine'
import { buildSnapshot } from '../src/core/snapshot'
import { readyAt, type GameState, type RunTicket } from '../src/core/state'
import { dayKey, weekKey } from '../src/core/time'
import { replayCloudJump, validInputs, CJ } from '../src/games/cloudJump'
import { item as catalogItem } from '../src/content/catalog'
import { ECONOMY } from '../src/content/economy'
import { STICKERS, fnv1a } from '../src/content/town'
import { GAME_IDS, type GameId } from '../src/core/state'
import { q, tx } from './db'
import { HttpError, type AuthUser } from './auth'

const ALLOWED: Action['type'][] = [
  'onboard', 'setNames', 'storySeen', 'tutorial', 'tutorialHidden', 'place', 'theme', 'saveLayout', 'applyLayout', 'equip',
  'saveOutfit', 'applyOutfit', 'buyItem', 'buyStock', 'sell', 'cook', 'feed', 'freeMeal', 'clean', 'cuddle', 'plant', 'water',
  'harvest', 'buyPlot', 'freeSeeds', 'completeOrder', 'rerollOrder', 'claimChapter', 'claimDaily', 'startRun', 'finishRun',
  'buyTicket', 'openCapsule', 'exchangeShards', 'claimSeries', 'setTitle', 'photo', 'sharePreview', 'setPrivacy', 'visitNpc',
  'npcCompliment', 'npcHelpWater',
]

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
const CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'

function env(now = Date.now()): Env {
  return { now, rand: () => randomInt(0, 2 ** 31) / 2 ** 31, uuid: randomUUID }
}

/** Lọc tên hiển thị không phù hợp (danh sách ngắn, bổ sung bằng chức năng báo cáo). */
const BANNED = ['dit', 'địt', 'lồn', 'buồi', 'cặc', 'đụ', 'fuck', 'shit', 'bitch', 'nigger', 'đĩ']
export function badName(name: string): boolean {
  const n = name.toLowerCase().normalize('NFC').replace(/\s+/g, '')
  return BANNED.some(w => n.includes(w))
}

interface AccountRow {
  user_id: string
  state: GameState
  friend_code: string
  is_anonymous: boolean
}

function newCode(): string {
  let s = ''
  for (let i = 0; i < 8; i++) s += CODE_CHARS[randomInt(0, CODE_CHARS.length)]
  return s
}

function uniqueItems(s: GameState): number {
  return s.owned.filter(id => {
    const it = catalogItem(id)
    return it && it.source !== 'starter'
  }).length
}

/** Nạp (và khóa) tài khoản; tạo mới nếu chưa có. */
async function loadAccount(c: pg.PoolClient, user: AuthUser, lock: boolean): Promise<AccountRow> {
  const rows = await q<AccountRow>(c, `select user_id, state, friend_code, is_anonymous from cozii.accounts where user_id = $1 ${lock ? 'for update' : ''}`, [user.id])
  if (rows[0]) {
    if (rows[0].is_anonymous !== user.isAnonymous) {
      await c.query('update cozii.accounts set is_anonymous = $2 where user_id = $1', [user.id, user.isAnonymous])
      rows[0].is_anonymous = user.isAnonymous
    }
    return rows[0]
  }
  const now = Date.now()
  const state = newState(user.id, now, env(now), 'online')
  for (let attempt = 0; attempt < 6; attempt++) {
    const code = newCode()
    const ins = await q<AccountRow>(
      c,
      `insert into cozii.accounts (user_id, state, friend_code, is_anonymous) values ($1, $2, $3, $4)
       on conflict do nothing returning user_id, state, friend_code, is_anonymous`,
      [user.id, state, code, user.isAnonymous],
    )
    if (ins[0]) {
      await c.query('insert into cozii.homes (user_id) values ($1) on conflict do nothing', [user.id])
      if (lock) await c.query('select 1 from cozii.accounts where user_id = $1 for update', [user.id])
      return ins[0]
    }
    // Có thể là trùng mã bạn bè hoặc một tab khác vừa tạo xong tài khoản.
    const again = await q<AccountRow>(c, `select user_id, state, friend_code, is_anonymous from cozii.accounts where user_id = $1 ${lock ? 'for update' : ''}`, [user.id])
    if (again[0]) return again[0]
  }
  throw new HttpError(500, 'code', 'Không tạo được mã bạn bè. Thử lại nhé.')
}

function present(row: AccountRow, s: GameState, now: number): GameState {
  s.mode = 'online'
  s.serverNow = now
  s.profile.id = row.user_id
  s.profile.friendCode = row.friend_code
  s.profile.isAnonymous = row.is_anonymous
  return s
}

async function save(c: pg.PoolClient, uid: string, s: GameState) {
  await c.query(
    `update cozii.accounts set state = $2, display_name = $3, pet_name = $4, species = $5, title = $6, unique_items = $7,
       version = version + 1, updated_at = now() where user_id = $1`,
    [uid, s, s.profile.name, s.pet.name, s.pet.species, s.profile.title, uniqueItems(s)],
  )
}

export function weeklySeed(week: string): number {
  return (fnv1a('cozii-week-' + week) % 2147483646) + 1
}

// ---------------- Trạng thái ----------------

export async function opState(user: AuthUser) {
  return tx(async c => {
    const row = await loadAccount(c, user, false)
    return present(row, row.state, Date.now())
  })
}

// ---------------- Thao tác game ----------------

export async function opAct(user: AuthUser, body: { action?: Action; requestId?: string }) {
  const a = body.action
  const requestId = body.requestId
  if (!a || typeof a !== 'object' || !ALLOWED.includes(a.type)) throw new HttpError(400, 'action', 'Thao tác không hợp lệ.')
  if (!requestId || !UUID.test(requestId)) throw new HttpError(400, 'request', 'Thiếu mã yêu cầu.')
  if (JSON.stringify(a).length > 200_000) throw new HttpError(413, 'size', 'Dữ liệu quá lớn.')
  return tx(async c => {
    const row = await loadAccount(c, user, true)
    const prior = await q<{ response: { result: unknown } }>(c, 'select response from cozii.tx_log where user_id = $1 and request_id = $2', [user.id, requestId])
    const now = Date.now()
    if (prior[0]) return { state: present(row, row.state, now), result: prior[0].response.result, replayed: true }
    const recent = await q<{ n: string }>(c, `select count(*) n from cozii.tx_log where user_id = $1 and created_at > now() - interval '10 seconds'`, [user.id])
    if (Number(recent[0].n) > 40) throw new HttpError(429, 'rate', 'Bạn thao tác nhanh quá, nghỉ một chút nhé.')

    const s = row.state
    const e = env(now)
    if ((a.type === 'onboard' && (badName(a.playerName) || badName(a.petName))) || (a.type === 'setNames' && ((a.playerName && badName(a.playerName)) || (a.petName && badName(a.petName))))) {
      throw new HttpError(400, 'name', 'Tên này không phù hợp. Chọn tên khác nhé.')
    }

    // Lượt Nhảy Mây xếp hạng: máy chủ chạy lại toàn bộ từ seed + nhật ký điều khiển, dùng kết quả của máy chủ.
    let ticket: RunTicket | undefined
    let verified = false
    let mismatch = false
    if (a.type === 'finishRun') {
      ticket = s.runs.find(r => r.id === a.run)
      if (ticket?.ranked && a.result?.game === 'cloudJump' && a.result.completed) {
        const inputs = a.result.inputs
        if (!validInputs(inputs)) {
          a.result = { ...a.result, completed: true, meters: 1_000_000, stars: 0 } // sẽ bị coi là phi lý
        } else {
          const elapsed = (now - ticket.startedAt) / 1000
          const r = replayCloudJump(ticket.seed, inputs, Math.min(CJ.MAX_TICKS, Math.ceil((elapsed + 10) * 60)))
          verified = r.over && r.ticks / 60 <= elapsed + 10
          mismatch = r.meters !== a.result.meters || r.stars !== a.result.stars
          a.result = { ...a.result, meters: r.meters, stars: r.stars, completed: r.over }
        }
      }
    }

    let result
    try {
      result = apply(s, a, e) as Record<string, unknown> | undefined
    } catch (err) {
      if (err instanceof GameError) throw new HttpError(400, err.code, err.message)
      throw err
    }

    if (a.type === 'startRun') {
      const t = (result as { run: RunTicket }).run
      t.ranked = t.game === 'cloudJump'
      if (t.weekly && t.game === 'cloudJump') t.seed = weeklySeed(weekKey(now))
      const inState = s.runs.find(r => r.id === t.id)
      if (inState) Object.assign(inState, t)
    }
    if (a.type === 'finishRun' && ticket?.ranked && result) {
      const r = result as { valid: boolean; finished: boolean; score: number }
      result.verified = verified
      if (mismatch) result.note = 'mismatch'
      if (verified && r.valid && r.finished && a.result.game === 'cloudJump') {
        await c.query(
          `insert into cozii.scores (run_id, user_id, game, week, weekly, score, meters, stars, verified)
           values ($1, $2, 'cloudJump', $3, $4, $5, $6, $7, true) on conflict (run_id) do nothing`,
          [ticket.id, user.id, weekKey(ticket.startedAt), ticket.weekly, r.score, a.result.meters, a.result.stars],
        )
      }
    }
    if (a.type === 'setPrivacy' && a.visibility) {
      await c.query('insert into cozii.homes (user_id, visibility) values ($1, $2) on conflict (user_id) do update set visibility = excluded.visibility', [user.id, a.visibility])
    }

    await save(c, user.id, s)
    await c.query('insert into cozii.tx_log (user_id, request_id, op, response) values ($1, $2, $3, $4)', [user.id, requestId, a.type, { result: result ?? null }])
    if (randomInt(0, 50) === 0) await c.query(`delete from cozii.tx_log where user_id = $1 and created_at < now() - interval '14 days'`, [user.id])
    return { state: present(row, s, now), result: result ?? null }
  })
}

// ---------------- Bạn bè ----------------

interface PersonRow { user_id: string; display_name: string; pet_name: string; species: string; title: string | null; friend_code: string }
const person = (r: PersonRow) => ({ id: r.user_id, name: r.display_name || 'Bạn nhỏ', petName: r.pet_name, species: r.species, title: r.title, friendCode: r.friend_code })
const PERSON_COLS = 'a.user_id, a.display_name, a.pet_name, a.species, a.title, a.friend_code'

async function blockedEither(c: pg.PoolClient, a: string, b: string): Promise<boolean> {
  const r = await q(c, 'select 1 from cozii.blocks where (blocker = $1 and blocked = $2) or (blocker = $2 and blocked = $1)', [a, b])
  return r.length > 0
}
async function areFriends(c: pg.PoolClient, a: string, b: string): Promise<boolean> {
  const r = await q(c, 'select 1 from cozii.friendships where user_id = $1 and friend_id = $2', [a, b])
  return r.length > 0
}

function checkUuid(id: unknown): string {
  if (typeof id !== 'string' || !UUID.test(id)) throw new HttpError(400, 'id', 'Mã người chơi không hợp lệ.')
  return id
}

export async function opFindByCode(user: AuthUser, code: string) {
  return tx(async c => {
    await loadAccount(c, user, false)
    const rows = await q<PersonRow>(c, `select ${PERSON_COLS} from cozii.accounts a where a.friend_code = $1 and a.user_id <> $2`, [String(code ?? '').toUpperCase().trim(), user.id])
    if (!rows[0] || (await blockedEither(c, user.id, rows[0].user_id))) return null
    return person(rows[0])
  })
}

export async function opSendRequest(user: AuthUser, code: string) {
  return tx(async c => {
    await loadAccount(c, user, false)
    const target = (await q<PersonRow>(c, `select ${PERSON_COLS} from cozii.accounts a where a.friend_code = $1`, [String(code ?? '').toUpperCase().trim()]))[0]
    if (!target) throw new HttpError(404, 'code', 'Không tìm thấy mã bạn bè này.')
    if (target.user_id === user.id) throw new HttpError(400, 'self', 'Đây là mã của chính bạn.')
    if (await blockedEither(c, user.id, target.user_id)) throw new HttpError(404, 'code', 'Không tìm thấy mã bạn bè này.')
    if (await areFriends(c, user.id, target.user_id)) throw new HttpError(400, 'friends', 'Hai bạn đã là bạn bè.')
    const reverse = await q<{ id: string }>(c, 'select id from cozii.friend_requests where from_id = $1 and to_id = $2', [target.user_id, user.id])
    if (reverse[0]) {
      await makeFriends(c, user.id, target.user_id)
      return { accepted: true }
    }
    const mine = await q<{ n: string }>(c, 'select count(*) n from cozii.friend_requests where from_id = $1', [user.id])
    if (Number(mine[0].n) >= ECONOMY.social.maxPendingRequests) throw new HttpError(400, 'cap', 'Bạn đang chờ quá nhiều lời mời.')
    await c.query('insert into cozii.friend_requests (from_id, to_id) values ($1, $2) on conflict do nothing', [user.id, target.user_id])
    return { accepted: false }
  })
}

async function makeFriends(c: pg.PoolClient, a: string, b: string) {
  const count = await q<{ n: string }>(c, 'select count(*) n from cozii.friendships where user_id = $1 or user_id = $2 group by user_id order by 1 desc limit 1', [a, b])
  if (count[0] && Number(count[0].n) >= ECONOMY.social.maxFriends) throw new HttpError(400, 'cap', `Mỗi người tối đa ${ECONOMY.social.maxFriends} bạn.`)
  await c.query('insert into cozii.friendships (user_id, friend_id) values ($1, $2), ($2, $1) on conflict do nothing', [a, b])
  await c.query('delete from cozii.friend_requests where (from_id = $1 and to_id = $2) or (from_id = $2 and to_id = $1)', [a, b])
}

export async function opRespondRequest(user: AuthUser, id: string, accept: boolean) {
  return tx(async c => {
    const r = (await q<{ from_id: string }>(c, 'select from_id from cozii.friend_requests where id = $1 and to_id = $2 for update', [checkUuid(id), user.id]))[0]
    if (!r) throw new HttpError(404, 'request', 'Lời mời không còn nữa.')
    if (accept && !(await blockedEither(c, user.id, r.from_id))) await makeFriends(c, user.id, r.from_id)
    else await c.query('delete from cozii.friend_requests where id = $1', [id])
    return { ok: true }
  })
}

export async function opListFriends(user: AuthUser) {
  return tx(async c => {
    await loadAccount(c, user, false)
    const rows = await q<PersonRow & { created_at: Date }>(c, `select ${PERSON_COLS}, f.created_at from cozii.friendships f join cozii.accounts a on a.user_id = f.friend_id where f.user_id = $1 order by a.display_name`, [user.id])
    return rows.map(r => ({ ...person(r), since: r.created_at.toISOString() }))
  })
}

export async function opListRequests(user: AuthUser) {
  return tx(async c => {
    const inc = await q<PersonRow & { id: string; created_at: Date }>(c, `select r.id, r.created_at, ${PERSON_COLS} from cozii.friend_requests r join cozii.accounts a on a.user_id = r.from_id where r.to_id = $1 order by r.created_at desc limit 50`, [user.id])
    const out = await q<PersonRow & { id: string; created_at: Date }>(c, `select r.id, r.created_at, ${PERSON_COLS} from cozii.friend_requests r join cozii.accounts a on a.user_id = r.to_id where r.from_id = $1 order by r.created_at desc limit 50`, [user.id])
    const map = (r: PersonRow & { id: string; created_at: Date }) => ({ id: r.id, from: person(r), createdAt: r.created_at.toISOString() })
    return { incoming: inc.map(map), outgoing: out.map(map) }
  })
}

export async function opRemoveFriend(user: AuthUser, other: string) {
  return tx(async c => {
    await c.query('delete from cozii.friendships where (user_id = $1 and friend_id = $2) or (user_id = $2 and friend_id = $1)', [user.id, checkUuid(other)])
    return { ok: true }
  })
}

export async function opBlock(user: AuthUser, other: string) {
  return tx(async c => {
    checkUuid(other)
    if (other === user.id) throw new HttpError(400, 'self', 'Không thể tự chặn mình.')
    const exists = await q(c, 'select 1 from cozii.accounts where user_id = $1', [other])
    if (!exists.length) throw new HttpError(404, 'user', 'Không tìm thấy người chơi.')
    await c.query('insert into cozii.blocks (blocker, blocked) values ($1, $2) on conflict do nothing', [user.id, other])
    await c.query('delete from cozii.friendships where (user_id = $1 and friend_id = $2) or (user_id = $2 and friend_id = $1)', [user.id, other])
    await c.query('delete from cozii.friend_requests where (from_id = $1 and to_id = $2) or (from_id = $2 and to_id = $1)', [user.id, other])
    return { ok: true }
  })
}

export async function opUnblock(user: AuthUser, other: string) {
  return tx(async c => {
    await c.query('delete from cozii.blocks where blocker = $1 and blocked = $2', [user.id, checkUuid(other)])
    return { ok: true }
  })
}

export async function opListBlocked(user: AuthUser) {
  return tx(async c => (await q<PersonRow>(c, `select ${PERSON_COLS} from cozii.blocks b join cozii.accounts a on a.user_id = b.blocked where b.blocker = $1`, [user.id])).map(person))
}

export async function opReport(user: AuthUser, other: string, reason: string, details: string) {
  return tx(async c => {
    checkUuid(other)
    if (!['name', 'spam', 'other'].includes(reason)) throw new HttpError(400, 'reason', 'Lý do không hợp lệ.')
    const today = await q<{ n: string }>(c, `select count(*) n from cozii.reports where reporter = $1 and created_at > now() - interval '1 day'`, [user.id])
    if (Number(today[0].n) >= 10) throw new HttpError(429, 'cap', 'Hôm nay bạn đã gửi nhiều báo cáo rồi.')
    await c.query('insert into cozii.reports (reporter, target, reason, details) values ($1, $2, $3, $4)', [user.id, other, reason, String(details ?? '').slice(0, 300)])
    return { ok: true }
  })
}

// ---------------- Nhà & thăm nhà ----------------

export async function opPublish(user: AuthUser) {
  return tx(async c => {
    const row = await loadAccount(c, user, true)
    const s = row.state
    if (!s.profile.onboarded) throw new HttpError(400, 'onboard', 'Hãy chọn bạn nhỏ trước.')
    const now = Date.now()
    const snap = buildSnapshot(s, now)
    snap.garden = s.social.shareGarden ? [] : null // vườn lấy trực tiếp lúc thăm (luôn mới nhất)
    s.social.publishedAt = now
    await c.query(
      `insert into cozii.homes (user_id, visibility, snapshot, published_at) values ($1, $2, $3, now())
       on conflict (user_id) do update set visibility = excluded.visibility, snapshot = excluded.snapshot, published_at = now()`,
      [user.id, s.social.visibility, snap],
    )
    await save(c, user.id, s)
    return { publishedAt: new Date(now).toISOString() }
  })
}

async function canView(c: pg.PoolClient, viewer: string, host: string): Promise<{ ok: boolean; reason?: string; snapshot?: unknown; friends: boolean }> {
  const friends = await areFriends(c, viewer, host)
  if (viewer === host) return { ok: true, friends }
  if (await blockedEither(c, viewer, host)) return { ok: false, reason: 'Không xem được ngôi nhà này.', friends }
  const h = (await q<{ visibility: string; snapshot: unknown }>(c, 'select visibility, snapshot from cozii.homes where user_id = $1', [host]))[0]
  if (!h || !h.snapshot) return { ok: false, reason: 'Ngôi nhà này chưa được đăng.', friends }
  if (h.visibility === 'private') return { ok: false, reason: 'Chủ nhà đang để chế độ riêng tư.', friends }
  if (h.visibility === 'friends' && !friends) return { ok: false, reason: 'Chủ nhà chỉ chia sẻ với bạn bè.', friends }
  return { ok: true, snapshot: h.snapshot, friends }
}

function liveGarden(s: GameState, now: number) {
  if (!s.social.shareGarden) return null
  return s.farm.plots.filter(p => p.crop && p.idx < s.farm.unlocked).map(p => ({
    idx: p.idx, crop: p.crop!, helps: p.helps,
    progress: Math.min(1, Math.max(0, (now - p.plantedAt) / Math.max(1, readyAt(p) - p.plantedAt))),
  }))
}

export async function opVisit(user: AuthUser, hostId: string) {
  checkUuid(hostId)
  return tx(async c => {
    const me = await loadAccount(c, user, true)
    const v = await canView(c, user.id, hostId)
    if (!v.ok) throw new HttpError(403, 'private', v.reason!)
    const host = (await q<AccountRow & PersonRow>(c, `select a.user_id, a.state, a.friend_code, a.is_anonymous, a.display_name, a.pet_name, a.species, a.title from cozii.accounts a where a.user_id = $1`, [hostId]))[0]
    if (!host) throw new HttpError(404, 'user', 'Không tìm thấy người chơi.')
    const now = Date.now()
    const day = dayKey(now)
    let snapshot = v.snapshot as ReturnType<typeof buildSnapshot> | undefined
    if (!snapshot && hostId === user.id) snapshot = buildSnapshot(me.state, now)
    snapshot = { ...snapshot!, garden: liveGarden(host.state, now) }
    let coins = 0
    if (hostId !== user.id) {
      const ins = await q(c, 'insert into cozii.visits (visitor, host, day) values ($1, $2, $3) on conflict do nothing returning 1', [user.id, hostId, day])
      const s = me.state
      if (ins.length) {
        const rewarded = await q<{ n: string }>(c, 'select count(*) n from cozii.visits where visitor = $1 and day = $2 and rewarded', [user.id, day])
        if (Number(rewarded[0].n) < ECONOMY.social.maxRewardedVisitsPerDay) {
          coins = ECONOMY.social.visitCoins
          s.wallet.coins += coins
          await c.query('update cozii.visits set rewarded = true where visitor = $1 and host = $2 and day = $3', [user.id, hostId, day])
        }
        bump(s, 'visit', 1, env(now))
      }
      s.counters['home_visited:' + hostId] = 1
      await save(c, user.id, s)
    }
    const comp = (await q<{ sticker: string }>(c, 'select sticker from cozii.compliments where visitor = $1 and host = $2 and day = $3', [user.id, hostId, day]))[0]
    const helped = await q<{ plot: number; planted_at: string }>(c, 'select plot, planted_at from cozii.help_waters where helper = $1 and host = $2', [user.id, hostId])
    const helpedPlots = host.state.farm.plots.filter(p => p.crop && helped.some(h => h.plot === p.idx && Number(h.planted_at) === p.plantedAt)).map(p => p.idx)
    const usedToday = await q<{ n: string }>(c, 'select count(*) n from cozii.help_waters where helper = $1 and day = $2', [user.id, day])
    return {
      snapshot,
      host: person(host),
      isFriend: v.friends,
      coins,
      complimentedToday: comp?.sticker ?? null,
      helpedPlots,
      helpsLeftToday: Math.max(0, ECONOMY.social.maxHelpWaterPerDay - Number(usedToday[0].n)),
    }
  })
}

export async function opCompliment(user: AuthUser, hostId: string, sticker: string) {
  checkUuid(hostId)
  if (!STICKERS.some(s => s.id === sticker)) throw new HttpError(400, 'sticker', 'Lời khen không hợp lệ.')
  if (hostId === user.id) throw new HttpError(400, 'self', 'Không tự khen nhà mình được.')
  return tx(async c => {
    const me = await loadAccount(c, user, true)
    const v = await canView(c, user.id, hostId)
    if (!v.ok) throw new HttpError(403, 'private', v.reason!)
    const now = Date.now()
    const day = dayKey(now)
    const sent = await q<{ n: string }>(c, 'select count(*) n from cozii.compliments where visitor = $1 and day = $2', [user.id, day])
    if (Number(sent[0].n) >= ECONOMY.social.maxComplimentsPerDay) throw new HttpError(429, 'cap', 'Hôm nay bạn đã gửi đủ lời khen rồi.')
    const ins = await q(c, 'insert into cozii.compliments (visitor, host, day, sticker) values ($1, $2, $3, $4) on conflict do nothing returning 1', [user.id, hostId, day, sticker])
    if (!ins.length) throw new HttpError(400, 'done', 'Hôm nay bạn đã khen nhà này rồi.')
    bump(me.state, 'compliment', 1, env(now))
    await save(c, user.id, me.state)
    return { ok: true }
  })
}

/** Tưới giúp: chỉ bạn bè, có hạn mức, khóa cả hai tài khoản theo thứ tự cố định để không kẹt khi hai người cùng tưới. */
export async function opHelpWater(user: AuthUser, hostId: string, plot: number, requestId: string) {
  checkUuid(hostId)
  if (!UUID.test(requestId ?? '')) throw new HttpError(400, 'request', 'Thiếu mã yêu cầu.')
  if (!Number.isInteger(plot) || plot < 0 || plot > 11) throw new HttpError(400, 'plot', 'Ô đất không hợp lệ.')
  if (hostId === user.id) throw new HttpError(400, 'self', 'Đây là vườn của bạn, hãy tưới ở Vườn rau.')
  return tx(async c => {
    const [first, second] = [user.id, hostId].sort()
    await q(c, 'select 1 from cozii.accounts where user_id = $1 for update', [first])
    await q(c, 'select 1 from cozii.accounts where user_id = $1 for update', [second])
    const me = await loadAccount(c, user, true)
    const prior = await q<{ response: { result: unknown } }>(c, 'select response from cozii.tx_log where user_id = $1 and request_id = $2', [user.id, requestId])
    if (prior[0]) return prior[0].response.result as { coins: number }
    if (await blockedEither(c, user.id, hostId)) throw new HttpError(403, 'blocked', 'Không tưới giúp được vườn này.')
    if (!(await areFriends(c, user.id, hostId))) throw new HttpError(403, 'friends', 'Chỉ bạn bè mới tưới giúp được.')
    const host = (await q<AccountRow>(c, 'select user_id, state, friend_code, is_anonymous from cozii.accounts where user_id = $1', [hostId]))[0]
    if (!host) throw new HttpError(404, 'user', 'Không tìm thấy người chơi.')
    const hs = host.state
    if (!hs.social.shareGarden) throw new HttpError(403, 'garden', 'Chủ nhà không chia sẻ vườn.')
    const now = Date.now()
    const day = dayKey(now)
    const p = hs.farm.plots[plot]
    if (!p || plot >= hs.farm.unlocked || !p.crop) throw new HttpError(400, 'empty', 'Ô này không có cây.')
    if (now >= readyAt(p)) throw new HttpError(400, 'ready', 'Cây đã chín rồi, không cần tưới.')
    if (p.helps >= ECONOMY.farm.maxHelpsPerCrop) throw new HttpError(400, 'cap', 'Cây này đã được bạn bè tưới đủ lượt.')
    const used = await q<{ n: string }>(c, 'select count(*) n from cozii.help_waters where helper = $1 and day = $2', [user.id, day])
    if (Number(used[0].n) >= ECONOMY.social.maxHelpWaterPerDay) throw new HttpError(429, 'cap', 'Hôm nay bạn đã tưới giúp đủ lượt.')
    const ins = await q(c, 'insert into cozii.help_waters (helper, host, plot, planted_at, day) values ($1, $2, $3, $4, $5) on conflict do nothing returning 1', [user.id, hostId, plot, p.plantedAt, day])
    if (!ins.length) throw new HttpError(400, 'done', 'Bạn đã tưới cây này rồi.')
    p.helps += 1
    p.cutPct = Math.min(ECONOMY.farm.maxCutPct, p.cutPct + ECONOMY.farm.helpWaterCutPct)
    await save(c, hostId, hs)
    const s = me.state
    s.wallet.coins += ECONOMY.social.helpWaterCoins
    bump(s, 'help_water', 1, env(now))
    await save(c, user.id, s)
    const result = { coins: ECONOMY.social.helpWaterCoins }
    await c.query('insert into cozii.tx_log (user_id, request_id, op, response) values ($1, $2, $3, $4)', [user.id, requestId, 'helpWater', { result }])
    return result
  })
}

export async function opDiscover(user: AuthUser, cursor: string | null) {
  return tx(async c => {
    const before = cursor && !Number.isNaN(Date.parse(cursor)) ? new Date(cursor) : new Date(Date.now() + 60_000)
    const rows = await q<PersonRow & { published_at: Date }>(
      c,
      `select ${PERSON_COLS}, h.published_at from cozii.homes h join cozii.accounts a on a.user_id = h.user_id
       where h.visibility = 'public' and h.snapshot is not null and h.published_at < $2 and h.user_id <> $1
         and not exists (select 1 from cozii.blocks b where (b.blocker = $1 and b.blocked = h.user_id) or (b.blocker = h.user_id and b.blocked = $1))
       order by h.published_at desc limit 21`,
      [user.id, before],
    )
    const page = rows.slice(0, 20)
    return { homes: page.map(person), next: rows.length > 20 ? page[page.length - 1].published_at.toISOString() : null }
  })
}

export async function opInbox(user: AuthUser) {
  return tx(async c => {
    const comps = await q<{ user_id: string; display_name: string; sticker: string; created_at: Date }>(
      c,
      `select a.user_id, a.display_name, x.sticker, x.created_at from cozii.compliments x join cozii.accounts a on a.user_id = x.visitor
       where x.host = $1 and not exists (select 1 from cozii.blocks b where b.blocker = $1 and b.blocked = x.visitor)
       order by x.created_at desc limit 40`,
      [user.id],
    )
    const helps = await q<{ user_id: string; display_name: string; created_at: Date }>(
      c,
      `select a.user_id, a.display_name, x.created_at from cozii.help_waters x join cozii.accounts a on a.user_id = x.helper
       where x.host = $1 and not exists (select 1 from cozii.blocks b where b.blocker = $1 and b.blocked = x.helper)
       order by x.created_at desc limit 20`,
      [user.id],
    )
    return [
      ...comps.map(r => ({ kind: 'compliment' as const, from: { id: r.user_id, name: r.display_name }, sticker: r.sticker, at: r.created_at.toISOString() })),
      ...helps.map(r => ({ kind: 'help_water' as const, from: { id: r.user_id, name: r.display_name }, at: r.created_at.toISOString() })),
    ].sort((a, b) => b.at.localeCompare(a.at))
  })
}

// ---------------- Bảng xếp hạng ----------------

interface BoardRow { user_id: string; display_name: string; pet_name: string; species: string; score: number; rank: string }

export async function opLeaderboard(user: AuthUser, game: string, scope: string, weekArg: string | null) {
  if (!GAME_IDS.includes(game as GameId) || game !== 'cloudJump') throw new HttpError(400, 'game', 'Trò này chưa có bảng xếp hạng.')
  if (!['all', 'weekly', 'friends'].includes(scope)) throw new HttpError(400, 'scope', 'Phạm vi không hợp lệ.')
  const week = weekArg && /^\d{4}-W\d{2}$/.test(weekArg) ? weekArg : weekKey(Date.now())
  return tx(async c => {
    const where = scope === 'weekly' ? `s.weekly and s.week = $2` : `true`
    const who = scope === 'friends'
      ? `and (s.user_id = $1 or s.user_id in (select friend_id from cozii.friendships where user_id = $1))`
      : `and not a.is_anonymous`
    const sql = `
      with best as (
        select s.user_id, max(s.score) score from cozii.scores s join cozii.accounts a on a.user_id = s.user_id
        where s.game = 'cloudJump' and s.verified and ${where} ${who}
          and not exists (select 1 from cozii.blocks b where (b.blocker = $1 and b.blocked = s.user_id) or (b.blocker = s.user_id and b.blocked = $1))
        group by s.user_id
      ), ranked as (
        select b.user_id, b.score, a.display_name, a.pet_name, a.species, rank() over (order by b.score desc) as rank
        from best b join cozii.accounts a on a.user_id = b.user_id
      )
      select * from ranked order by rank, display_name limit 50`
    const rows = await q<BoardRow>(c, sql, [user.id, week])
    const map = (r: BoardRow) => ({ rank: Number(r.rank), userId: r.user_id, name: r.display_name || 'Bạn nhỏ', petName: r.pet_name, species: r.species, score: r.score, me: r.user_id === user.id })
    let me = rows.find(r => r.user_id === user.id)
    if (!me) {
      const all = await q<BoardRow>(c, sql.replace('limit 50', ''), [user.id, week])
      me = all.find(r => r.user_id === user.id)
    }
    return { rows: rows.map(map), me: me ? map(me) : null, week }
  })
}

export async function opCollectors(user: AuthUser) {
  return tx(async c => {
    const sql = `select a.user_id, a.display_name, a.pet_name, a.species, a.unique_items score, rank() over (order by a.unique_items desc) rank
      from cozii.accounts a where not a.is_anonymous and a.unique_items > 0
        and not exists (select 1 from cozii.blocks b where (b.blocker = $1 and b.blocked = a.user_id) or (b.blocker = a.user_id and b.blocked = $1))`
    const rows = await q<BoardRow>(c, sql + ' order by rank, a.display_name limit 50', [user.id])
    const map = (r: BoardRow) => ({ rank: Number(r.rank), userId: r.user_id, name: r.display_name || 'Bạn nhỏ', petName: r.pet_name, species: r.species, score: Number(r.score), me: r.user_id === user.id })
    const mine = (await q<BoardRow>(c, `select * from (${sql}) x where x.user_id = $1`, [user.id]))[0]
    return { rows: rows.map(map), me: mine ? map(mine) : null }
  })
}

/** Trao huy hiệu cho các tuần đã kết thúc (8 tuần gần nhất). Gọi nhiều lần cũng chỉ trao một lần. */
export async function opClaimBadges(user: AuthUser) {
  return tx(async c => {
    const me = await loadAccount(c, user, true)
    if (me.is_anonymous) throw new HttpError(403, 'anon', 'Gắn email cho tài khoản để nhận huy hiệu xếp hạng.')
    const current = weekKey(Date.now())
    const weeks = await q<{ week: string }>(c, `select distinct week from cozii.scores where user_id = $1 and weekly and verified and week < $2 order by week desc limit 8`, [user.id, current])
    const got: string[] = []
    for (const { week } of weeks) {
      const r = (await q<{ rank: string }>(
        c,
        `select rank from (select s.user_id, rank() over (order by max(s.score) desc) rank from cozii.scores s join cozii.accounts a on a.user_id = s.user_id
          where s.game = 'cloudJump' and s.weekly and s.verified and s.week = $2 and not a.is_anonymous group by s.user_id) x where x.user_id = $1`,
        [user.id, week],
      ))[0]
      if (!r) continue
      const rank = Number(r.rank)
      const badge = rank === 1 ? `Cúp vàng ${week}` : rank <= 3 ? `Top 3 ${week}` : rank <= 10 ? `Top 10 ${week}` : null
      if (badge && !me.state.badges.includes(badge)) {
        me.state.badges.push(badge)
        got.push(badge)
      }
    }
    if (got.length) await save(c, user.id, me.state)
    return { badges: got }
  })
}
