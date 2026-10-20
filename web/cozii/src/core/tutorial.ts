// Các bước hướng dẫn bằng thao tác thật. Thuần dữ liệu để test được; giao diện ở app/tutorial.tsx.
import type { GameState } from './state'

export interface TutorialStep {
  id: string
  title: string
  hint: string
  /** Màn hình cần tới. */
  where: string
  whereLabel: string
  done: (s: GameState) => boolean
}

export const TUTORIAL: TutorialStep[] = [
  { id: 'pet', title: 'Chọn và đặt tên bạn nhỏ', hint: 'Đã xong ở phần mở đầu.', where: 'home', whereLabel: 'Nhà mình', done: s => s.profile.onboarded },
  { id: 'place', title: 'Đặt cây nến được tặng', hint: 'Bấm Trang trí, chạm ô đèn rồi chọn Nến thơm.', where: 'home/decorate', whereLabel: 'Trang trí', done: s => (s.counters.place_item ?? 0) > 0 },
  { id: 'feed', title: 'Cho bạn nhỏ ăn', hint: 'Bấm Cho ăn rồi chọn một quả táo.', where: 'home', whereLabel: 'Nhà mình', done: s => (s.counters.feed ?? 0) > 0 },
  { id: 'plant', title: 'Gieo hạt hướng dẫn', hint: 'Vào Vườn rau, chạm một ô đất trống, chọn Hạt mầm hướng dẫn (lớn trong 20 giây).', where: 'farm', whereLabel: 'Vườn rau', done: s => (s.counters.plant ?? 0) > 0 },
  { id: 'game', title: 'Chơi một ván minigame', hint: 'Ở Sân chơi, thử Lật Thẻ mức Dễ, ngắn và dễ thương.', where: 'place/playground', whereLabel: 'Sân chơi', done: s => (s.counters.game_finished ?? 0) > 0 },
  { id: 'harvest', title: 'Thu hoạch cây hướng dẫn', hint: 'Cây chín thì ô đất sáng viền vàng. Chạm để thu hoạch.', where: 'farm', whereLabel: 'Vườn rau', done: s => (s.counters.harvest ?? 0) > 0 },
  { id: 'visit', title: 'Ghé nhà một NPC', hint: 'Ở tab Bạn bè có Nhà mẫu NPC. Ông Trà đang đợi.', where: 'visit/npc:tra', whereLabel: 'Nhà Ông Trà', done: s => (s.counters.visit_npc ?? 0) > 0 },
  { id: 'passport', title: 'Nhận hộ chiếu thị trấn', hint: 'Tới Tòa thị chính, đóng dấu chương 1 để nhận quà và mở phòng ngủ.', where: 'place/hall', whereLabel: 'Tòa thị chính', done: s => s.passport.claimed.includes(1) },
]

export function currentStep(s: GameState): TutorialStep | null {
  if (!s.profile.onboarded) return null
  for (const step of TUTORIAL) {
    if (step.done(s)) continue
    const st = s.onboarding.tutorial[step.id]
    if (st === 'skipped') continue
    return step
  }
  return null
}
