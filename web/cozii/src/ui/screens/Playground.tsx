import { useEffect, useState } from 'react'
import { useGame } from '../../app/game'
import { back, go } from '../../app/router'
import { GAME_IDS, type GameId } from '../../core/state'
import { GAME_INFO } from '../../core/games'
import { SONGS } from '../../games/rhythm'
import { weekKey } from '../../core/time'
import type { LeaderRow } from '../../backend/types'
import { Empty, Icon, ScreenHead } from '../kit'
import { PetThumb } from '../PetCanvas'
import { NpcHeader } from './Places'
import { NATURAL_FUR, type PetSpecies } from '../../content/pet'
import { sfx } from '../../app/sound'

const VARIANTS: Partial<Record<GameId, { id: string; label: string }[]>> = {
  memory: [{ id: 'easy', label: 'Dễ (6 cặp)' }, { id: 'medium', label: 'Vừa (8 cặp)' }],
  rhythm: SONGS.map(s => ({ id: s.id, label: s.name })),
  picnic: [{ id: 'easy', label: 'Giỏ nhỏ' }, { id: 'normal', label: 'Giỏ vừa' }, { id: 'hard', label: 'Giỏ lớn' }],
}

const GAME_COLOR: Record<GameId, string> = {
  cloudJump: 'linear-gradient(135deg,#c9bdf0,#fdebdd)', giftBasket: 'linear-gradient(135deg,#d8e9fb,#c3e2bc)',
  memory: 'linear-gradient(135deg,#ece6fa,#fbe7de)', rhythm: 'linear-gradient(135deg,#e9f4e4,#f2a3b8)',
  runner: 'linear-gradient(135deg,#bfe0f5,#f1e2c4)', picnic: 'linear-gradient(135deg,#eaf4e2,#f8edd3)',
}

export function Playground() {
  const { state, social, online } = useGame()
  const [variant, setVariant] = useState<Partial<Record<GameId, string>>>({ memory: 'easy', rhythm: SONGS[0].id, picnic: 'normal' })
  return (
    <div className="wide-2">
      <div className="stack">
        <ScreenHead title="Sân chơi" onBack={() => back('town')} />
        <NpcHeader id="pip" />
        <p className="small muted">Mỗi lượt hoàn thành hợp lệ cho xu theo điểm (tối đa 12 xu/lượt, 80 xu/ngày) và làm bạn nhỏ vui. Thua không mất gì. Mọi loài có cùng kích thước va chạm, không loài nào có lợi thế.</p>
        <div className="stack" style={{ gap: 10 }}>
          {GAME_IDS.map(g => (
            <div key={g} className="card row" style={{ background: GAME_COLOR[g], alignItems: 'flex-start' }}>
              <div style={{ flex: 1 }}>
                <div className="bold" style={{ fontSize: 17 }}>{GAME_INFO[g].name}</div>
                <div className="small">{GAME_INFO[g].blurb}</div>
                <div className="tiny muted" style={{ marginTop: 4 }}>Kỷ lục: {state.records[g]?.best ?? 0} · đã chơi {state.records[g]?.runs ?? 0} lượt</div>
                {VARIANTS[g] && (
                  <div className="row wrap" style={{ marginTop: 6, gap: 4 }}>
                    {VARIANTS[g]!.map(v => <button key={v.id} className="pill" style={{ minHeight: 30, padding: '3px 10px', fontSize: 12.5 }} aria-pressed={variant[g] === v.id} onClick={() => setVariant({ ...variant, [g]: v.id })}>{v.label}</button>)}
                  </div>
                )}
              </div>
              <div className="stack" style={{ gap: 6 }}>
                <button className="btn primary small" onClick={() => { sfx('tap'); go(`game/${g}/${variant[g] ?? 'normal'}`) }}><Icon.play />Chơi</button>
                {g === 'cloudJump' && <button className="btn small" onClick={() => go('game/cloudJump/weekly')}>Thử thách tuần</button>}
              </div>
            </div>
          ))}
        </div>
      </div>
      <div className="stack">
        {social && online ? <Leaderboard /> : (
          <div className="card small stack" style={{ gap: 6 }}>
            <b>Bảng xếp hạng</b>
            <p className="muted">Bảng xếp hạng chỉ tính lượt chơi được máy chủ kiểm tra, nên cần tài khoản online và có mạng. {state.mode === 'local' ? 'Bạn đang chơi trên máy này.' : 'Bạn đang ngoại tuyến.'}</p>
          </div>
        )}
      </div>
    </div>
  )
}

