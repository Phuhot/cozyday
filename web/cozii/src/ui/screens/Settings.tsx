import { useRef, useState } from 'react'
import { useGame } from '../../app/game'
import { back } from '../../app/router'
import { soundEnabled, setSoundEnabled, unlockAudio, playNote, audioContext } from '../../app/sound'
import { getMotionPref, setMotionPref } from '../anim'
import { LocalBackend } from '../../backend/local'
import { ScreenHead } from '../kit'
import { AccountCard } from './Account'
import { ECONOMY } from '../../content/economy'
import { CROPS } from '../../content/farm'
import { formatDuration } from '../../core/time'
import { rhythmOffsetMs } from '../games/views2'

export function Settings({ onReplayStory }: { onReplayStory: () => void }) {
  const { state, act, backend, toast } = useGame()
  const [sound, setSound] = useState(soundEnabled())
  const [motion, setMotion] = useState(getMotionPref())
  const [name, setName] = useState(state.profile.name)
  const [petName, setPetName] = useState(state.pet.name)
  const [offset, setOffset] = useState(rhythmOffsetMs())
  const file = useRef<HTMLInputElement>(null)
  const local = backend instanceof LocalBackend ? backend : null

  const saveOffset = (v: number) => {
    setOffset(v)
    try { localStorage.setItem('cozii:rhythmOffset', String(v)) } catch { /* bỏ qua */ }
  }

  return (
    <div className="stack" style={{ maxWidth: 640 }}>
      <ScreenHead title="Cài đặt" onBack={() => back('home')} />
      <AccountCard />
      <div className="card stack" style={{ gap: 8 }}>
        <b>Tên</b>
        <label className="small">Tên của bạn<input className="input" value={name} maxLength={20} onChange={e => setName(e.target.value)} /></label>
        <label className="small">Tên bạn nhỏ<input className="input" value={petName} maxLength={16} onChange={e => setPetName(e.target.value)} /></label>
        <button className="btn small" onClick={async () => { if (await act({ type: 'setNames', playerName: name, petName })) toast('Đã lưu tên.', 'good') }}>Lưu tên</button>
      </div>
      <div className="card stack" style={{ gap: 8 }}>
        <b>Âm thanh & chuyển động</b>
        <label className="row small"><input type="checkbox" checked={sound} onChange={e => { setSound(e.target.checked); setSoundEnabled(e.target.checked); unlockAudio() }} /> Âm thanh (tự tổng hợp, bật sau lần chạm đầu tiên)</label>
        <div className="small">Chuyển động:</div>
        <div className="row wrap">
          {([['system', 'Theo thiết bị'], ['reduce', 'Giảm chuyển động'], ['full', 'Đầy đủ']] as const).map(([k, l]) => (
            <button key={k} className="pill" aria-pressed={motion === k} onClick={() => { setMotion(k); setMotionPref(k) }}>{l}</button>
          ))}
        </div>
      </div>
      <div className="card stack" style={{ gap: 8 }}>
        <b>Độ trễ Vườn Nốt Nhạc</b>
        <p className="small muted">Nếu bạn luôn chạm muộn/sớm hơn nốt nhạc, chỉnh số này. Dương = máy của bạn trễ (chạm muộn vẫn tính đúng).</p>
        <div className="row">
          <input type="range" min={-250} max={250} step={10} value={offset} onChange={e => saveOffset(Number(e.target.value))} style={{ flex: 1 }} aria-label="Độ trễ (mili giây)" />
          <b style={{ width: 70, textAlign: 'right' }}>{offset} ms</b>
        </div>
        <Calibrate onDone={v => { saveOffset(v); toast(`Đã đặt độ trễ ${v} ms.`, 'good') }} />
      </div>
      <div className="card stack" style={{ gap: 8 }}>
        <b>Cốt truyện & hướng dẫn</b>
        <button className="btn small" onClick={onReplayStory}>Xem lại cốt truyện mở đầu</button>
      </div>
      {local && (
        <div className="card stack" style={{ gap: 8 }}>
          <b>Sao lưu (chơi trên máy)</b>
          <p className="small muted">Dữ liệu chế độ này chỉ nằm trong trình duyệt. Xuất file định kỳ để phòng khi xóa dữ liệu. File chỉ khôi phục được cho chế độ chơi trên máy, không tạo được tài sản online.</p>
          <div className="row wrap">
            <button className="btn small" onClick={() => {
              const blob = new Blob([local.exportBackup()], { type: 'application/json' })
              const a = document.createElement('a')
              a.href = URL.createObjectURL(blob)
              a.download = `cozii-sao-luu-${new Date().toISOString().slice(0, 10)}.json`
              a.click()
            }}>Xuất sao lưu</button>
            <button className="btn small" onClick={() => file.current?.click()}>Khôi phục từ file</button>
            <input ref={file} type="file" accept="application/json" hidden onChange={async e => {
              const f = e.target.files?.[0]
              if (!f) return
              try {
                local.importBackup(await f.text())
                toast('Đã khôi phục. Đang tải lại…', 'good')
                setTimeout(() => location.reload(), 600)
              } catch (err) {
                toast(err instanceof Error ? err.message : 'File không hợp lệ.', 'warn')
              }
            }} />
            <button className="btn small" onClick={() => {
              if (!confirm('Xóa toàn bộ dữ liệu chơi trên máy này? Không hoàn tác được.')) return
              local.reset()
              location.reload()
            }}>Xóa dữ liệu trên máy</button>
          </div>
        </div>
      )}
      {!local && (
        <div className="card stack" style={{ gap: 8 }}>
          <b>Dữ liệu online</b>
          <p className="small muted">Tiến độ được lưu trên máy chủ sau mỗi thao tác. Bạn có thể tải một bản sao để giữ riêng; bản sao này chỉ để xem, không nhập ngược vào tài khoản và không thay đổi số xu hay kho đồ online.</p>
          <button className="btn small" onClick={() => {
            const blob = new Blob([JSON.stringify({ kind: 'cozii-online-copy', exportedAt: new Date().toISOString(), state }, null, 2)], { type: 'application/json' })
            const a = document.createElement('a')
            a.href = URL.createObjectURL(blob)
            a.download = `cozii-ban-sao-${new Date().toISOString().slice(0, 10)}.json`
            a.click()
          }}>Tải bản sao dữ liệu</button>
        </div>
      )}
      <div className="card stack small" style={{ gap: 6 }}>
        <b>Quy tắc phần thưởng</b>
        <ul style={{ margin: 0, paddingLeft: 18 }}>
          <li>Cây lớn theo thời gian thật; tự tưới nhanh hơn {ECONOMY.farm.selfWaterCutPct}% (một lần/vụ), bạn bè tưới giúp mỗi lượt {ECONOMY.farm.helpWaterCutPct}% (tối đa {ECONOMY.farm.maxHelpsPerCrop}). Không có cây chết.</li>
          <li>Cây: {CROPS.map(c => `${c.name} ${formatDuration(c.growSec * 1000)}`).join(', ')}.</li>
          <li>Quầy Hạt Giống trả đủ giá tới khi tiền lãi bán nông sản trong ngày đạt {ECONOMY.farm.marketProfitPerDay} xu; vượt mức thì mua đúng giá vốn hạt (không lỗ). Đơn hàng không bị tính, tối đa {ECONOMY.orders.maxCompletedPerDay} đơn/ngày.</li>
          <li>Minigame: tối đa {ECONOMY.games.maxCoinsPerRun} xu/lượt, {ECONOMY.games.dailyCoinCap} xu/ngày. Thoát giữa chừng không có xu.</li>
          <li>Chăm pet đúng lúc cần: có xu (tối đa {ECONOMY.care.dailyCoinCap}/ngày) và thân thiết (tối đa {ECONOMY.care.dailyAffectionCap}/ngày). Pet không ốm, không bỏ đi.</li>
          <li>Ngày đổi lúc 0 giờ theo giờ Việt Nam.</li>
        </ul>
      </div>
      <p className="tiny muted center">Cozii! · hình vẽ và câu chữ gốc của dự án Cozyday · chế độ {state.mode === 'online' ? 'online' : 'chơi trên máy'}</p>
    </div>
  )
}

