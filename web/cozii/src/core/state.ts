// Trạng thái một tài khoản — cùng hình dạng với JSON mà máy chủ trả về (hàm SQL cozii_state()).
import type { FurColor, PetSpecies } from '../content/pet'
import type { RoomId, ItemSlot } from '../content/catalog'
import { ECONOMY } from '../content/economy'

export type GameId = 'cloudJump' | 'giftBasket' | 'memory' | 'rhythm' | 'runner' | 'picnic'
export const GAME_IDS: GameId[] = ['cloudJump', 'giftBasket', 'memory', 'rhythm', 'runner', 'picnic']

export type Visibility = 'private' | 'friends' | 'public'

export interface PlacedItem {
  item: string
  flip: boolean
  /** Dịch ngang (đơn vị phòng), |dx| ≤ MAX_NUDGE. */
  dx: number
}

export interface RoomState {
  theme: string
  slots: Partial<Record<ItemSlot, PlacedItem>>
}

export interface Plot {
  idx: number
  crop: string | null
  /** Thời điểm gieo (ms, theo đồng hồ máy chủ). */
  plantedAt: number
  /** Tổng thời gian lớn gốc (giây). */
  growSec: number
  /** Tổng phần trăm đã giảm nhờ tưới. */
  cutPct: number
  selfWatered: boolean
  helps: number
}

export interface Order {
  id: string
  npc: string
  needs: Record<string, number>
  coins: number
  createdAt: number
}

export interface Needs {
  fullness: number
  cleanliness: number
  happiness: number
  asOf: number
}

export interface OutfitPreset {
  name: string
  species: PetSpecies
  fur: FurColor
  wear: Partial<Record<'hat' | 'glasses' | 'neck' | 'outfit' | 'back', string>>
}

export interface LayoutPreset {
  name: string
  theme: string
  slots: Partial<Record<ItemSlot, PlacedItem>>
}

export interface PullResult {
  requestId: string
  series: string
  item: string
  rarity: 'common' | 'rare' | 'special'
  duplicate: boolean
  shards: number
  at: number
}

export interface GameRecord {
  best: number
  runs: number
}

export interface RunTicket {
  id: string
  game: GameId
  seed: number
  rulesVersion: number
  startedAt: number
  expiresAt: number
  weekly: boolean
  ranked: boolean
}

export interface GameState {
  mode: 'local' | 'online'
  version: number
  serverNow: number
  profile: {
    id: string
    name: string
    friendCode: string
    title: string | null
    frame: string | null
    createdAt: number
    isAnonymous: boolean
    onboarded: boolean
  }
  pet: {
    name: string
    species: PetSpecies
    fur: FurColor
    wear: Partial<Record<'hat' | 'glasses' | 'neck' | 'outfit' | 'back', string>>
    needs: Needs
    affection: number
  }
  wallet: { coins: number; tickets: number; shards: number }
  owned: string[]
  stock: Record<string, number>
  home: { rooms: Partial<Record<RoomId, RoomState>> }
  farm: { plots: Plot[]; unlocked: number; freeSeedDay: string | null; tutorialSeedUsed: boolean }
  orders: { list: Order[]; rerollDay: string; rerollsUsed: number; doneDay: string; doneToday: number }
  counters: Record<string, number>
  daily: { day: string; claimed: string[]; bonusClaimed: boolean }
  /** Hạn mức theo ngày (chăm sóc, game, thăm nhà…) — khóa: "<ngày>|<loại>". */
  caps: Record<string, number>
  passport: { claimed: number[] }
  capsule: { pity: Record<string, { sinceRare: number; sinceSpecial: number }>; last: PullResult[]; ticketDay: string; ticketsBought: number }
  titles: string[]
  poses: string[]
  badges: string[]
  presets: { outfits: (OutfitPreset | null)[]; layouts: Partial<Record<RoomId, (LayoutPreset | null)[]>> }
  records: Partial<Record<GameId, GameRecord>>
  social: { visibility: Visibility; shareGarden: boolean; showSources: boolean; publishedAt: number | null }
  onboarding: { storySeen: boolean; tutorial: Record<string, 'done' | 'skipped' | 'later'>; tutorialHidden: boolean }
  /** Lượt chơi đang mở (đã cấp mã, chưa nộp). */
  runs: RunTicket[]
}

export function rankOf(s: GameState): number {
  return Math.min(ECONOMY.maxRank, 1 + s.passport.claimed.length)
}

export function affectionLevel(affection: number): number {
  let lvl = 1
  ECONOMY.affectionLevels.forEach((t, i) => {
    if (affection >= t) lvl = i + 1
  })
  return lvl
}

export function petStage(affection: number): 'little' | 'growing' | 'grown' {
  const l = affectionLevel(affection)
  return l >= 6 ? 'grown' : l >= 3 ? 'growing' : 'little'
}

export function stockOf(s: GameState, id: string): number {
  return s.stock[id] ?? 0
}

/** Thời điểm cây chín (ms). */
export function readyAt(p: Plot): number {
  return p.plantedAt + Math.round(p.growSec * 1000 * (1 - Math.min(ECONOMY.farm.maxCutPct, p.cutPct) / 100))
}
