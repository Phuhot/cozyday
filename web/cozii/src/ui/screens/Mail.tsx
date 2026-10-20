import { useEffect, useState } from 'react'
import { useGame } from '../../app/game'
import { CHAPTERS, STICKERS, npc } from '../../content/town'
import type { InboxEntry } from '../../backend/types'
import { Empty, Sheet } from '../kit'
import { PetThumb } from '../PetCanvas'

const LETTERS: Record<number, { from: string; text: string }> = {
  1: { from: 'tra', text: 'Chào mừng cháu tới Cozii. Ông để sẵn một ấm trà ở tòa thị chính, lúc nào rảnh thì ghé.' },
  2: { from: 'la', text: 'Vườn của bạn xanh mướt luôn! Lần sau đổi hạt giống với mình nhé!' },
  3: { from: 'bo', text: 'Cảm ơn vì đã giao đơn và ghé thăm mọi người. Bơ đếm được ba ngôi nhà vui hơn rồi đó.' },
  4: { from: 'moc', text: 'Bà ghé ngang qua cửa sổ nhà cháu. Đẹp lắm. Bà tự hào ghê.' },
  5: { from: 'pip', text: 'Ngày hội vui quá! Năm sau mình thi Nhảy Mây tiếp nha. Pip sẽ không nhường đâu.' },
}

export function MailSheet({ onClose }: { onClose: () => void }) {
  const { state, social } = useGame()
  const [inbox, setInbox] = useState<InboxEntry[] | null>(null)
  const [err, setErr] = useState(false)
  useEffect(() => {
    if (!social) return
    social.inbox().then(setInbox).catch(() => setErr(true))
  }, [social])
  const letters = state.passport.claimed.map(id => ({ id, ...LETTERS[id] })).reverse()
  return (
    <Sheet title="Hộp thư" onClose={onClose}>
      <div className="stack">
        {social && (
          <>
            <b className="small">Từ hàng xóm</b>
            {err && <div className="card small muted">Chưa tải được thư (đang ngoại tuyến?).</div>}
            {inbox && inbox.length === 0 && <Empty>Chưa có lời khen nào. Đăng nhà cho bạn bè xem ở tab Bạn bè nhé.</Empty>}
            {inbox?.map((m, i) => (
              <div key={i} className="card small row">
                <span style={{ fontSize: 22 }}>{m.kind === 'compliment' ? STICKERS.find(s => s.id === m.sticker)?.emoji ?? '💌' : m.kind === 'help_water' ? '💧' : '👋'}</span>
                <div style={{ flex: 1 }}>
                  <b>{m.from?.name ?? 'Một người bạn'}</b>{' '}
                  {m.kind === 'compliment' ? `khen: “${STICKERS.find(s => s.id === m.sticker)?.text ?? ''}”` : m.kind === 'help_water' ? 'đã tưới giúp vườn của bạn.' : 'muốn kết bạn.'}
                  <div className="tiny muted">{new Date(m.at).toLocaleString('vi-VN')}</div>
                </div>
              </div>
            ))}
          </>
        )}
        <b className="small">Thư cảm ơn từ thị trấn</b>
        {letters.length === 0 ? <Empty>Đóng dấu chương hộ chiếu đầu tiên để nhận thư.</Empty> : letters.map(l => {
          const n = npc(l.from)
          return (
            <div key={l.id} className="card row" style={{ alignItems: 'flex-start', background: '#fffaf0' }}>
              <PetThumb appearance={n.look} size={48} />
              <div className="small" style={{ flex: 1 }}>
                <b>{n.name}</b> <span className="tiny muted">· sau chương “{CHAPTERS[l.id - 1].name}”</span>
                <p style={{ marginTop: 4 }}>{l.text}</p>
              </div>
            </div>
          )
        })}
      </div>
    </Sheet>
  )
}
