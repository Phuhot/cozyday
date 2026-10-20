import { createContext, useContext } from 'react'

export type AuthStatus = 'local' | 'guest' | 'member'

/** Đăng nhập / tài khoản. `null` khi bản build chưa cấu hình máy chủ (chỉ chơi trên máy). */
export interface AuthApi {
  status: AuthStatus
  email: string | null
  configured: boolean
  /** Gửi mã 6 số đăng nhập tới email. */
  sendCode(email: string): Promise<void>
  verifyCode(email: string, code: string): Promise<void>
  /** Gắn email cho tài khoản khách (giữ nguyên toàn bộ tiến độ online). */
  linkEmail(email: string): Promise<void>
  verifyLink(email: string, code: string): Promise<void>
  signOut(): Promise<void>
  /** Chuyển sang chế độ chơi trên máy / sang online (tải lại app). */
  useLocal(): void
  useOnline(): void
}

export const AuthCtx = createContext<AuthApi | null>(null)
export function useAuth(): AuthApi | null {
  return useContext(AuthCtx)
}

export function preferredMode(): 'online' | 'local' | null {
  try {
    const v = localStorage.getItem('cozii:mode')
    return v === 'online' || v === 'local' ? v : null
  } catch {
    return null
  }
}
export function setPreferredMode(v: 'online' | 'local') {
  try {
    localStorage.setItem('cozii:mode', v)
  } catch {
    /* bỏ qua */
  }
}