function Leaderboard() {
  const { social, state, toast } = useGame()
  const [scope, setScope] = useState<'all' | 'weekly' | 'friends' | 'collector'>('weekly')
  const [rows, setRows] = useState<LeaderRow[] | null>(null)
  const [me, setMe] = useState<LeaderRow | null>(null)
  const [err, setErr] = useState<string | null>(null)
  useEffect(() => {
    if (!social) return
    setRows(null)
    setErr(null)
    const p = scope === 'collector' ? social.collectorBoard() : social.leaderboard('cloudJump', scope)
    p.then(r => { setRows(r.rows); setMe(r.me) }).catch(e => setErr(e instanceof Error ? e.message : 'Không tải được.'))
  }, [social, scope])
  return (
    <div className="card stack" style={{ gap: 8 }}>
      <div className="row"><Icon.trophy /><b style={{ flex: 1 }}>Bảng xếp hạng Nhảy Mây</b></div>
      <div className="pill-tabs">
        {([['weekly', 'Tuần này'], ['all', 'Mọi lúc'], ['friends', 'Bạn bè'], ['collector', 'Nhà sưu tầm']] as const).map(([k, l]) => (
          <button key={k} className="pill" aria-pressed={scope === k} onClick={() => setScope(k)}>{l}</button>
        ))}
      </div>
      <p className="tiny muted">
        {scope === 'collector' ? 'Số món ngoại hình khác nhau trong kho, chỉ tính đồ máy chủ đã ghi nhận.' :
          `Chỉ tính lượt máy chủ chạy lại từ seed và nhật ký điều khiển. ${scope === 'weekly' ? `Tuần ${weekKey(Date.now())}: ai cũng chơi cùng một bản đồ.` : ''} Xác minh không đồng nghĩa chặn được bot hoàn toàn.`}
      </p>
      {err && <div className="small muted">{err}</div>}
      {!rows && !err && <div className="small muted">Đang tải…</div>}
      {rows && rows.length === 0 && <Empty>Chưa có ai trên bảng. Bạn là người đầu tiên!</Empty>}
      {rows && rows.length > 0 && (
        <div className="list">
          {rows.map(r => (
            <div key={r.userId} className="list-item" style={r.me ? { background: 'var(--lavender-2)', borderRadius: 12 } : undefined}>
              <b style={{ width: 28, textAlign: 'center' }}>{r.rank <= 3 ? ['🥇', '🥈', '🥉'][r.rank - 1] : r.rank}</b>
              <PetThumb appearance={{ species: r.species as PetSpecies, fur: NATURAL_FUR[r.species as PetSpecies] ?? 'cream', stage: 'grown' }} size={34} />
              <div style={{ flex: 1 }} className="small"><b>{r.name}</b><div className="tiny muted">{r.petName}</div></div>
              <b>{r.score}</b>
            </div>
          ))}
        </div>
      )}
      {me && !rows?.some(r => r.me) && <div className="small">Hạng của bạn: <b>{me.rank}</b> · {me.score}</div>}
      <button className="btn small" onClick={async () => {
        try {
          const r = await social!.claimBadges()
          toast(r.badges.length ? `Nhận huy hiệu: ${r.badges.join(', ')}` : 'Chưa có huy hiệu mới. Huy hiệu tuần được trao sau khi tuần kết thúc.', r.badges.length ? 'good' : 'info')
        } catch (e) {
          toast(e instanceof Error ? e.message : 'Lỗi', 'warn')
        }
      }}>Nhận huy hiệu tuần đã qua</button>
      {state.badges.length > 0 && <div className="tiny muted">Huy hiệu của bạn: {state.badges.join(' · ')}</div>}
    </div>
  )
}
