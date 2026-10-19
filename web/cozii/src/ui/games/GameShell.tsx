import { useCallback, useEffect, useRef, useState } from 'react'
import { useGame } from '../../app/game'
import { back } from '../../app/router'
import type { GameId, RunTicket } from '../../core/state'
import { GAME_INFO } from '../../core/games'
import { sfx, suspendAudio, resumeAudio, unlockAudio } from '../../app/sound'
import { fitCanvas, useReducedMotion } from '../anim'
import { petAppearance } from '../screens/Home'
import { Coins, Icon } from '../kit'
import type { GameView } from './types'
import { BasketView, CloudJumpView, MemoryView } from './views1'
import { PicnicView, RhythmView, RunnerView, cancelScheduledNotes } from './views2'
import { uuid } from '../../backend/local'

type Phase = 'ready' | 'starting' | 'countdown' | 'playing' | 'paused' | 'submitting' | 'finished'

const HOW_TO: Record<GameId, string[]> = {
  cloudJump: ['Bạn nhỏ tự nảy khi chạm mây. Kéo ngang (hoặc phím ← →) để lái.', 'Né mây giông và chim. Mây viền nét đứt chỉ nảy được một lần.', 'Rơi khỏi màn hình là hết lượt. Điểm = mét + 3 × sao.'],
  giftBasket: ['Kéo ngang (hoặc ← →) để di chuyển giỏ.', 'Hứng trái cây, sao, hộp quà. Hứng liên tục để có combo.', 'Né bùn nâu và mây mưa (có dấu ✕). Lượt dài 60 giây.'],
  memory: ['Chạm (hoặc phím mũi tên + Enter) để lật hai thẻ.', 'Giống nhau thì giữ mở, khác nhau thì úp lại.', 'Ghép hết các cặp là thắng. Ít lượt và nhanh thì nhiều điểm.'],
  rhythm: ['Chạm vào làn (hoặc phím A S D / ← ↓ →) khi nốt nhạc rơi tới bông hoa.', 'Có thể chơi khi tắt tiếng: nhìn nốt chạm bông hoa.', 'Lệch nhịp? Chỉnh độ trễ trong Cài đặt.'],
  runner: ['Vuốt trái/phải (← →) để đổi làn, vuốt lên hoặc chạm (Space) để nhảy.', 'Nhảy qua rào gỗ thấp, tránh xe hàng. Nhặt dâu thêm điểm.', 'Có 3 trái tim. Luôn có ít nhất một làn đi được.'],
  picnic: ['Kéo miếng đồ ăn vào giỏ. Chạm miếng rồi bấm Xoay (phím R) để xoay.', 'Xếp kín mọi ô của giỏ là xong. Không tính giờ.', 'Kẹt thì bấm Gợi ý (phím H), chỉ bớt một ít xu thưởng.'],
}

function makeView(game: GameId, opts: ConstructorParameters<typeof CloudJumpView>[0]): GameView {
  switch (game) {
    case 'cloudJump': return new CloudJumpView(opts)
    case 'giftBasket': return new BasketView(opts)
    case 'memory': return new MemoryView(opts)
    case 'rhythm': return new RhythmView(opts)
    case 'runner': return new RunnerView(opts)
    case 'picnic': return new PicnicView(opts)
  }
}

interface Outcome {
  score: number
  coins: number
  earned: number
  note: string
  newBest: boolean
  best: number
  practice: boolean
  verified?: boolean
}

const NOTE_TEXT: Record<string, string> = {
  rewarded: '',
  belowThreshold: 'Chưa đủ điểm tối thiểu để nhận xu. Thử lại nhé!',
  notCompleted: 'Lượt chưa hoàn thành nên chưa có xu.',
  implausible: 'Kết quả không hợp lệ nên không tính.',
  partialCap: 'Chỉ nhận phần còn lại của hạn mức xu Sân chơi hôm nay.',
  dailyCap: 'Hôm nay đã nhận đủ xu Sân chơi. Kỷ lục vẫn được lưu!',
  practice: 'Lượt luyện tập khi ngoại tuyến: lưu kỷ lục trên máy, không có xu.',
  mismatch: 'Máy chủ chạy lại lượt chơi và cho kết quả khác. Điểm theo máy chủ.',
}

