// Ảnh chụp ngôi nhà để khách xem (bản đã đăng). Chỉ chứa dữ liệu cần để dựng phòng:
// tên hiển thị, pet + trang phục, bố cục các phòng, danh hiệu/huy hiệu và phần vườn được phép.
// KHÔNG chứa email, số dư, lịch sử giao dịch, kho hay toàn bộ dữ liệu.
import type { FurColor, PetSpecies } from '../content/pet'
import type { RoomId, ItemSlot } from '../content/catalog'
import { ROOMS } from '../content/catalog'
import { rankOf, readyAt, petStage, type GameState, type PlacedItem } from './state'

export interface HomeSnapshot {
  v: 1
  name: string
  title: string | null
  badges: string[]
  pet: { name: string; species: PetSpecies; fur: FurColor; wear: Partial<Record<'hat' | 'glasses' | 'neck' | 'outfit' | 'back', string>>; stage: 'little' | 'growing' | 'grown' }
  rooms: { id: RoomId; theme: string; slots: Partial<Record<ItemSlot, PlacedItem>> }[]
  /** null nếu chủ nhà không chia sẻ vườn. */
  garden: { idx: number; crop: string; progress: number; helps: number }[] | null
  showSources: boolean
  publishedAt: number
}

export function buildSnapshot(s: GameState, now: number): HomeSnapshot {
  const rank = rankOf(s)
  return {
    v: 1,
    name: s.profile.name,
    title: s.profile.title,
    badges: s.badges.slice(0, 6),
    pet: { name: s.pet.name, species: s.pet.species, fur: s.pet.fur, wear: { ...s.pet.wear }, stage: petStage(s.pet.affection) },
    rooms: ROOMS.filter(r => r.rank <= rank).map(r => ({
      id: r.id,
      theme: s.home.rooms[r.id]!.theme,
      slots: JSON.parse(JSON.stringify(s.home.rooms[r.id]!.slots)),
    })),
    garden: s.social.shareGarden
      ? s.farm.plots.filter(p => p.crop && p.idx < s.farm.unlocked).map(p => ({
          idx: p.idx,
          crop: p.crop!,
          progress: Math.min(1, Math.max(0, (now - p.plantedAt) / Math.max(1, readyAt(p) - p.plantedAt))),
          helps: p.helps,
        }))
      : null,
    showSources: s.social.showSources,
    publishedAt: now,
  }
}
