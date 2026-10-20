import { useState } from 'react'
import { useAuth } from '../../app/auth'
import { useGame } from '../../app/game'
import { Sheet } from '../kit'

/** Thẻ trạng thái tài khoản: chơi trên máy / khách online / đã gắn email. */
export function AccountCard() {
  const auth = useAuth()
  const { state } = useGame()
  const [sheet, setSheet] = useState(false)
  if (!auth) return null
  const text =
    auth.status === 'local'
      ? { t: 'Đang chơi trên máy này', d: 'Tiến độ chỉ lưu trong trình duyệt này và không được máy chủ xác minh. Xóa dữ liệu trình duyệt là mất.' }
      : auth.status === 'guest'
        ? { t: 'Tài khoản khách (online)', d: 'Tiến độ lưu trên máy chủ, nhưng chỉ mở lại được từ trình duyệt này. Gắn email để không mất khi đổi máy.' }
        : { t: `Tài khoản ${auth.email ?? ''}`, d: 'Tiến độ lưu trên máy chủ. Đăng nhập bằng email trên máy khác để chơi tiếp.' }
  return (
    <div className="card row" style={{ background: auth.status === 'member' ? 'var(--sage-2)' : 'var(--honey-2)' }}>
      <div style={{ flex: 1 }} className="small"><b>{text.t}</b><div className="muted tiny">{text.d}</div></div>
      {auth.configured && <button className="btn small" onClick={() => setSheet(true)}>{auth.status === 'member' ? 'Tài khoản' : auth.status === 'guest' ? 'Gắn email' : 'Chơi online'}</button>}
      {sheet && <AccountSheet onClose={() => setSheet(false)} />}
      <span className="sr-only">{state.profile.name}</span>
    </div>
  )
}

export function AccountSheet({ onClose }: { onClose: () => void }) {
  const auth = useAuth()!
  const [email, setEmail] = useState('')
  const [code, setCode] = useState('')
  const [sent, setSent] = useState(false)
  const [busy, setBusy] = useState(false)
  const [err, setErr] = useState<string | null>(null)
  const go = async (fn: () => Promise<void>) => {
    setBusy(true)
    setErr(null)
    try {
      await fn()
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Có lỗi xảy ra.')
    } finally {
      setBusy(false)
    }
  }
  return (
    <Sheet title="Tài khoản" onClose={onClose}>
      <div className="stack">
        {auth.status === 'local' && (
          <>
            <p className="small">Chơi online để lưu tiến độ trên máy chủ, kết bạn, thăm nhà nhau và lên bảng xếp hạng.</p>
            <div className="card small" style={{ background: 'var(--honey-2)' }}>
              <b>Quy tắc chuyển dữ liệu:</b> tài khoản online bắt đầu với quà khởi đầu chuẩn. Xu, đồ và vườn của chế độ chơi trên máy <b>không</b> được chuyển sang (máy chủ không tin số dư do trình duyệt tự khai). Dữ liệu trên máy vẫn còn, quay lại chế độ này lúc nào cũng được.
            </div>
            <button className="btn primary block" onClick={() => auth.useOnline()}>Chơi online</button>
          </>
        )}
        {auth.status === 'guest' && (
          <>
            <p className="small">Gắn email để giữ tiến độ khi đổi máy hoặc xóa dữ liệu trình duyệt. Toàn bộ tiến độ hiện tại được giữ nguyên.</p>
            {!sent ? (
              <>
                <input className="input" type="email" placeholder="email@vidu.com" value={email} onChange={e => setEmail(e.target.value)} autoComplete="email" />
                <button className="btn primary" disabled={busy || !email.includes('@')} onClick={() => go(async () => { await auth.linkEmail(email.trim()); setSent(true) })}>Gửi mã xác nhận</button>
              </>
            ) : (
              <>
                <p className="small">Nhập mã 6 số vừa gửi tới {email}.</p>
                <input className="input" inputMode="numeric" maxLength={8} value={code} onChange={e => setCode(e.target.value.replace(/\D/g, ''))} />
                <button className="btn primary" disabled={busy || code.length < 6} onClick={() => go(async () => { await auth.verifyLink(email.trim(), code); onClose() })}>Xác nhận</button>
              </>
            )}
            <hr style={{ border: 0, borderTop: '1px solid var(--line)', width: '100%' }} />
            <p className="tiny muted">Đã có tài khoản email khác? Đăng nhập sẽ rời tài khoản khách này (không gộp hai tài khoản).</p>
            <button className="btn small" onClick={() => go(async () => { await auth.signOut() })}>Đăng xuất khách</button>
          </>
        )}
        {auth.status === 'member' && (
          <>
            <p className="small">Đang đăng nhập: <b>{auth.email}</b></p>
            <button className="btn" onClick={() => go(async () => { await auth.signOut() })}>Đăng xuất</button>
          </>
        )}
        {auth.status !== 'local' && <button className="btn ghost small" onClick={() => auth.useLocal()}>Chuyển sang chơi trên máy (không cần mạng)</button>}
        {err && <div className="small" style={{ color: 'var(--danger)' }}>{err}</div>}
      </div>
    </Sheet>
  )
}

