// Chế độ online: Supabase Auth để đăng nhập; mọi thao tác đi qua hàm máy chủ /api/cozii (server/), nơi luật chơi chạy
// trong một giao dịch Postgres có khóa dòng và khóa chống trùng. Client không bao giờ ghi trực tiếp vào cơ sở dữ liệu.
import { createClient, type SupabaseClient, type Session } from '@supabase/supabase-js'
import type { Action } from '../core/engine'
import type { GameState, GameId } from '../core/state'
import { BackendError, type ActResponse, type Backend, type SocialApi, type FriendEntry, type VisitResult, type LeaderRow, type InboxEntry, type FriendRequest } from './types'

export interface OnlineConfig {
  url: string
  key: string
}

export function readConfig(): OnlineConfig | null {
  const env = import.meta.env as Record<string, string | undefined>
  const url = env.VITE_SUPABASE_URL?.trim()
  const key = (env.VITE_SUPABASE_PUBLISHABLE_KEY ?? env.VITE_SUPABASE_ANON_KEY)?.trim()
  if (!url || !key) return null
  return { url, key }
}

let client: SupabaseClient | null = null
export function supabase(cfg: OnlineConfig): SupabaseClient {
  if (!client) client = createClient(cfg.url, cfg.key, { auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true } })
  return client
}

/** Lấy access token hiện tại (tự làm mới) — hoặc token giả khi chạy dev cục bộ. */
export type TokenSource = () => Promise<string | null>

export function supabaseToken(sb: SupabaseClient): TokenSource {
  return async () => (await sb.auth.getSession()).data.session?.access_token ?? null
}

/** Gọi hàm máy chủ /api/cozii. */
async function call<T>(token: TokenSource, op: string, args: Record<string, unknown> = {}): Promise<T> {
  const t = await token()
  if (!t) throw new BackendError('auth', 'Bạn chưa đăng nhập.')
  let res: Response
  try {
    res = await fetch('/api/cozii', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${t}` },
      body: JSON.stringify({ op, ...args }),
    })
  } catch (e) {
    throw new BackendError('network', e instanceof Error ? e.message : 'Mất kết nối.', true)
  }
  let body: { data?: T; error?: { code: string; message: string } }
  try {
    body = await res.json()
  } catch {
    throw new BackendError('network', 'Máy chủ không phản hồi đúng.', res.status >= 500 || res.status === 0)
  }
  if (!res.ok || body.error) {
    const err = body.error ?? { code: 'error', message: 'Máy chủ từ chối thao tác.' }
    // 5xx/409: lỗi tạm thời — giữ lại để gửi lại đúng mã yêu cầu.
    throw new BackendError(err.code, err.message, res.status >= 500 || res.status === 409)
  }
  return body.data as T
}

const CACHE_KEY = 'cozii:online:cache'

export class SupabaseBackend implements Backend {
  readonly kind = 'online' as const
  private token: TokenSource
  constructor(token: TokenSource) {
    this.token = token
  }
  async load(): Promise<GameState> {
    try {
      const s = await call<GameState>(this.token, 'state')
      try { localStorage.setItem(CACHE_KEY, JSON.stringify(s)) } catch { /* bỏ qua */ }
      return s
    } catch (e) {
      // Ngoại tuyến: dùng bản đã lưu gần nhất để xem (không thao tác được tài sản).
      if (e instanceof BackendError && e.network) {
        const raw = localStorage.getItem(CACHE_KEY)
        if (raw) return JSON.parse(raw) as GameState
      }
      throw e
    }
  }
  async act(a: Action, requestId: string): Promise<ActResponse> {
    const r = await call<ActResponse>(this.token, 'act', { action: a, requestId })
    try { localStorage.setItem(CACHE_KEY, JSON.stringify(r.state)) } catch { /* bỏ qua */ }
    return r
  }
}

export class SupabaseSocial implements SocialApi {
  private t: TokenSource
  constructor(token: TokenSource) {
    this.t = token
  }
  publishHome() { return call<{ publishedAt: string }>(this.t, 'publish') }
  async setVisibility() { /* đi qua thao tác setPrivacy */ }
  findByCode(code: string) { return call<FriendEntry | null>(this.t, 'findByCode', { code }) }
  async sendRequest(code: string) { await call(this.t, 'sendRequest', { code }) }
  async respondRequest(id: string, accept: boolean) { await call(this.t, 'respondRequest', { id, accept }) }
  listFriends() { return call<FriendEntry[]>(this.t, 'listFriends') }
  listRequests() { return call<{ incoming: FriendRequest[]; outgoing: FriendRequest[] }>(this.t, 'listRequests') }
  async removeFriend(id: string) { await call(this.t, 'removeFriend', { other: id }) }
  async block(id: string) { await call(this.t, 'block', { other: id }) }
  async unblock(id: string) { await call(this.t, 'unblock', { other: id }) }
  listBlocked() { return call<FriendEntry[]>(this.t, 'listBlocked') }
  async report(id: string, reason: string, details: string) { await call(this.t, 'report', { other: id, reason, details }) }
  discover(cursor: string | null) { return call<{ homes: FriendEntry[]; next: string | null }>(this.t, 'discover', { cursor }) }
  visit(hostId: string) { return call<VisitResult>(this.t, 'visit', { host: hostId }) }
  async compliment(hostId: string, sticker: string) { await call(this.t, 'compliment', { host: hostId, sticker }) }
  helpWater(hostId: string, plot: number, requestId: string) { return call<{ coins: number }>(this.t, 'helpWater', { host: hostId, plot, requestId }) }
  inbox() { return call<InboxEntry[]>(this.t, 'inbox') }
  leaderboard(game: GameId, scope: 'all' | 'weekly' | 'friends', week?: string) { return call<{ rows: LeaderRow[]; me: LeaderRow | null; week: string }>(this.t, 'leaderboard', { game, scope, week: week ?? null }) }
  collectorBoard() { return call<{ rows: LeaderRow[]; me: LeaderRow | null }>(this.t, 'collectors') }
  claimBadges() { return call<{ badges: string[] }>(this.t, 'claimBadges') }
}

export async function currentSession(sb: SupabaseClient): Promise<Session | null> {
  const { data } = await sb.auth.getSession()
  return data.session
}

export function authErrorText(e: unknown): string {
  const m = e instanceof Error ? e.message : String(e)
  if (/anonymous sign-ins are disabled/i.test(m)) return 'Máy chủ chưa bật đăng nhập khách (Anonymous sign-ins).'
  if (/rate limit/i.test(m)) return 'Thử lại sau ít phút (giới hạn số lần gửi).'
  if (/invalid|expired/i.test(m)) return 'Mã không đúng hoặc đã hết hạn.'
  if (/already/i.test(m)) return 'Email này đã thuộc một tài khoản khác. Hãy đăng nhập bằng email đó.'
  return m
}
