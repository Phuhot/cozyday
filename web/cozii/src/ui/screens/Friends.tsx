import { useCallback, useEffect, useState } from 'react'
import { useGame } from '../../app/game'
import { go } from '../../app/router'
import { NPC_HOMES, npc } from '../../content/town'
import { buildSnapshot } from '../../core/snapshot'
import type { FriendEntry, FriendRequest } from '../../backend/types'
import type { Visibility } from '../../core/state'
import { NATURAL_FUR, type PetSpecies } from '../../content/pet'
import { Empty, Icon, Sheet } from '../kit'
import { PetThumb } from '../PetCanvas'
import { SnapshotView } from './Visit'
import { sfx } from '../../app/sound'
import { AccountCard } from './Account'

const VIS: { id: Visibility; label: string; hint: string }[] = [
  { id: 'private', label: 'Chỉ mình tôi', hint: 'Không ai xem được nhà bạn.' },
  { id: 'friends', label: 'Bạn bè', hint: 'Chỉ bạn bè đã kết bạn xem được bản đã đăng.' },
  { id: 'public', label: 'Công khai', hint: 'Ai cũng có thể thấy nhà bạn trong mục Khám phá.' },
]

function Person({ f, right }: { f: FriendEntry; right?: React.ReactNode }) {
  return (
    <div className="list-item">
      <PetThumb appearance={{ species: f.species as PetSpecies, fur: NATURAL_FUR[f.species as PetSpecies] ?? 'cream', stage: 'grown' }} size={44} />
      <div style={{ flex: 1 }} className="small">
        <b>{f.name}</b>{f.title && <span className="badge" style={{ marginLeft: 6 }}>{f.title}</span>}
        <div className="tiny muted">Bạn nhỏ: {f.petName}</div>
      </div>
      {right}
    </div>
  )
}

