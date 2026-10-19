// Chế độ chơi trên máy này: chạy luật trong trình duyệt, lưu vào localStorage.
// Dữ liệu chỉ nằm trên trình duyệt này, không được máy chủ xác minh — giao diện luôn ghi rõ điều đó.
import { apply, GameError, newState, type Action, type Env } from '../core/engine'
import type { GameState } from '../core/state'
import { BackendError, type ActResponse, type Backend } from './types'

const KEY = 'cozii:local:v1'
const TX_KEY = 'cozii:local:tx:v1'
const LAST_SEEN = 'cozii:local:lastSeen'

export function uuid(): string {
  if (globalThis.crypto?.randomUUID) return crypto.randomUUID()
  const b = new Uint8Array(16)
  globalThis.crypto.getRandomValues(b)
  b[6] = (b[6] & 0x0f) | 0x40
  b[8] = (b[8] & 0x3f) | 0x80
  const h = [...b].map(x => x.toString(16).padStart(2, '0')).join('')
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-${h.slice(12, 16)}-${h.slice(16, 20)}-${h.slice(20)}`
}

export function cryptoRand(): number {
  const a = new Uint32Array(1)
  globalThis.crypto.getRandomValues(a)
  return a[0] / 4294967296
}

export interface Storage {
  get(k: string): string | null
  set(k: string, v: string): void
  remove(k: string): void
}

export const browserStorage: Storage = {
  get(k) {
    try { return localStorage.getItem(k) } catch { return null }
  },
  set(k, v) {
    try { localStorage.setItem(k, v) } catch { /* bộ nhớ đầy hoặc bị chặn: vẫn chơi được trong phiên này */ }
  },
  remove(k) {
    try { localStorage.removeItem(k) } catch { /* bỏ qua */ }
  },
}

export class LocalBackend implements Backend {
  readonly kind = 'local' as const
  private state: GameState | null = null
  private tx: Record<string, unknown> = {}
  private readonly storage: Storage
  private readonly clock: () => number

  constructor(storage: Storage = browserStorage, clock: () => number = () => Date.now()) {
    this.storage = storage
    this.clock = clock
  }

  /** Đồng hồ đơn điệu: chỉnh giờ máy lùi lại không làm cây "lớn ngược" hay nhu cầu hồi lại. */
  private now(): number {
    const t = this.clock()
    const last = Number(this.storage.get(LAST_SEEN) ?? 0)
    const v = Math.max(t, Number.isFinite(last) ? last : 0)
    this.storage.set(LAST_SEEN, String(v))
    return v
  }

  private env(): Env {
    return { now: this.now(), rand: cryptoRand, uuid }
  }

  async load(): Promise<GameState> {
    if (!this.state) {
      const raw = this.storage.get(KEY)
      if (raw) {
        try {
          this.state = JSON.parse(raw) as GameState
        } catch {
          this.state = null
        }
      }
      if (!this.state) {
        this.state = newState('local-' + uuid().slice(0, 8), this.now(), this.env(), 'local')
        this.save()
      }
      try {
        this.tx = JSON.parse(this.storage.get(TX_KEY) ?? '{}')
      } catch {
        this.tx = {}
      }
    }
    this.state.serverNow = this.now()
    return structuredClone(this.state)
  }

  async act(a: Action, requestId: string): Promise<ActResponse> {
    const s = await this.load().then(() => this.state!)
    if (requestId in this.tx) return { state: structuredClone(s), result: this.tx[requestId] as never }
    const draft = structuredClone(s)
    let result
    try {
      result = apply(draft, a, this.env())
    } catch (e) {
      if (e instanceof GameError) throw new BackendError(e.code, e.message)
      throw e
    }
    this.state = draft
    this.tx[requestId] = result ?? null
    const keys = Object.keys(this.tx)
    if (keys.length > 60) for (const k of keys.slice(0, keys.length - 60)) delete this.tx[k]
    this.save()
    return { state: structuredClone(draft), result }
  }

  private save() {
    this.storage.set(KEY, JSON.stringify(this.state))
    this.storage.set(TX_KEY, JSON.stringify(this.tx))
  }

  /** Xóa dữ liệu chơi trên máy (Cài đặt → Xóa dữ liệu trên máy). */
  reset() {
    this.storage.remove(KEY)
    this.storage.remove(TX_KEY)
    this.state = null
  }

  /** Bản sao lưu chế độ chơi trên máy (JSON). Không dùng được để tạo tài sản cho tài khoản online. */
  exportBackup(): string {
    return JSON.stringify({ kind: 'cozii-local-backup', v: 1, exportedAt: new Date(this.clock()).toISOString(), state: this.state }, null, 1)
  }

  importBackup(text: string) {
    const data = JSON.parse(text)
    if (data?.kind !== 'cozii-local-backup' || !data.state?.profile) throw new BackendError('backup', 'File sao lưu không hợp lệ.')
    if (data.state.mode !== 'local') throw new BackendError('backup', 'Chỉ khôi phục được bản sao lưu của chế độ chơi trên máy.')
    this.state = data.state
    this.tx = {}
    this.save()
  }
}
