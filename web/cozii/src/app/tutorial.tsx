import { useGame } from './game'
import { go, useRoute } from './router'
import { PetThumb } from '../ui/PetCanvas'
import { npc } from '../content/town'
import { sfx } from './sound'

export { TUTORIAL, currentStep, type TutorialStep } from '../core/tutorial'
import { TUTORIAL, currentStep, type TutorialStep } from '../core/tutorial'

export function useTutorial(): { step: TutorialStep | null; visible: boolean } {
  const { state } = useGame()
  const step = currentStep(state)
  const visible = !!step && !state.onboarding.tutorialHidden && state.onboarding.tutorial[step.id] !== 'later'
  return { step, visible }
}

/** Gợi ý một bước nhỏ ở cuối màn hình (không che toàn bộ, không khóa game). */
export function Coach() {
  const { state, act } = useGame()
  const route = useRoute()
  const { step, visible } = useTutorial()
  if (!step || !visible) return null
  if (route.path[0] === 'game' || route.path[0] === 'photo') return null
  const here = route.raw === step.where || (step.where === 'home' && route.path.length === 0)
  const guide = npc('tra')
  const idx = TUTORIAL.indexOf(step) + 1
  return (
    <div className="coach" role="status">
      <PetThumb appearance={guide.look} size={40} label={guide.name} />
      <div className="txt">
        <small>Hướng dẫn {idx}/{TUTORIAL.length}</small>
        {step.title}
        <small className="clamp2">{step.hint}</small>
        <div className="row" style={{ gap: 4, marginTop: 4 }}>
          {!here && <button className="btn primary small" onClick={() => { sfx('tap'); go(step.where) }}>{step.whereLabel}</button>}
          <button className="btn ghost small" onClick={() => void act({ type: 'tutorial', step: step.id, status: 'later' }, { quiet: true })}>Để sau</button>
          <button className="btn ghost small" onClick={() => void act({ type: 'tutorial', step: step.id, status: 'skipped' }, { quiet: true })} aria-label={`Bỏ qua bước: ${step.title}`}>Bỏ qua</button>
        </div>
      </div>
      <span className="sr-only">{state.pet.name}</span>
    </div>
  )
}
