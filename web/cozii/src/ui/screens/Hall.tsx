import { useGame } from '../../app/game'
import { back, go } from '../../app/router'
import { CHAPTERS, dailyTasksFor, npc } from '../../content/town'
import { ECONOMY } from '../../content/economy'
import { derived, taskDone } from '../../core/engine'
import { rankOf } from '../../core/state'
import { dayKey } from '../../core/time'
import { Coins, Icon, Progress, ScreenHead, TicketIcon } from '../kit'
import { NpcHeader } from './Places'
import { sfx } from '../../app/sound'
import { TUTORIAL } from '../../app/tutorial'

export function Hall() {
  const { state, act, toast } = useGame()
  const rank = rankOf(state)
  const nextCh = CHAPTERS.find(c => !state.passport.claimed.includes(c.id))
  const tra = npc('tra')
  const line = nextCh ? (nextCh.id === 1 ? 'Chào cháu. Đây là hộ chiếu thị trấn: mỗi con dấu là một kỷ niệm nhỏ.' : tra.progressLines?.[rank] ?? tra.lines[0]) : 'Hộ chiếu đã kín dấu. Cozii là nhà của cháu rồi.'
  return (
    <div className="wide-2">
      <div className="stack">
        <ScreenHead title="Tòa thị chính" onBack={() => back('town')} />
        <NpcHeader id="tra" line={line} />
        <h2 className="section-title">Hộ chiếu thị trấn · hạng {rank}</h2>
        {CHAPTERS.map(ch => {
          const claimed = state.passport.claimed.includes(ch.id)
          const open = ch.id === 1 || state.passport.claimed.includes(ch.id - 1)
          const done = ch.tasks.filter(t => taskDone(state, t)).length
          const all = done === ch.tasks.length
          return (
            <div key={ch.id} className="card stack" style={{ gap: 8, opacity: open ? 1 : 0.65 }}>
              <div className="row">
                <div className={'stamp' + (claimed ? ' on' : '')} aria-hidden>{claimed ? '🌸' : ch.id}</div>
                <div style={{ flex: 1 }}>
                  <div className="bold">Chương {ch.id}: {ch.name}</div>
                  <div className="muted tiny">{ch.intro}</div>
                </div>
              </div>
              {open && !claimed && (
                <>
                  <Progress value={done / ch.tasks.length} />
                  <div>
                    {ch.tasks.map(t => {
                      const ok = taskDone(state, t)
                      const v = Math.min(t.target, derived(state, t.key))
                      return (
                        <div key={t.id} className="task">
                          <span className={'check' + (ok ? ' on' : '')}>{ok && <Icon.check />}</span>
                          <div style={{ flex: 1 }} className="small">
                            {t.text} {t.target > 1 && <span className="muted">({v}/{t.target})</span>}
                            {t.hint && !ok && <div className="tiny muted">{t.hint}</div>}
                          </div>
                        </div>
                      )
                    })}
                  </div>
                  <div className="row">
                    <span className="small muted" style={{ flex: 1 }}>Quà: <Coins n={ch.reward.coins} /> · {ch.reward.tickets} vé{ch.reward.title ? ` · danh hiệu “${ch.reward.title}”` : ''}{ch.id < 5 ? ` · mở hạng ${ch.id + 1}` : ''}</span>
                    <button className="btn primary small" disabled={!all} onClick={async () => {
                      const r = await act({ type: 'claimChapter', chapter: ch.id })
                      if (r) {
                        sfx('stamp')
                        toast(`Đóng dấu chương ${ch.id}! Hạng thị trấn ${(r as { rank: number }).rank}.`, 'good')
                      }
                    }}>Đóng dấu</button>
                  </div>
                </>
              )}
              {claimed && <div className="small muted">“{ch.outro}”</div>}
            </div>
          )
        })}
      </div>
      <div className="stack">
        <DailyCard />
        <div className="card stack" style={{ gap: 6 }}>
          <b>Hướng dẫn</b>
          <p className="small muted">Mở lại các bước hướng dẫn đã bỏ qua hoặc để sau.</p>
          <button className="btn small" onClick={async () => {
            for (const s of TUTORIAL) if (state.onboarding.tutorial[s.id]) await act({ type: 'tutorial', step: s.id, status: 'reset' }, { quiet: true })
            await act({ type: 'tutorialHidden', hidden: false }, { quiet: true })
            go('home')
          }}>Xem lại hướng dẫn</button>
        </div>
        {state.titles.length > 0 && (
          <div className="card stack" style={{ gap: 6 }}>
            <b>Danh hiệu</b>
            <div className="row wrap">
              <button className="pill" aria-pressed={state.profile.title == null} onClick={() => void act({ type: 'setTitle', title: null })}>Không</button>
              {state.titles.map(t => <button key={t} className="pill" aria-pressed={state.profile.title === t} onClick={() => void act({ type: 'setTitle', title: t })}>{t}</button>)}
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

/** Nhiệm vụ ngày: 3 việc nhỏ, không phạt khi bỏ lỡ. */
export function DailyCard({ compact }: { compact?: boolean }) {
  const { state, act, serverNow, toast } = useGame()
  if (!state.profile.onboarded) return null
  const today = dayKey(serverNow())
  const tasks = dailyTasksFor(state.profile.id, today)
  const claimed = state.daily.day === today ? state.daily.claimed : []
  const bonus = state.daily.day === today && state.daily.bonusClaimed
  return (
    <div className="card stack" style={{ gap: 6 }}>
      <div className="row"><b style={{ flex: 1 }}>Việc nhỏ hôm nay</b><span className="tiny muted">không bắt buộc</span></div>
      {tasks.map(t => {
        const v = state.counters[`d:${today}:${t.key}`] ?? 0
        const done = v >= t.target
        const got = claimed.includes(t.id)
        return (
          <div key={t.id} className="row small">
            <span className={'check' + (got ? ' on' : '')}>{got && <Icon.check />}</span>
            <span style={{ flex: 1 }}>{t.text} {t.target > 1 && <span className="muted">({Math.min(v, t.target)}/{t.target})</span>}</span>
            {got ? <span className="tiny muted">Đã nhận</span> : (
              <button className="btn small" disabled={!done} onClick={async () => {
                const r = await act({ type: 'claimDaily', task: t.id })
                if (r) {
                  sfx('coin')
                  const rr = r as { coins: number; tickets: number }
                  toast(`+${rr.coins} xu${rr.tickets ? ` · +${rr.tickets} vé capsule` : ''}`, 'good')
                }
              }}><Coins n={ECONOMY.daily.coinsPerTask} /></button>
            )}
          </div>
        )
      })}
      {!compact && <div className="tiny muted row"><TicketIcon size={16} /> Xong cả ba: thêm {ECONOMY.daily.allDoneTickets} vé capsule{bonus ? ' (đã nhận)' : ''}. Nhiệm vụ đổi lúc 0 giờ (giờ Việt Nam).</div>}
    </div>
  )
}
