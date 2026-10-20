import { beforeAll, afterAll, describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
import { randomUUID } from 'node:crypto'
import pg from 'pg'

const URL = process.env.TEST_DATABASE_URL
const d = URL ? describe : describe.skip

let pool: pg.Pool
let api: typeof import('../../server/api')
let db: typeof import('../../server/db')

async function user(anon = false) {
  const id = randomUUID()
  await pool.query('insert into auth.users (id, is_anonymous) values ($1, $2)', [id, anon])
  return { id, email: anon ? null : 'x@y.z', isAnonymous: anon }
}

async function call(u: { id: string; email: string | null; isAnonymous: boolean }, body: Record<string, unknown>) {
  return api.dispatch(u, body) as Promise<any>
}
async function act(u: any, action: any, requestId = randomUUID()) {
  return call(u, { op: 'act', action, requestId })
}
async function onboard(u: any, name = 'Mai') {
  await call(u, { op: 'state' })
  return act(u, { type: 'onboard', playerName: name, petName: 'Bông', species: 'capybara', fur: 'cocoa' })
}
async function setState(uid: string, fn: (s: any) => void) {
  const r = await pool.query('select state from cozii.accounts where user_id = $1', [uid])
  const s = r.rows[0].state
  fn(s)
  await pool.query('update cozii.accounts set state = $2 where user_id = $1', [uid, s])
}

d('máy chủ Cozii (Postgres thật)', () => {
  beforeAll(async () => {
    process.env.COZII_DEV_AUTH = '1'
    process.env.DATABASE_URL = URL
    pool = new pg.Pool({ connectionString: URL, max: 8 })
    await pool.query('drop schema if exists cozii cascade; drop schema if exists auth cascade;')
    await pool.query(readFileSync('supabase/tests/bootstrap-local.sql', 'utf8'))
    await pool.query(readFileSync('supabase/migrations/20261020000000_cozii_schema.sql', 'utf8'))
    db = await import('../../server/db')
    db.setPool(pool)
    api = await import('../../server/api')
  })
  afterAll(async () => {
    await pool?.end()
  })

  it('tạo tài khoản khi gọi lần đầu, có mã bạn bè hợp lệ', async () => {
    const u = await user()
    const s = await call(u, { op: 'state' })
    expect(s.mode).toBe('online')
    expect(s.profile.friendCode).toMatch(/^[A-HJ-NP-Z2-9]{8}$/)
    expect(s.wallet.coins).toBe(120)
  })

  it('thao tác lặp lại cùng mã yêu cầu chỉ xử lý một lần (mất mạng rồi gửi lại)', async () => {
    const u = await user()
    await onboard(u)
    const rid = randomUUID()
    const a = await act(u, { type: 'buyItem', item: 'plant.monstera' }, rid)
    const b = await act(u, { type: 'buyItem', item: 'plant.monstera' }, rid)
    expect(a.state.wallet.coins).toBe(15)
    expect(b.state.wallet.coins).toBe(15)
    expect(b.replayed).toBe(true)
  })

  it('hai tab cùng mua: không bao giờ âm xu, không nhân đôi đồ', async () => {
    const u = await user()
    await onboard(u)
    // 120 xu: mua hai món 105 xu cùng lúc → chỉ một món thành công
    const rs = await Promise.allSettled([
      act(u, { type: 'buyItem', item: 'plant.monstera' }),
      act(u, { type: 'buyItem', item: 'wall.poster' }),
      act(u, { type: 'buyItem', item: 'plant.monstera' }),
    ])
    const ok = rs.filter(r => r.status === 'fulfilled')
    expect(ok.length).toBe(1)
    const s = await call(u, { op: 'state' })
    expect(s.wallet.coins).toBe(15)
    expect(s.owned.filter((x: string) => x === 'plant.monstera' || x === 'wall.poster')).toHaveLength(1)
  })

  it('thu hoạch hai lần cùng lúc chỉ được một lần; chưa chín thì máy chủ từ chối', async () => {
    const u = await user()
    await onboard(u)
    await act(u, { type: 'plant', plot: 0, seed: 'seed.radish' })
    await expect(act(u, { type: 'harvest', plot: 0 })).rejects.toThrow(/chưa chín/)
    await setState(u.id, s => { s.farm.plots[0].plantedAt -= 200_000 })
    const rs = await Promise.allSettled([act(u, { type: 'harvest', plot: 0 }), act(u, { type: 'harvest', plot: 0 })])
    expect(rs.filter(r => r.status === 'fulfilled')).toHaveLength(1)
    const s = await call(u, { op: 'state' })
    expect(s.stock['crop.radish']).toBe(1)
  })

  it('từ chối thao tác lạ và không có cách nào tự ghi xu', async () => {
    const u = await user()
    await onboard(u)
    await expect(act(u, { type: 'setCoins', coins: 99999 })).rejects.toThrow(/không hợp lệ/)
    await expect(call(u, { op: 'setCoins' })).rejects.toThrow(/không tồn tại/)
    await expect(act(u, { type: 'buyStock', id: 'seed.radish', count: -50 })).rejects.toThrow()
    const s = await call(u, { op: 'state' })
    expect(s.wallet.coins).toBe(120)
  })

  it('ràng buộc CSDL chặn số dư âm kể cả khi luật bị lỗi', async () => {
    const u = await user()
    await onboard(u)
    await expect(setState(u.id, s => { s.wallet.coins = -1 })).rejects.toThrow(/wallet_non_negative/)
  })

  it('capsule: thử lại cùng mã trả đúng kết quả đã lưu', async () => {
    const u = await user()
    await onboard(u)
    const rid = randomUUID()
    const a = await act(u, { type: 'openCapsule', series: 'moon' }, rid)
    const b = await act(u, { type: 'openCapsule', series: 'moon' }, rid)
    expect(b.result.pull.item).toBe(a.result.pull.item)
    expect(b.state.wallet.tickets).toBe(0)
  })

  describe('bạn bè & thăm nhà', () => {
    it('kết bạn bằng mã, quyền riêng tư, chặn có hiệu lực ở máy chủ', async () => {
      const a = await user(), b = await user(), c = await user()
      await onboard(a, 'An'); await onboard(b, 'Bình'); await onboard(c, 'Chi')
      const sa = await call(a, { op: 'state' })
      // mặc định riêng tư: không ai xem được
      await call(a, { op: 'publish' })
      await expect(call(b, { op: 'visit', host: a.id })).rejects.toThrow(/riêng tư/)
      // bạn bè
      await act(a, { type: 'setPrivacy', visibility: 'friends' })
      await call(a, { op: 'publish' })
      await expect(call(b, { op: 'visit', host: a.id })).rejects.toThrow(/bạn bè/)
      await call(b, { op: 'sendRequest', code: sa.profile.friendCode })
      const reqs = await call(a, { op: 'listRequests' })
      expect(reqs.incoming).toHaveLength(1)
      await call(a, { op: 'respondRequest', id: reqs.incoming[0].id, accept: true })
      const v = await call(b, { op: 'visit', host: a.id })
      expect(v.isFriend).toBe(true)
      expect(v.coins).toBe(3)
      const again = await call(b, { op: 'visit', host: a.id })
      expect(again.coins).toBe(0) // tải lại cùng nhà không thưởng lặp
      // công khai: người lạ xem được
      await act(a, { type: 'setPrivacy', visibility: 'public' })
      await call(a, { op: 'publish' })
      await call(c, { op: 'visit', host: a.id })
      const disc = await call(c, { op: 'discover', cursor: null })
      expect(disc.homes.map((h: any) => h.id)).toContain(a.id)
      // chặn: không xem được nữa (kể cả gọi API trực tiếp), không còn trong khám phá
      await call(a, { op: 'block', other: c.id })
      await expect(call(c, { op: 'visit', host: a.id })).rejects.toThrow(/Không xem được/)
      const disc2 = await call(c, { op: 'discover', cursor: null })
      expect(disc2.homes.map((h: any) => h.id)).not.toContain(a.id)
      await expect(call(c, { op: 'sendRequest', code: sa.profile.friendCode })).rejects.toThrow(/Không tìm thấy/)
      await expect(call(c, { op: 'compliment', host: a.id, sticker: 'warm' })).rejects.toThrow()
      // chặn bạn bè → mất quan hệ bạn bè
      await call(a, { op: 'block', other: b.id })
      expect(await call(a, { op: 'listFriends' })).toHaveLength(0)
    })

    it('snapshot không lộ dữ liệu riêng', async () => {
      const a = await user(), b = await user()
      await onboard(a); await onboard(b)
      await act(a, { type: 'setPrivacy', visibility: 'public' })
      await call(a, { op: 'publish' })
      const v = await call(b, { op: 'visit', host: a.id })
      const keys = Object.keys(v.snapshot).sort()
      expect(keys).toEqual(['badges', 'garden', 'name', 'pet', 'publishedAt', 'rooms', 'showSources', 'title', 'v'].sort())
      const text = JSON.stringify({ snapshot: v.snapshot, host: v.host })
      for (const bad of ['wallet', 'coins', 'owned', 'stock', 'email', 'counters', 'capsule', 'ledger']) expect(text).not.toContain(`"${bad}"`)
      // tắt chia sẻ vườn → không có vườn
      await act(a, { type: 'setPrivacy', shareGarden: false })
      const v2 = await call(b, { op: 'visit', host: a.id })
      expect(v2.snapshot.garden).toBeNull()
    })

    it('lời khen một lần mỗi ngày; tưới giúp có hạn mức, an toàn khi nhiều người cùng tưới', async () => {
      const host = await user()
      await onboard(host)
      await act(host, { type: 'setPrivacy', visibility: 'friends' })
      await act(host, { type: 'buyStock', id: 'seed.strawberry', count: 1 })
      await act(host, { type: 'plant', plot: 0, seed: 'seed.strawberry' })
      await call(host, { op: 'publish' })
      const code = (await call(host, { op: 'state' })).profile.friendCode
      const friends = [await user(), await user(), await user(), await user()]
      for (const f of friends) {
        await onboard(f)
        await call(f, { op: 'sendRequest', code })
      }
      for (const r of (await call(host, { op: 'listRequests' })).incoming) await call(host, { op: 'respondRequest', id: r.id, accept: true })
      await call(friends[0], { op: 'compliment', host: host.id, sticker: 'cute' })
      await expect(call(friends[0], { op: 'compliment', host: host.id, sticker: 'warm' })).rejects.toThrow(/đã khen/)
      const rs = await Promise.allSettled(friends.map(f => call(f, { op: 'helpWater', host: host.id, plot: 0, requestId: randomUUID() })))
      expect(rs.filter(r => r.status === 'fulfilled')).toHaveLength(2)
      const hs = await call(host, { op: 'state' })
      expect(hs.farm.plots[0].helps).toBe(2)
      expect(hs.farm.plots[0].cutPct).toBe(20)
      // người lạ không tưới được
      const stranger = await user()
      await onboard(stranger)
      await expect(call(stranger, { op: 'helpWater', host: host.id, plot: 0, requestId: randomUUID() })).rejects.toThrow(/bạn bè/)
      const inbox = await call(host, { op: 'inbox' })
      expect(inbox.filter((m: any) => m.kind === 'compliment')).toHaveLength(1)
      expect(inbox.filter((m: any) => m.kind === 'help_water')).toHaveLength(2)
    })
  })

  describe('bảng xếp hạng Nhảy Mây', () => {
    it('máy chủ chạy lại lượt chơi; điểm khai gian bị thay bằng điểm thật; lượt nhanh hơn thời gian thực bị loại', async () => {
      const { playCloudJump } = await import('../bots')
      const u = await user()
      await onboard(u)
      const t = (await act(u, { type: 'startRun', game: 'cloudJump' })).result.run
      expect(t.ranked).toBe(true)
      const e = playCloudJump(t.seed, 60 * 90)
      expect(e.over || e.time >= 60 * 90).toBe(true)
      // giả lập đã chơi đủ thời gian thật
      await setState(u.id, s => { s.runs.find((r: any) => r.id === t.id).startedAt -= Math.ceil(e.time / 60) * 1000 + 2000 })
      const r = await act(u, { type: 'finishRun', run: t.id, result: { game: 'cloudJump', completed: true, meters: e.meters + 500, stars: e.stars, inputs: e.inputs } })
      expect(r.result.verified).toBe(e.over)
      expect(r.result.note).toBe('mismatch')
      expect(r.result.score).toBe(e.meters + e.stars * 3)
      // lượt nộp ngay (không đủ thời gian thật) → không xác minh, không lên bảng
      const t2 = (await act(u, { type: 'startRun', game: 'cloudJump' })).result.run
      const e2 = playCloudJump(t2.seed, 60 * 90)
      const r2 = await act(u, { type: 'finishRun', run: t2.id, result: { game: 'cloudJump', completed: true, meters: e2.meters, stars: e2.stars, inputs: e2.inputs } })
      expect(r2.result.verified).toBe(false)
      const rows = await pool.query('select count(*)::int n from cozii.scores where user_id = $1', [u.id])
      expect(rows.rows[0].n).toBe(e.over ? 1 : 0)
      // nộp lại cùng lượt không tạo điểm thứ hai
      await expect(act(u, { type: 'finishRun', run: t.id, result: { game: 'cloudJump', completed: true, meters: 1, stars: 0, inputs: [] } })).rejects.toThrow()
    })

    it('bảng chung bỏ qua tài khoản khách, bảng bạn bè có', async () => {
      const { playCloudJump } = await import('../bots')
      const member = await user(false), guest = await user(true)
      for (const u of [member, guest]) {
        await onboard(u)
        const t = (await act(u, { type: 'startRun', game: 'cloudJump', weekly: true })).result.run
        const e = playCloudJump(t.seed, 60 * 120)
        await setState(u.id, s => { s.runs.find((r: any) => r.id === t.id).startedAt -= Math.ceil(e.time / 60) * 1000 + 2000 })
        await act(u, { type: 'finishRun', run: t.id, result: { game: 'cloudJump', completed: true, meters: e.meters, stars: e.stars, inputs: e.inputs } })
      }
      const all = await call(member, { op: 'leaderboard', game: 'cloudJump', scope: 'weekly' })
      expect(all.rows.some((r: any) => r.userId === guest.id)).toBe(false)
      expect(all.me?.userId).toBe(member.id)
      // thử thách tuần: cùng seed cho mọi người
      const ta = (await act(member, { type: 'startRun', game: 'cloudJump', weekly: true })).result.run
      const tb = (await act(guest, { type: 'startRun', game: 'cloudJump', weekly: true })).result.run
      expect(ta.seed).toBe(tb.seed)
    })
  })
})