/** Màn chào khi có máy chủ mà chưa đăng nhập. */
export function Welcome({ onGuest, onLocal, configured, sendCode, verifyCode }: {
  onGuest: () => Promise<void>; onLocal: () => void; configured: boolean
  sendCode: (email: string) => Promise<void>; verifyCode: (email: string, code: string) => Promise<void>
}) {
  const [email, setEmail] = useState('')
  const [code, setCode] = useState('')
  const [sent, setSent] = useState(false)
  const [busy, setBusy] = useState(false)
  const [err, setErr] = useState<string | null>(null)
  const go = async (fn: () => Promise<void>) => {
    setBusy(true)
    setErr(null)
    try { await fn() } catch (e) { setErr(e instanceof Error ? e.message : 'Có lỗi xảy ra.') } finally { setBusy(false) }
  }
  return (
    <div style={{ minHeight: '100dvh', display: 'grid', placeItems: 'center', padding: 16 }}>
      <div className="card stack" style={{ width: 'min(100%, 440px)', padding: 22 }}>
        <h1 style={{ fontSize: 34, fontWeight: 900, color: 'var(--lavender-deep)' }}>Cozii!</h1>
        <p>Thị trấn bạn nhỏ: nuôi pet, trồng rau, chơi minigame, trang trí nhà và ghé thăm nhau.</p>
        {configured && (
          <>
            <button className="btn primary block" disabled={busy} onClick={() => go(onGuest)}>Chơi ngay (tài khoản khách)</button>
            <p className="tiny muted">Tài khoản khách lưu trên máy chủ nhưng chỉ mở lại được từ trình duyệt này. Gắn email sau để giữ lâu dài.</p>
            <details>
              <summary className="small bold" style={{ cursor: 'pointer' }}>Đăng nhập bằng email</summary>
              <div className="stack" style={{ marginTop: 8 }}>
                {!sent ? (
                  <>
                    <input className="input" type="email" placeholder="email@vidu.com" value={email} onChange={e => setEmail(e.target.value)} autoComplete="email" />
                    <button className="btn" disabled={busy || !email.includes('@')} onClick={() => go(async () => { await sendCode(email.trim()); setSent(true) })}>Gửi mã đăng nhập</button>
                  </>
                ) : (
                  <>
                    <input className="input" inputMode="numeric" placeholder="Mã 6 số" value={code} onChange={e => setCode(e.target.value.replace(/\D/g, ''))} />
                    <button className="btn primary" disabled={busy || code.length < 6} onClick={() => go(() => verifyCode(email.trim(), code))}>Đăng nhập</button>
                  </>
                )}
              </div>
            </details>
          </>
        )}
        <button className="btn ghost block" onClick={onLocal}>Chơi trên máy này, không cần mạng</button>
        <p className="tiny muted">Chơi trên máy: lưu trong trình duyệt, không kết bạn, không xếp hạng. Không có gì bảo đảm dữ liệu trình duyệt tồn tại mãi (xóa dữ liệu duyệt web là mất), nên hãy xuất sao lưu trong Cài đặt.</p>
        {err && <div className="small" style={{ color: 'var(--danger)' }}>{err}</div>}
      </div>
    </div>
  )
}