/** Đo độ trễ: bấm theo 8 tiếng gõ nhịp. */
function Calibrate({ onDone }: { onDone: (ms: number) => void }) {
  const [running, setRunning] = useState(false)
  const beats = useRef<number[]>([])
  const taps = useRef<number[]>([])
  const start = () => {
    unlockAudio()
    const ctx = audioContext()
    setRunning(true)
    beats.current = []
    taps.current = []
    const t0 = performance.now() + 600
    for (let i = 0; i < 8; i++) {
      const at = t0 + i * 600
      beats.current.push(at)
      setTimeout(() => playNote(880, 0.08, 'square', 0.15), at - performance.now())
    }
    setTimeout(() => {
      setRunning(false)
      const diffs = taps.current.map(t => {
        const nearest = beats.current.reduce((a, b) => (Math.abs(b - t) < Math.abs(a - t) ? b : a), beats.current[0])
        return t - nearest
      }).filter(d => Math.abs(d) < 300)
      if (diffs.length >= 4) {
        diffs.sort((a, b) => a - b)
        onDone(Math.round(diffs[Math.floor(diffs.length / 2)] / 10) * 10)
      }
    }, 600 + 8 * 600 + 400)
    void ctx
  }
  return running
    ? <button className="btn primary block" style={{ minHeight: 70 }} onPointerDown={() => taps.current.push(performance.now())}>Chạm theo tiếng “tích”</button>
    : <button className="btn small" onClick={start}>Đo tự động (8 nhịp)</button>
}