function practiceBest(game: GameId): number {
  try {
    return Number(localStorage.getItem('cozii:practice:' + game) ?? 0) || 0
  } catch {
    return 0
  }
}

export function GameShell({ game, variant, weekly }: { game: GameId; variant?: string; weekly?: boolean }) {
  const { state, act, online } = useGame()
  const reduce = useReducedMotion()
  const [phase, setPhase] = useState<Phase>('ready')
  const [count, setCount] = useState(3)
  const [hud, setHud] = useState<{ label: string; value: string }[]>([])
  const [outcome, setOutcome] = useState<Outcome | null>(null)
  const [size, setSize] = useState({ w: 320, h: 480 })
  const cv = useRef<HTMLCanvasElement>(null)
  const stage = useRef<HTMLDivElement>(null)
  const view = useRef<GameView | null>(null)
  const ticket = useRef<RunTicket | null>(null)
  const runToken = useRef(0)
  const phaseRef = useRef<Phase>('ready')
  phaseRef.current = phase
  const countdownTimer = useRef<number | null>(null)
  const finishRequest = useRef<string | null>(null)
  const info = GAME_INFO[game]
  const rec = state.records[game]

  // Kích thước khung game: vừa màn hình, giữ tỉ lệ, không kéo dãn vô hạn trên máy tính.
  const fit = useCallback(() => {
    const el = stage.current
    if (!el) return
    const aspect = view.current?.aspect ?? 0.62
    const maxW = el.clientWidth - 16, maxH = el.clientHeight - 16
    let w = Math.min(maxW, 520), h = w / aspect
    if (h > maxH) {
      h = maxH
      w = h * aspect
    }
    setSize({ w: Math.floor(w), h: Math.floor(h) })
  }, [])
  useEffect(() => {
    fit()
    window.addEventListener('resize', fit)
    return () => window.removeEventListener('resize', fit)
  }, [fit])

  const clearCountdown = () => {
    if (countdownTimer.current) clearInterval(countdownTimer.current)
    countdownTimer.current = null
  }

  const beginCountdown = useCallback(() => {
    clearCountdown()
    setCount(3)
    setPhase('countdown')
    let n = 3
    countdownTimer.current = window.setInterval(() => {
      n -= 1
      if (n <= 0) {
        clearCountdown()
        setPhase('playing')
        resumeAudio()
      } else {
        setCount(n)
        sfx('tap')
      }
    }, 700)
  }, [])

  const start = async () => {
    unlockAudio()
    cancelScheduledNotes()
    view.current?.dispose()
    runToken.current += 1
    setOutcome(null)
    finishRequest.current = null
    setPhase('starting')
    let seed = Math.floor(Math.random() * 2147483646) + 1
    ticket.current = null
    if (online) {
      const r = await act({ type: 'startRun', game, weekly }, { quiet: true })
      if (r && (r as { run?: RunTicket }).run) {
        ticket.current = (r as { run: RunTicket }).run
        seed = ticket.current.seed
      }
    }
    view.current = makeView(game, { seed, appearance: petAppearance(state), reduceMotion: reduce, variant, sfx })
    fit()
    beginCountdown()
  }

  const pause = useCallback(() => {
    if (phaseRef.current === 'playing' || phaseRef.current === 'countdown') {
      clearCountdown()
      cancelScheduledNotes()
      suspendAudio()
      setPhase('paused')
    }
  }, [])

  // Tự tạm dừng khi app vào nền / mất tiêu điểm.
  useEffect(() => {
    const onHide = () => {
      if (document.hidden) pause()
    }
    document.addEventListener('visibilitychange', onHide)
    window.addEventListener('blur', pause)
    window.addEventListener('pagehide', pause)
    return () => {
      document.removeEventListener('visibilitychange', onHide)
      window.removeEventListener('blur', pause)
      window.removeEventListener('pagehide', pause)
    }
  }, [pause])

  // Dọn dẹp khi rời màn hình.
  useEffect(() => () => {
    clearCountdown()
    cancelScheduledNotes()
    view.current?.dispose()
    view.current = null
    runToken.current += 1
  }, [])

  const finish = useCallback(async (completed: boolean) => {
    const v = view.current
    if (!v) return
    const token = runToken.current
    setPhase('submitting')
    cancelScheduledNotes()
    const result = v.result(completed)
    const t = ticket.current
    if (!t) {
      // Luyện tập (ngoại tuyến): chỉ lưu kỷ lục trên máy.
      const sc = 'score' in result ? (result as { score: number }).score : 0
      const score = result.game === 'cloudJump' ? result.meters + result.stars * 3 : result.game === 'runner' ? result.meters + result.berries * 2 : result.game === 'rhythm' ? result.accuracy * 10 : sc
      const best = Math.max(practiceBest(game), score)
      try { localStorage.setItem('cozii:practice:' + game, String(best)) } catch { /* bỏ qua */ }
      setOutcome({ score, coins: 0, earned: 0, note: 'practice', newBest: score >= best && score > 0, best, practice: true })
      setPhase('finished')
      return
    }
    finishRequest.current = finishRequest.current ?? uuid()
    const r = await act({ type: 'finishRun', run: t.id, result }, { requestId: finishRequest.current })
    if (token !== runToken.current) return // lượt cũ: bỏ qua
    if (!r) {
      setOutcome({ score: 0, coins: 0, earned: 0, note: 'notCompleted', newBest: false, best: rec?.best ?? 0, practice: false })
    } else {
      const o = r as unknown as Outcome & { verified?: boolean }
      setOutcome({ ...o, practice: false })
      if (o.coins > 0) sfx('coin')
      else if (o.newBest) sfx('good')
    }
    setPhase('finished')
  }, [act, game, rec?.best])

  // Vòng lặp khung hình duy nhất: chỉ chạy khi đang chơi/đếm ngược (để vẽ).
  useEffect(() => {
    if (phase !== 'playing' && phase !== 'countdown' && phase !== 'paused') return
    const token = runToken.current
    let raf = 0
    let last = performance.now()
    let hudAt = 0
    const loop = (now: number) => {
      if (token !== runToken.current) return
      raf = requestAnimationFrame(loop)
      const dt = Math.min(0.1, (now - last) / 1000)
      last = now
      const v = view.current
      const c0 = cv.current
      if (!v || !c0) return
      if (phaseRef.current === 'playing') v.step(dt)
      const c = fitCanvas(c0, size.w, size.h)
      v.render(c, size.w, size.h, now / 1000)
      if (now - hudAt > 200) {
        hudAt = now
        setHud(v.hud())
      }
      if (phaseRef.current === 'playing' && v.over()) {
        cancelAnimationFrame(raf)
        void finish(true)
      }
    }
    raf = requestAnimationFrame(loop)
    return () => cancelAnimationFrame(raf)
  }, [phase, size.w, size.h, finish])

  // Vẽ khung tĩnh khi đang ở màn sẵn sàng.
  useEffect(() => {
    if (phase === 'ready' && cv.current) {
      const c = fitCanvas(cv.current, size.w, size.h)
      const v = makeView(game, { seed: 12345, appearance: petAppearance(state), reduceMotion: true, variant, sfx: () => {} })
      v.render(c, size.w, size.h, 0)
      v.dispose()
    }
  }, [phase, size.w, size.h, game, variant, state])

  // Bàn phím
  useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.key === 'Escape' || e.key === 'p') {
        if (phaseRef.current === 'playing') pause()
        return
      }
      if (phaseRef.current !== 'playing') return
      if (['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown', ' '].includes(e.key)) e.preventDefault()
      view.current?.key('down', e.key)
    }
    const up = (e: KeyboardEvent) => {
      if (phaseRef.current === 'playing') view.current?.key('up', e.key)
    }
    window.addEventListener('keydown', down)
    window.addEventListener('keyup', up)
    return () => {
      window.removeEventListener('keydown', down)
      window.removeEventListener('keyup', up)
    }
  }, [pause])

  const ptr = (type: 'down' | 'move' | 'up') => (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (phaseRef.current !== 'playing') return
    const r = e.currentTarget.getBoundingClientRect()
    if (type === 'down') e.currentTarget.setPointerCapture?.(e.pointerId)
    view.current?.pointer(type, e.clientX - r.left, e.clientY - r.top, r.width, r.height)
  }

  const quit = () => {
    runToken.current += 1
    cancelScheduledNotes()
    view.current?.dispose()
    view.current = null
    back('place/playground')
  }

  return (
    <div className="game-root">
      <div className="game-bar">
        <button className="icon-btn" onClick={quit} aria-label="Thoát"><Icon.back /></button>
        <b style={{ flex: 1 }}>{info.name}{weekly ? ' · Thử thách tuần' : ''}</b>
        {phase === 'playing' && <button className="icon-btn" onClick={pause} aria-label="Tạm dừng"><Icon.pause /></button>}
      </div>
      <div className="game-stage" ref={stage}>
        <div style={{ position: 'relative', width: size.w, height: size.h }}>
          <canvas
            ref={cv}
            style={{ width: size.w, height: size.h }}
            onPointerDown={ptr('down')}
            onPointerMove={ptr('move')}
            onPointerUp={ptr('up')}
            onPointerCancel={ptr('up')}
            role="application"
            aria-label={`${info.name}: ${info.blurb}`}
          />
          {(phase === 'playing' || phase === 'paused' || phase === 'countdown') && (
            <div className="hud">{hud.map(h => <span key={h.label} className="chip"><span className="muted tiny">{h.label}</span> {h.value}</span>)}</div>
          )}
          {phase === 'ready' && (
            <div className="game-overlay">
              <div className="game-panel stack">
                <h2 style={{ fontSize: 22, fontWeight: 900 }}>{info.name}</h2>
                <ul style={{ textAlign: 'left', margin: 0, paddingLeft: 18 }} className="small">{HOW_TO[game].map(l => <li key={l}>{l}</li>)}</ul>
                <div className="small muted">Kỷ lục: {rec?.best ?? 0}{!online && ` · luyện tập: ${practiceBest(game)}`}</div>
                {!online && <div className="small" style={{ color: '#9c7424' }}>Đang ngoại tuyến: chơi luyện tập, không có xu và không lên bảng xếp hạng.</div>}
                <button className="btn primary block" onClick={() => void start()}><Icon.play />Bắt đầu</button>
              </div>
            </div>
          )}
          {phase === 'starting' && <div className="game-overlay"><div className="game-panel">Đang chuẩn bị lượt chơi…</div></div>}
          {phase === 'countdown' && <div className="game-overlay" style={{ background: 'rgba(254,246,236,.35)' }}><div className="count-big" key={count}>{count}</div></div>}
          {phase === 'paused' && (
            <div className="game-overlay">
              <div className="game-panel stack">
                <h2 style={{ fontSize: 22, fontWeight: 900 }}>Tạm dừng</h2>
                <button className="btn primary block" onClick={() => { unlockAudio(); beginCountdown() }}>Chơi tiếp</button>
                <button className="btn block" onClick={() => void finish(false)}>Kết thúc lượt</button>
                <p className="tiny muted">Kết thúc giữa chừng sẽ không có xu.</p>
              </div>
            </div>
          )}
          {phase === 'submitting' && <div className="game-overlay"><div className="game-panel">Đang gửi kết quả…</div></div>}
          {phase === 'finished' && outcome && (
            <div className="game-overlay">
              <div className="game-panel stack">
                <h2 style={{ fontSize: 22, fontWeight: 900 }}>{outcome.newBest ? 'Kỷ lục mới!' : 'Xong lượt!'}</h2>
                <div style={{ fontSize: 40, fontWeight: 900, color: 'var(--lavender-deep)' }}>{outcome.score}</div>
                <div className="small muted">Kỷ lục: {outcome.best}</div>
                {outcome.coins > 0 && <div className="bold">+<Coins n={outcome.coins} /></div>}
                {NOTE_TEXT[outcome.note] && <div className="small muted">{NOTE_TEXT[outcome.note]}</div>}
                {outcome.verified && <div className="badge sage" style={{ alignSelf: 'center' }}>Máy chủ đã kiểm tra lượt chơi</div>}
                <div className="row">
                  <button className="btn block" onClick={quit}>Về Sân chơi</button>
                  <button className="btn primary block" onClick={() => void start()}>Chơi lại</button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
