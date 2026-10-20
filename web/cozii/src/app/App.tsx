import { useEffect, useState } from 'react'
import { useGame } from './game'
import { go, useRoute } from './router'
import { Coach } from './tutorial'
import { CoinIcon, Icon, TicketIcon } from '../ui/kit'
import { Story } from '../ui/screens/Story'
import { Home } from '../ui/screens/Home'
import { Decorate } from '../ui/screens/Decorate'
import { Wardrobe } from '../ui/screens/Wardrobe'
import { Farm } from '../ui/screens/Farm'
import { Town } from '../ui/screens/Town'
import { Place } from '../ui/screens/Places'
import { Friends } from '../ui/screens/Friends'
import { Visit } from '../ui/screens/Visit'
import { Settings } from '../ui/screens/Settings'
import { Photo } from '../ui/screens/Photo'
import { GameShell } from '../ui/games/GameShell'
import { GAME_IDS, rankOf, type GameId } from '../core/state'
import type { RoomId } from '../content/catalog'
import { sfx, unlockAudio } from './sound'
import { UpdatePrompt } from './pwa'

export function App() {
  const { state, toasts, dismissToast, online, pending, retryPending } = useGame()
  const route = useRoute()
  const [replay, setReplay] = useState(false)
  const needsStory = !state.profile.onboarded || (!state.onboarding.storySeen && !replay && localStorage.getItem('cozii:storyScene') !== null)

  useEffect(() => {
    const unlock = () => unlockAudio()
    window.addEventListener('pointerdown', unlock, { once: true })
    return () => window.removeEventListener('pointerdown', unlock)
  }, [])

  // Cuộn lên đầu khi đổi màn.
  useEffect(() => {
    window.scrollTo(0, 0)
  }, [route.raw])

  if (replay) return <Story replay onDone={() => setReplay(false)} />
  if (needsStory) return <Story onDone={() => go('home', true)} />

  const [p0, p1, p2] = route.path
  if (p0 === 'game' && GAME_IDS.includes(p1 as GameId)) {
    return <GameShell key={route.raw} game={p1 as GameId} variant={p2 === 'weekly' ? undefined : p2} weekly={p2 === 'weekly'} />
  }
  if (p0 === 'photo') return <Photo roomId={(p1 as RoomId) || 'study'} />

  let screen: React.ReactNode
  let tab: 'home' | 'town' | 'friends' = 'home'
  switch (p0) {
    case undefined:
    case 'home':
      if (p1 === 'decorate') screen = <Decorate key={p2} roomId={(p2 as RoomId) || 'study'} />
      else if (p1 === 'wardrobe') screen = <Wardrobe />
      else screen = <Home />
      break
    case 'farm':
      screen = <Farm />
      break
    case 'town':
      tab = 'town'
      screen = <Town />
      break
    case 'place':
      tab = 'town'
      screen = <Place key={p1} id={p1} />
      break
    case 'friends':
      tab = 'friends'
      screen = <Friends />
      break
    case 'visit':
      tab = 'friends'
      screen = <Visit key={p1} target={p1} />
      break
    case 'settings':
      screen = <Settings onReplayStory={() => setReplay(true)} />
      break
    default:
      screen = <Home />
  }

  return (
    <div className="app">
      <nav className="tabbar" aria-label="Điều hướng chính">
        <div className="tabbar-inner">
          {([['home', 'Nhà mình', Icon.home], ['town', 'Thị trấn', Icon.town], ['friends', 'Bạn bè', Icon.friends]] as const).map(([id, label, I]) => (
            <button key={id} className="tab" aria-current={tab === id ? 'page' : undefined} onClick={() => { sfx('tap'); go(id) }}>
              <I />{label}
            </button>
          ))}
        </div>
      </nav>
      <div className="app-body">
        <header className="topbar">
          <span className="brand">Cozii!<small>hạng {rankOf(state)}</small></span>
          <span className="chip" title="Xu"><CoinIcon />{state.wallet.coins}</span>
          <span className="chip" title="Vé capsule"><TicketIcon />{state.wallet.tickets}</span>
          <button className="icon-btn" onClick={() => go('settings')} aria-label="Cài đặt"><Icon.gear /></button>
        </header>
        {(!online || pending) && state.mode === 'online' && (
          <div className="net-banner" role="status">
            <Icon.wifiOff />
            <span style={{ flex: 1 }}>{pending ? 'Có thao tác chờ gửi lại.' : 'Đang ngoại tuyến: xem được nhà, thử đồ, chơi luyện tập.'}</span>
            {pending && <button className="btn small" onClick={() => void retryPending()}>Thử lại</button>}
          </div>
        )}
        {state.mode === 'local' && route.path.length === 0 && <div className="net-banner" style={{ background: 'var(--lavender-2)', color: 'var(--lavender-deep)' }}>Đang chơi trên máy này: dữ liệu lưu trong trình duyệt, chưa xác minh online.</div>}
        <main className="app-main">{screen}</main>
      </div>
      <Coach />
      <UpdatePrompt />
      <div className="toasts" aria-live="polite">
        {toasts.map(t => <div key={t.id} className={'toast ' + t.tone} onClick={() => dismissToast(t.id)}>{t.text}</div>)}
      </div>
    </div>
  )
}
