// Chế độ online: Supabase (Auth + Postgres). Mọi thay đổi tiền, kho, vườn, capsule… đi qua hàm RPC có kiểm tra quyền
// và chạy trong một giao dịch ở máy chủ (supabase/migrations). Client không bao giờ ghi trực tiếp vào bảng.
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

function isNetwork(err: { message?: string; code?: string } | null | undefined): boolean {
  if (typeof navigator !== 'undefined' && navigator.onLine === false) return true
  const m = (err?.message ?? '').toLowerCase()
  return m.includes('failed to fetch') || m.includes('networkerror') || m.includes('load failed') || m.includes('network request failed') || m.includes('fetch')
}

function toError(err: { message?: string; code?: string; hint?: string } | null): BackendError {
  if (isNetwork(err)) return new BackendError('network', 'Mất kết nối tới máy chủ.', true)
  const code = err?.hint || err?.code || 'error'
  let msg = err?.message || 'Máy chủ từ chối thao tác.'
  if (code === 'PGRST301' || code === '401' || /jwt/i.test(msg)) msg = 'Phiên đăng nhập đã hết hạn. Hãy tải lại trang.'
  return new BackendError(code, msg)
}

async function rpc<T>(sb: SupabaseClient, fn: string, args: Record<string, unknown> = {}): Promise<T> {
  let res
  try {
    res = await sb.rpc(fn, args)
  } catch (e) {
    throw new BackendError('network', e instanceof Error ? e.message : 'Mất kết nối.', true)
  }
  if (res.error) throw toError(res.error)
  return res.data as T
}

const CACHE_KEY = 'cozii:online:cache'

export class SupabaseBackend implements Backend {
  readonly kind = 'online' as const
  readonly sb: SupabaseClient
  constructor(sb: SupabaseClient) {
    this.sb = sb
  }
  async load(): Promise<GameState> {
    try {
      const s = await rpc<GameState>(this.sb, 'cozii_state')
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
    const r = await rpc<ActResponse>(this.sb, 'cozii_act', { p_action: a, p_request: requestId })
    try { localStorage.setItem(CACHE_KEY, JSON.stringify(r.state)) } catch { /* bỏ qua */ }
    return r
  }
}

export class SupabaseSocial implements SocialApi {
  private sb: SupabaseClient
  constructor(sb: SupabaseClient) {
    this.sb = sb
  }
  publishHome() { return rpc<{ publishedAt: string }>(this.sb, 'cozii_publish_home') }
  async setVisibility() { /* đi qua cozii_act setPrivacy */ }
  findByCode(code: string) { return rpc<FriendEntry | null>(this.sb, 'cozii_find_by_code', { p_code: code }) }
  async sendRequest(code: string) { await rpc(this.sb, 'cozii_send_request', { p_code: code }) }
  async respondRequest(id: string, accept: boolean) { await rpc(this.sb, 'cozii_respond_request', { p_id: id, p_accept: accept }) }
  listFriends() { return rpc<FriendEntry[]>(this.sb, 'cozii_list_friends') }
  listRequests() { return rpc<{ incoming: FriendRequest[]; outgoing: FriendRequest[] }>(this.sb, 'cozii_list_requests') }
  async removeFriend(id: string) { await rpc(this.sb, 'cozii_remove_friend', { p_other: id }) }
  async block(id: string) { await rpc(this.sb, 'cozii_block', { p_other: id }) }
  async unblock(id: string) { await rpc(this.sb, 'cozii_unblock', { p_other: id }) }
  listBlocked() { return rpc<FriendEntry[]>(this.sb, 'cozii_list_blocked') }
  async report(id: string, reason: string, details: string) { await rpc(this.sb, 'cozii_report', { p_other: id, p_reason: reason, p_details: details }) }
  discover(cursor: string | null) { return rpc<{ homes: FriendEntry[]; next: string | null }>(this.sb, 'cozii_discover', { p_cursor: cursor }) }
  visit(hostId: string) { return rpc<VisitResult>(this.sb, 'cozii_visit', { p_host: hostId }) }
  async compliment(hostId: string, sticker: string) { await rpc(this.sb, 'cozii_compliment', { p_host: hostId, p_sticker: sticker }) }
  helpWater(hostId: string, plot: number, requestId: string) { return rpc<{ coins: number }>(this.sb, 'cozii_help_water', { p_host: hostId, p_plot: plot, p_request: requestId }) }
  inbox() { return rpc<InboxEntry[]>(this.sb, 'cozii_inbox') }
  leaderboard(game: GameId, scope: 'all' | 'weekly' | 'friends', week?: string) { return rpc<{ rows: LeaderRow[]; me: LeaderRow | null; week: string }>(this.sb, 'cozii_leaderboard', { p_game: game, p_scope: scope, p_week: week ?? null }) }
  collectorBoard() { return rpc<{ rows: LeaderRow[]; me: LeaderRow | null }>(this.sb, 'cozii_collectors') }
  claimBadges() { return rpc<{ badges: string[] }>(this.sb, 'cozii_claim_badges') }
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
