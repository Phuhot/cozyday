import { StrictMode, useEffect, useMemo, useState } from 'react'
import { createRoot } from 'react-dom/client'
import './styles.css'
import { App } from './app/App'
import { GameProvider } from './app/game'
import { AuthCtx, preferredMode, setPreferredMode, type AuthApi } from './app/auth'
import { LocalBackend } from './backend/local'
import type { Backend, SocialApi } from './backend/types'
import type { GameState } from './core/state'
import { readConfig, supabase, SupabaseBackend, SupabaseSocial, currentSession, authErrorText, supabaseToken, type TokenSource } from './backend/supabase'
import { Welcome } from './ui/screens/Account'
import { registerSW } from './app/pwa'

registerSW()

const cfg = readConfig()

/** Chỉ khi chạy `npm run dev` với VITE_COZII_DEV_AUTH=1: đăng nhập giả để thử online trên máy (không có ở bản build). */
const devAuth = import.meta.env.DEV && import.meta.env.VITE_COZII_DEV_AUTH === '1'
function devToken(): TokenSource {
  return async () => {
    let id = localStorage.getItem('cozii:devUser')
    if (!id) {
      id = crypto.randomUUID()
      localStorage.setItem('cozii:devUser', id)
    }
    return `dev:${id}`
  }
}

type Boot =
  | { kind: 'loading' }
  | { kind: 'welcome' }
  | { kind: 'ready'; backend: Backend; social: SocialApi | null; state: GameState; status: AuthApi['status']; email: string | null }
  | { kind: 'error'; message: string }

function reload() {
  location.hash = ''
  location.reload()
}

function Root() {
  const [boot, setBoot] = useState<Boot>({ kind: 'loading' })

  const startLocal = async () => {
    const backend = new LocalBackend()
    setBoot({ kind: 'ready', backend, social: null, state: await backend.load(), status: 'local', email: null })
  }

  const startOnline = async () => {
    if (devAuth) {
      const t = devToken()
      const backend = new SupabaseBackend(t)
      try {
        setBoot({ kind: 'ready', backend, social: new SupabaseSocial(t), state: await backend.load(), status: 'member', email: 'dev@local' })
      } catch (e) {
        setBoot({ kind: 'error', message: e instanceof Error ? e.message : 'Lỗi máy chủ dev.' })
      }
      return
    }
    const sb = supabase(cfg!)
    const session = await currentSession(sb)
    if (!session) {
      setBoot({ kind: 'welcome' })
      return
    }
    const token = supabaseToken(sb)
    const backend = new SupabaseBackend(token)
    try {
      const state = await backend.load()
      const user = session.user
      setBoot({ kind: 'ready', backend, social: new SupabaseSocial(token), state, status: user.is_anonymous ? 'guest' : 'member', email: user.email ?? null })
    } catch (e) {
      setBoot({ kind: 'error', message: e instanceof Error ? e.message : 'Không kết nối được máy chủ.' })
    }
  }

  useEffect(() => {
    const mode = cfg || devAuth ? preferredMode() ?? 'online' : 'local'
    void (mode === 'local' ? startLocal() : startOnline())
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const auth = useMemo<AuthApi | null>(() => {
    if (boot.kind !== 'ready') return null
    const sb = cfg ? supabase(cfg) : null
    const need = () => {
      if (!sb) throw new Error('Bản này chưa cấu hình máy chủ.')
      return sb
    }
    return {
      status: boot.status,
      email: boot.email,
      configured: !!cfg,
      async sendCode(email) {
        const { error } = await need().auth.signInWithOtp({ email, options: { shouldCreateUser: true } })
        if (error) throw new Error(authErrorText(error))
      },
      async verifyCode(email, code) {
        const { error } = await need().auth.verifyOtp({ email, token: code, type: 'email' })
        if (error) throw new Error(authErrorText(error))
        reload()
      },
      async linkEmail(email) {
        const { error } = await need().auth.updateUser({ email })
        if (error) throw new Error(authErrorText(error))
      },
      async verifyLink(email, code) {
        const { error } = await need().auth.verifyOtp({ email, token: code, type: 'email_change' })
        if (error) throw new Error(authErrorText(error))
        reload()
      },
      async signOut() {
        await need().auth.signOut()
        reload()
      },
      useLocal() {
        setPreferredMode('local')
        reload()
      },
      useOnline() {
        setPreferredMode('online')
        reload()
      },
    }
  }, [boot])

  if (boot.kind === 'loading') return <div style={{ minHeight: '100dvh', display: 'grid', placeItems: 'center', color: 'var(--lavender-deep)', fontWeight: 900, fontSize: 28 }}>Cozii!</div>
  if (boot.kind === 'error') {
    return (
      <div style={{ minHeight: '100dvh', display: 'grid', placeItems: 'center', padding: 16 }}>
        <div className="card stack" style={{ maxWidth: 420 }}>
          <b>Chưa kết nối được thị trấn</b>
          <p className="small muted">{boot.message}</p>
          <button className="btn primary" onClick={reload}>Thử lại</button>
          <button className="btn" onClick={() => { setPreferredMode('local'); reload() }}>Chơi trên máy này</button>
        </div>
      </div>
    )
  }
  if (boot.kind === 'welcome') {
    const sb = supabase(cfg!)
    return (
      <Welcome
        configured
        onGuest={async () => {
          const { error } = await sb.auth.signInAnonymously()
          if (error) throw new Error(authErrorText(error))
          setPreferredMode('online')
          reload()
        }}
        onLocal={() => { setPreferredMode('local'); reload() }}
        sendCode={async email => {
          const { error } = await sb.auth.signInWithOtp({ email, options: { shouldCreateUser: true } })
          if (error) throw new Error(authErrorText(error))
        }}
        verifyCode={async (email, code) => {
          const { error } = await sb.auth.verifyOtp({ email, token: code, type: 'email' })
          if (error) throw new Error(authErrorText(error))
          setPreferredMode('online')
          reload()
        }}
      />
    )
  }
  return (
    <AuthCtx.Provider value={auth}>
      <GameProvider backend={boot.backend} social={boot.social} initial={boot.state}>
        <App />
      </GameProvider>
    </AuthCtx.Provider>
  )
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Root />
  </StrictMode>,
)
