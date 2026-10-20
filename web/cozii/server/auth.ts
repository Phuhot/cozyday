// Xác minh người chơi: hỏi Supabase Auth (GET /auth/v1/user) với access token của người chơi.
// Không dùng service-role/secret key. Kết quả được nhớ ngắn hạn theo token để giảm số lần gọi.

export interface AuthUser {
  id: string
  email: string | null
  isAnonymous: boolean
}

export class HttpError extends Error {
  readonly status: number
  readonly code: string
  constructor(status: number, code: string, message: string) {
    super(message)
    this.status = status
    this.code = code
  }
}

const cache = new Map<string, { user: AuthUser; until: number }>()

function supabaseEnv() {
  const url = process.env.SUPABASE_URL ?? process.env.VITE_SUPABASE_URL
  const key = process.env.SUPABASE_PUBLISHABLE_KEY ?? process.env.VITE_SUPABASE_PUBLISHABLE_KEY ?? process.env.VITE_SUPABASE_ANON_KEY
  return { url, key }
}

/** Chế độ xác thực giả CHỈ cho test cục bộ: bật bằng COZII_DEV_AUTH=1 và không bao giờ có hiệu lực trên Vercel/production. */
function devAuthAllowed() {
  return process.env.COZII_DEV_AUTH === '1' && !process.env.VERCEL && process.env.NODE_ENV !== 'production'
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

export async function authenticate(header: string | undefined): Promise<AuthUser> {
  const token = header?.startsWith('Bearer ') ? header.slice(7).trim() : null
  if (!token) throw new HttpError(401, 'auth', 'Bạn chưa đăng nhập.')
  if (token.startsWith('dev:')) {
    if (!devAuthAllowed()) throw new HttpError(401, 'auth', 'Phiên đăng nhập không hợp lệ.')
    const [, id, anon] = token.split(':')
    if (!UUID.test(id)) throw new HttpError(401, 'auth', 'Phiên đăng nhập không hợp lệ.')
    return { id, email: anon === 'anon' ? null : `${id.slice(0, 6)}@dev.local`, isAnonymous: anon === 'anon' }
  }
  const hit = cache.get(token)
  if (hit && hit.until > Date.now()) return hit.user
  const { url, key } = supabaseEnv()
  if (!url || !key) throw new HttpError(500, 'config', 'Máy chủ chưa cấu hình SUPABASE_URL / publishable key.')
  let res: Response
  try {
    res = await fetch(`${url.replace(/\/$/, '')}/auth/v1/user`, { headers: { apikey: key, Authorization: `Bearer ${token}` } })
  } catch {
    throw new HttpError(503, 'auth_unreachable', 'Không kết nối được dịch vụ đăng nhập.')
  }
  if (res.status === 401 || res.status === 403) throw new HttpError(401, 'auth', 'Phiên đăng nhập đã hết hạn. Hãy tải lại trang.')
  if (!res.ok) throw new HttpError(503, 'auth_unreachable', 'Dịch vụ đăng nhập đang bận.')
  const u = (await res.json()) as { id?: string; email?: string | null; is_anonymous?: boolean }
  if (!u.id || !UUID.test(u.id)) throw new HttpError(401, 'auth', 'Phiên đăng nhập không hợp lệ.')
  const user: AuthUser = { id: u.id, email: u.email ?? null, isAnonymous: !!u.is_anonymous }
  cache.set(token, { user, until: Date.now() + 60_000 })
  if (cache.size > 500) cache.delete(cache.keys().next().value!)
  return user
}
