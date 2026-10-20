import type { Action, ActionResult } from '../core/engine'
import type { GameState, GameId, Visibility } from '../core/state'
import type { HomeSnapshot } from '../core/snapshot'

export interface ActResponse {
  state: GameState
  result: ActionResult
}

export class BackendError extends Error {
  readonly code: string
  /** Lỗi mạng (có thể thử lại cùng mã yêu cầu). */
  readonly network: boolean
  constructor(code: string, message: string, network = false) {
    super(message)
    this.code = code
    this.network = network
  }
}

export interface FriendEntry {
  id: string
  name: string
  petName: string
  species: string
  title: string | null
  friendCode: string
  since?: string
}

export interface FriendRequest {
  id: string
  from: FriendEntry
  createdAt: string
}

export interface InboxEntry {
  kind: 'compliment' | 'help_water' | 'friend'
  from: { id: string; name: string } | null
  sticker?: string
  at: string
}

export interface VisitResult {
  snapshot: HomeSnapshot
  host: FriendEntry
  isFriend: boolean
  coins: number
  complimentedToday: string | null
  helpedPlots: number[]
  helpsLeftToday: number
}

export interface LeaderRow {
  rank: number
  userId: string
  name: string
  petName: string
  species: string
  score: number
  me: boolean
}

export interface Backend {
  readonly kind: 'local' | 'online'
  load(): Promise<GameState>
  act(a: Action, requestId: string): Promise<ActResponse>
}

/** Chức năng chỉ có khi có máy chủ (bạn bè, thăm nhà người thật, bảng xếp hạng). */
export interface SocialApi {
  publishHome(): Promise<{ publishedAt: string }>
  setVisibility(v: Visibility): Promise<void>
  findByCode(code: string): Promise<FriendEntry | null>
  sendRequest(code: string): Promise<void>
  respondRequest(id: string, accept: boolean): Promise<void>
  listFriends(): Promise<FriendEntry[]>
  listRequests(): Promise<{ incoming: FriendRequest[]; outgoing: FriendRequest[] }>
  removeFriend(id: string): Promise<void>
  block(id: string): Promise<void>
  unblock(id: string): Promise<void>
  listBlocked(): Promise<FriendEntry[]>
  report(id: string, reason: string, details: string): Promise<void>
  discover(cursor: string | null): Promise<{ homes: FriendEntry[]; next: string | null }>
  visit(hostId: string): Promise<VisitResult>
  compliment(hostId: string, sticker: string): Promise<void>
  helpWater(hostId: string, plot: number, requestId: string): Promise<{ coins: number }>
  inbox(): Promise<InboxEntry[]>
  leaderboard(game: GameId, scope: 'all' | 'weekly' | 'friends', week?: string): Promise<{ rows: LeaderRow[]; me: LeaderRow | null; week: string }>
  collectorBoard(): Promise<{ rows: LeaderRow[]; me: LeaderRow | null }>
  claimBadges(): Promise<{ badges: string[] }>
}
