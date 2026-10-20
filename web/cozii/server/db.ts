// Kết nối Postgres (Supabase) cho hàm máy chủ. Dùng chuỗi kết nối bí mật DATABASE_URL (pooler chế độ transaction).
import pg from 'pg'

let pool: pg.Pool | null = null

export function getPool(): pg.Pool {
  if (pool) return pool
  const url = process.env.DATABASE_URL
  if (!url) throw new Error('Thiếu biến môi trường DATABASE_URL trên máy chủ.')
  const local = /@(localhost|127\.0\.0\.1)[:/]/.test(url)
  pool = new pg.Pool({
    connectionString: url,
    max: Number(process.env.DATABASE_POOL_MAX ?? 3),
    idleTimeoutMillis: 10_000,
    connectionTimeoutMillis: 8_000,
    // Supabase yêu cầu SSL. Nếu có DATABASE_CA (chứng chỉ của Supabase) thì xác minh đầy đủ.
    ssl: local ? undefined : process.env.DATABASE_CA ? { ca: process.env.DATABASE_CA } : { rejectUnauthorized: false },
  })
  return pool
}

export function setPool(p: pg.Pool) {
  pool = p
}

/** Chạy `fn` trong một giao dịch; lỗi thì ROLLBACK toàn bộ. */
export async function tx<T>(fn: (c: pg.PoolClient) => Promise<T>): Promise<T> {
  const c = await getPool().connect()
  try {
    await c.query('begin')
    const r = await fn(c)
    await c.query('commit')
    return r
  } catch (e) {
    try {
      await c.query('rollback')
    } catch {
      /* bỏ qua */
    }
    throw e
  } finally {
    c.release()
  }
}

export async function q<T extends pg.QueryResultRow = pg.QueryResultRow>(c: pg.PoolClient | pg.Pool, sql: string, params: unknown[] = []): Promise<T[]> {
  const r = await c.query<T>(sql, params)
  return r.rows
}