export function Friends() {
  const { state, act, social, online, toast } = useGame()
  const [preview, setPreview] = useState(false)
  const [code, setCode] = useState('')
  const [friends, setFriends] = useState<FriendEntry[] | null>(null)
  const [requests, setRequests] = useState<{ incoming: FriendRequest[]; outgoing: FriendRequest[] } | null>(null)
  const [blocked, setBlocked] = useState<FriendEntry[] | null>(null)
  const [discover, setDiscover] = useState<{ homes: FriendEntry[]; next: string | null } | null>(null)
  const [busy, setBusy] = useState(false)

  const refresh = useCallback(async () => {
    if (!social || !online) return
    try {
      const [f, r, b] = await Promise.all([social.listFriends(), social.listRequests(), social.listBlocked()])
      setFriends(f)
      setRequests(r)
      setBlocked(b)
    } catch (e) {
      toast(e instanceof Error ? e.message : 'Không tải được danh sách bạn.', 'warn')
    }
  }, [social, online, toast])
  useEffect(() => { void refresh() }, [refresh])

  const run = async (fn: () => Promise<unknown>, ok?: string) => {
    setBusy(true)
    try {
      await fn()
      if (ok) toast(ok, 'good')
      await refresh()
    } catch (e) {
      toast(e instanceof Error ? e.message : 'Có lỗi xảy ra.', 'warn')
    } finally {
      setBusy(false)
    }
  }

  const loadDiscover = async (cursor: string | null) => {
    if (!social) return
    try {
      const r = await social.discover(cursor)
      setDiscover(d => ({ homes: cursor && d ? [...d.homes, ...r.homes] : r.homes, next: r.next }))
    } catch (e) {
      toast(e instanceof Error ? e.message : 'Không tải được.', 'warn')
    }
  }

  return (
    <div className="wide-2">
      <div className="stack">
        <h1 className="screen-title">Bạn bè</h1>
        <AccountCard />
        {social ? (
          <>
            <div className="card stack" style={{ gap: 8 }}>
              <div className="row">
                <div style={{ flex: 1 }}><div className="tiny muted">Mã bạn bè của bạn</div><div className="bold" style={{ fontSize: 22, letterSpacing: 2 }}>{state.profile.friendCode || '…'}</div></div>
                <button className="btn small" onClick={async () => {
                  try { await navigator.clipboard.writeText(state.profile.friendCode); toast('Đã chép mã.', 'good') } catch { toast('Không chép được, hãy chép tay nhé.') }
                }}><Icon.copy />Chép</button>
              </div>
              <div className="row">
                <input className="input" placeholder="Nhập mã bạn bè" value={code} maxLength={12} onChange={e => setCode(e.target.value.toUpperCase())} aria-label="Mã bạn bè" />
                <button className="btn primary" disabled={busy || code.trim().length < 6 || !online} onClick={() => run(() => social.sendRequest(code.trim()), 'Đã gửi lời mời kết bạn.').then(() => setCode(''))}>Mời</button>
              </div>
              {!online && <div className="tiny muted">Đang ngoại tuyến: danh sách bạn bè sẽ tải lại khi có mạng.</div>}
            </div>

            {requests && requests.incoming.length > 0 && (
              <div className="card"><b className="small">Lời mời kết bạn</b>
                <div className="list">{requests.incoming.map(r => <Person key={r.id} f={r.from} right={<div className="row">
                  <button className="btn small primary" disabled={busy} onClick={() => run(() => social.respondRequest(r.id, true), 'Đã kết bạn!')}>Đồng ý</button>
                  <button className="btn small" disabled={busy} onClick={() => run(() => social.respondRequest(r.id, false))}>Từ chối</button>
                </div>} />)}</div>
              </div>
            )}
            {requests && requests.outgoing.length > 0 && (
              <div className="card"><b className="small">Đang chờ đồng ý</b>
                <div className="list">{requests.outgoing.map(r => <Person key={r.id} f={r.from} right={<span className="tiny muted">đã gửi</span>} />)}</div>
              </div>
            )}

            <div className="card">
              <b className="small">Bạn bè {friends ? `(${friends.length})` : ''}</b>
              {friends == null ? <div className="small muted">Đang tải…</div> : friends.length === 0 ? <div className="small muted" style={{ padding: '8px 0' }}>Chưa có bạn. Gửi mã của bạn cho ai đó, hoặc ghé nhà NPC bên dưới trước nhé.</div> : (
                <div className="list">{friends.map(f => <Person key={f.id} f={f} right={<div className="row">
                  <button className="btn small primary" onClick={() => { sfx('tap'); go('visit/' + f.id) }}>Thăm</button>
                  <button className="btn small" aria-label={`Bỏ kết bạn ${f.name}`} disabled={busy} onClick={() => { if (confirm(`Bỏ kết bạn với ${f.name}?`)) void run(() => social.removeFriend(f.id), 'Đã bỏ kết bạn.') }}><Icon.trash /></button>
                </div>} />)}</div>
              )}
            </div>

            <div className="card stack" style={{ gap: 6 }}>
              <div className="row"><b className="small" style={{ flex: 1 }}>Khám phá nhà công khai</b><button className="btn small" onClick={() => void loadDiscover(null)}>Tải</button></div>
              {discover && discover.homes.length === 0 && <div className="small muted">Chưa có ngôi nhà công khai nào. Số liệu ở đây là người chơi thật, không có nhà giả.</div>}
              {discover && <div className="list">{discover.homes.map(f => <Person key={f.id} f={f} right={<button className="btn small" onClick={() => go('visit/' + f.id)}>Thăm</button>} />)}</div>}
              {discover?.next && <button className="btn small" onClick={() => void loadDiscover(discover.next)}>Xem thêm</button>}
            </div>
          </>
        ) : (
          <div className="card small stack" style={{ gap: 6 }}>
            <b>Thăm nhà bạn bè cần máy chủ</b>
            <p className="muted">Bản này đang chạy ở chế độ chơi trên máy (chưa cấu hình máy chủ Supabase), nên chưa có mã bạn bè, lời mời hay thăm nhà người thật. Nhà mẫu NPC bên dưới vẫn ghé được và vẫn tính cho hộ chiếu.</p>
          </div>
        )}
      </div>

      <div className="stack">
        <div className="card stack" style={{ gap: 8 }}>
          <b>Quyền riêng tư của nhà bạn</b>
          <div className="stack" style={{ gap: 4 }}>
            {VIS.map(v => (
              <label key={v.id} className="row small" style={{ cursor: 'pointer' }}>
                <input type="radio" name="vis" checked={state.social.visibility === v.id} onChange={() => void act({ type: 'setPrivacy', visibility: v.id })} />
                <span><b>{v.label}</b> <span className="muted">· {v.hint}</span></span>
              </label>
            ))}
          </div>
          <label className="row small"><input type="checkbox" checked={state.social.shareGarden} onChange={e => void act({ type: 'setPrivacy', shareGarden: e.target.checked })} /> Cho khách xem vườn (và bạn bè tưới giúp)</label>
          <label className="row small"><input type="checkbox" checked={state.social.showSources} onChange={e => void act({ type: 'setPrivacy', showSources: e.target.checked })} /> Cho khách xem tên món đồ và cách kiếm</label>
          <div className="row">
            <button className="btn" onClick={() => { setPreview(true); void act({ type: 'sharePreview' }, { quiet: true }) }}>Xem trước</button>
            {social && <button className="btn primary" disabled={busy || !online || state.social.visibility === 'private'} onClick={() => run(() => social.publishHome(), 'Đã đăng bản mới nhất của nhà bạn.')}>Đăng nhà</button>}
          </div>
          <p className="tiny muted">Khách chỉ thấy: tên hiển thị, bạn nhỏ và trang phục, bố cục phòng đã đăng, danh hiệu, huy hiệu{state.social.shareGarden ? ' và vườn' : ''}. Không có email, số xu, kho đồ hay lịch sử giao dịch.{state.social.publishedAt ? ` Lần đăng gần nhất: ${new Date(state.social.publishedAt).toLocaleString('vi-VN')}.` : ''}</p>
        </div>

        <div className="card stack" style={{ gap: 4 }}>
          <b className="small">Nhà mẫu NPC <span className="badge peach">không phải người chơi</span></b>
          <div className="list">
            {NPC_HOMES.map(h => {
              const n = npc(h.npc)
              return (
                <div key={h.npc} className="list-item">
                  <PetThumb appearance={n.look} size={44} />
                  <div style={{ flex: 1 }} className="small"><b>Nhà {n.name}</b><div className="tiny muted">{h.note}</div></div>
                  <button className="btn small" onClick={() => go('visit/npc:' + h.npc)}>Ghé</button>
                </div>
              )
            })}
          </div>
        </div>

        {blocked && blocked.length > 0 && social && (
          <div className="card"><b className="small">Đã chặn</b>
            <div className="list">{blocked.map(b => <Person key={b.id} f={b} right={<button className="btn small" onClick={() => run(() => social.unblock(b.id), 'Đã bỏ chặn.')}>Bỏ chặn</button>} />)}</div>
          </div>
        )}
      </div>

      {preview && (
        <Sheet title="Bản nhà sẽ được đăng" onClose={() => setPreview(false)} wide>
          <SnapshotView snap={buildSnapshot(state, Date.now())} isNpc={false} hostId={null} isFriend={false} complimented={false} helped={[]} canHelp={false} coins={0} preview />
        </Sheet>
      )}
    </div>
  )
}
