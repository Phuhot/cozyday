// Thị trấn Cozii: NPC (nội dung viết sẵn), hộ chiếu, nhiệm vụ ngày và các địa điểm trên bản đồ.
import type { PetAppearance } from './pet'
import type { RoomId, ItemSlot } from './catalog'

// ---------------- NPC ----------------

export interface Npc {
  id: string
  name: string
  role: string
  personality: string
  look: PetAppearance
  /** Câu chào khi gặp (chọn xoay vòng). */
  lines: string[]
  /** Câu nói khi hạng thị trấn tăng (theo hạng). */
  progressLines?: Partial<Record<number, string>>
}

export const NPCS: Npc[] = [
  {
    id: 'tra', name: 'Ông Trà', role: 'Trưởng thị trấn', personality: 'Chậm rãi, hay pha trà, nhớ tên từng người.',
    look: { species: 'capybara', fur: 'cocoa', hat: 'hat.straw', neck: 'neck.bowtie', stage: 'grown' },
    lines: [
      'Trà vừa pha. Ngồi xuống một chút rồi hẵng đi tiếp.',
      'Đèn trong thị trấn sáng thêm một ngọn. Chắc là nhờ cháu.',
      'Không ai ở Cozii phải vội cả.',
    ],
    progressLines: {
      2: 'Phòng ngủ đã sửa xong. Tối nay ngủ ngon nhé.',
      3: 'Bếp nhỏ mở cửa rồi. Mùi bánh lan ra tận quảng trường.',
      4: 'Phòng tắm có nước nóng rồi. Ông đã thử, rất dễ chịu.',
      5: 'Sân trước nhà cháu giờ đủ chỗ cho một bữa tiệc nhỏ.',
      6: 'Ngày hội năm nay vui nhất từ trước tới giờ.',
    },
  },
  {
    id: 'la', name: 'Cô Lá', role: 'Quầy hạt giống', personality: 'Nhanh nhảu, mê cây, nói chuyện bằng dấu chấm than.',
    look: { species: 'frog', fur: 'mint', hat: 'hat.sprout', outfit: 'outfit.overalls', stage: 'grown' },
    lines: [
      'Hạt mới về! Cái nào cũng nảy mầm hết!',
      'Cây không giận nếu cháu quên tưới đâu. Cây chỉ lớn chậm hơn chút thôi.',
      'Củ cải hồng lớn nhanh lắm, thử đi!',
    ],
  },
  {
    id: 'moc', name: 'Bà Mộc', role: 'Tiệm Nội Thất', personality: 'Hiền, khéo tay, thích kể chuyện về từng món đồ.',
    look: { species: 'bear', fur: 'cocoa', glasses: 'glasses.round', outfit: 'outfit.apron', stage: 'grown' },
    lines: [
      'Món nào ở đây cũng có một câu chuyện.',
      'Đặt đồ theo ý mình là được. Nhà là của cháu mà.',
      'Bà vừa đánh bóng lại cái ghế bành. Ngồi thử không?',
    ],
  },
  {
    id: 'may', name: 'Anh Mây', role: 'Tiệm May Mây', personality: 'Điệu đà, khen thật lòng, hơi hay quên.',
    look: { species: 'bunny', fur: 'lilac', hat: 'hat.beret', neck: 'neck.scarf', stage: 'grown' },
    lines: [
      'Màu này hợp với bạn nhỏ của bạn ghê.',
      'Mặc thử thoải mái, không mua cũng không sao.',
      'Hôm qua anh may nhầm một chiếc mũ cho mèo thành mũ cho thỏ. Vẫn đẹp.',
    ],
  },
  {
    id: 'bo', name: 'Bé Bơ', role: 'Bưu tá & bảng đơn hàng', personality: 'Lạch bạch, chăm chỉ, hay đếm.',
    look: { species: 'duck', fur: 'honey', hat: 'hat.cap', back: 'back.backpack', stage: 'little' },
    lines: [
      'Có đơn mới! Không gấp đâu, lúc nào rảnh thì làm.',
      'Một, hai, ba... đủ cà rốt rồi!',
      'Thư của bạn đây. Bơ chưa đọc trộm đâu.',
    ],
  },
  {
    id: 'pip', name: 'Pip', role: 'Sân chơi', personality: 'Tinh nghịch, thích thi đấu nhưng thua cũng cười.',
    look: { species: 'fox', fur: 'ginger', glasses: 'glasses.sun', neck: 'neck.bandana', stage: 'growing' },
    lines: [
      'Chơi một ván không? Thua cũng chẳng mất gì.',
      'Kỷ lục của Pip là... à thôi, bí mật.',
      'Thử thách tuần mới đã có. Ai cũng chơi cùng một bản đồ.',
    ],
  },
]
export function npc(id: string): Npc {
  return NPCS.find(n => n.id === id)!
}

/** Nhà mẫu của NPC — dữ liệu viết sẵn, luôn ghi rõ là NPC, không giả làm người chơi. */
export interface NpcHome {
  npc: string
  room: RoomId
  theme: string
  slots: Partial<Record<ItemSlot, string>>
  garden: { crop: string; stage: number }[]
  note: string
}

export const NPC_HOMES: NpcHome[] = [
  {
    npc: 'tra', room: 'study', theme: 'studyTheme.mint',
    slots: { wall: 'wall.clock', lamp: 'lamp.paper', desk: 'desk.sage', plant: 'plant.bonsai', seat: 'seat.armchair' },
    garden: [{ crop: 'pumpkin', stage: 2 }, { crop: 'corn', stage: 1 }, { crop: 'carrot', stage: 3 }],
    note: 'Nhà mẫu của Ông Trà: gọn gàng, nhiều cây, lúc nào cũng có trà.',
  },
  {
    npc: 'la', room: 'garden', theme: 'gardenTheme.day',
    slots: { tree: 'tree.apple', flowerBed: 'flowerBed.tulip', gardenSeat: 'gardenSeat.bench', pond: 'pond.lily', gardenDeco: 'gardenDeco.birdhouse' },
    garden: [{ crop: 'strawberry', stage: 2 }, { crop: 'radish', stage: 1 }, { crop: 'sunflower', stage: 2 }, { crop: 'carrot', stage: 1 }],
    note: 'Nhà mẫu của Cô Lá: khu vườn là phòng khách.',
  },
  {
    npc: 'moc', room: 'bedroom', theme: 'bedroomTheme.candy',
    slots: { bed: 'bed.wood', nightstand: 'nightstand.lamp', bedroomWall: 'bedroomWall.garland', closet: 'closet.wardrobe', bedroomRug: 'bedroomRug.heart', plush: 'plush.teddy' },
    garden: [{ crop: 'pumpkin', stage: 1 }, { crop: 'strawberry', stage: 3 }],
    note: 'Nhà mẫu của Bà Mộc: món nào cũng do bà tự đóng.',
  },
]

// ---------------- Hộ chiếu ----------------

export interface PassportTask {
  id: string
  text: string
  /** Bộ đếm (counter) hoặc chỉ số suy ra (derived:*). */
  key: string
  target: number
  hint?: string
}

export interface Chapter {
  id: number
  name: string
  intro: string
  tasks: PassportTask[]
  reward: { coins: number; tickets: number; title?: string }
  /** Câu Ông Trà nói khi đóng dấu chương. */
  outro: string
}

export const CHAPTERS: Chapter[] = [
  {
    id: 1, name: 'Dọn vào nhà', intro: 'Một căn nhà nhỏ, một người bạn nhỏ, và vài việc đầu tiên.',
    tasks: [
      { id: 'c1.name', text: 'Đặt tên cho bạn nhỏ', key: 'named', target: 1 },
      { id: 'c1.place', text: 'Đặt món quà đầu tiên vào phòng', key: 'place_item', target: 1, hint: 'Nhà mình → Trang trí' },
      { id: 'c1.feed', text: 'Cho bạn nhỏ ăn', key: 'feed', target: 1, hint: 'Nhà mình → Cho ăn' },
      { id: 'c1.plant', text: 'Gieo một hạt giống', key: 'plant', target: 1, hint: 'Vườn rau → chạm ô đất' },
      { id: 'c1.game', text: 'Chơi hết một lượt minigame', key: 'game_finished', target: 1, hint: 'Thị trấn → Sân chơi' },
      { id: 'c1.harvest', text: 'Thu hoạch lần đầu', key: 'harvest', target: 1 },
      { id: 'c1.visit', text: 'Ghé thăm nhà một NPC', key: 'visit_npc', target: 1, hint: 'Bạn bè → Nhà mẫu NPC' },
    ],
    reward: { coins: 100, tickets: 2 },
    outro: 'Đây là hộ chiếu thị trấn của cháu. Mỗi con dấu là một kỷ niệm. Phòng ngủ đã sửa xong rồi đấy.',
  },
  {
    id: 2, name: 'Mùa gieo hạt đầu tiên', intro: 'Vườn rau bắt đầu xanh. Bé Bơ có vài đơn hàng nho nhỏ.',
    tasks: [
      { id: 'c2.harvest', text: 'Thu hoạch 15 lần', key: 'harvest', target: 15 },
      { id: 'c2.kinds', text: 'Thu hoạch 3 loại cây khác nhau', key: 'derived:harvest_kinds', target: 3 },
      { id: 'c2.orders', text: 'Hoàn thành 2 đơn hàng', key: 'order', target: 2, hint: 'Thị trấn → Bảng đơn hàng' },
      { id: 'c2.plot', text: 'Mở thêm một ô đất', key: 'plot_bought', target: 1 },
      { id: 'c2.cook', text: 'Nấu một món ở Tiệm Bánh', key: 'cook', target: 1 },
      { id: 'c2.water', text: 'Tưới cây 3 lần', key: 'water', target: 3 },
    ],
    reward: { coins: 150, tickets: 2 },
    outro: 'Vườn của cháu làm cả con đường thơm mùi dâu. Bếp nhỏ mở cửa rồi.',
  },
  {
    id: 3, name: 'Người bạn hàng xóm', intro: 'Ở Cozii, ghé nhà nhau là chuyện thường ngày.',
    tasks: [
      { id: 'c3.visits', text: 'Ghé thăm 3 ngôi nhà khác nhau', key: 'derived:homes_visited', target: 3, hint: 'Nhà NPC cũng được tính' },
      { id: 'c3.compliment', text: 'Gửi 3 lời khen', key: 'compliment', target: 3 },
      { id: 'c3.help', text: 'Tưới giúp cây nhà hàng xóm 2 lần', key: 'help_water', target: 2 },
      { id: 'c3.preview', text: 'Xem trước ngôi nhà mình sẽ chia sẻ', key: 'share_preview', target: 1, hint: 'Bạn bè → Quyền riêng tư' },
      { id: 'c3.clean', text: 'Dọn nhà 2 lần', key: 'clean', target: 2 },
    ],
    reward: { coins: 200, tickets: 2 },
    outro: 'Hàng xóm ai cũng nhắc tới nhà cháu. Phòng tắm có nước nóng rồi.',
  },
  {
    id: 4, name: 'Góc nhà có gu', intro: 'Nhà là nơi thể hiện mình. Trang trí theo ý thích nhé.',
    tasks: [
      { id: 'c4.furniture', text: 'Sở hữu 8 món nội thất mua thêm', key: 'derived:furniture_bought', target: 8 },
      { id: 'c4.theme', text: 'Đổi tường & sàn một phòng', key: 'theme_changed', target: 1 },
      { id: 'c4.layout', text: 'Lưu một bố cục phòng yêu thích', key: 'layout_saved', target: 1 },
      { id: 'c4.outfit', text: 'Cho bạn nhỏ mặc 3 món cùng lúc', key: 'derived:wearing', target: 3 },
      { id: 'c4.photo', text: 'Chụp một tấm ảnh', key: 'photo', target: 1, hint: 'Nhà mình → Chụp ảnh' },
      { id: 'c4.affection', text: 'Đạt thân thiết bậc 3', key: 'derived:affection_level', target: 3 },
    ],
    reward: { coins: 250, tickets: 3 },
    outro: 'Bà Mộc nói nhà cháu là ngôi nhà có gu nhất phố. Sân trước đã dọn xong.',
  },
  {
    id: 5, name: 'Ngày hội thị trấn', intro: 'Đèn lồng được treo khắp quảng trường. Cả thị trấn chuẩn bị cho ngày hội.',
    tasks: [
      { id: 'c5.games', text: 'Chơi 4 minigame khác nhau', key: 'derived:games_distinct', target: 4 },
      { id: 'c5.jump', text: 'Đạt 40 điểm ở Nhảy Mây', key: 'best:cloudJump', target: 40 },
      { id: 'c5.orders', text: 'Hoàn thành tổng cộng 10 đơn hàng', key: 'order', target: 10 },
      { id: 'c5.capsule', text: 'Mở 3 capsule', key: 'capsule_pull', target: 3 },
      { id: 'c5.harvest', text: 'Thu hoạch 60 lần', key: 'harvest', target: 60 },
    ],
    reward: { coins: 300, tickets: 3, title: 'Cư dân Cozii' },
    outro: 'Cảm ơn cháu đã ở lại với thị trấn. Từ giờ, Cozii cũng là nhà của cháu.',
  },
]

export function allPassportTasks(): PassportTask[] {
  return CHAPTERS.flatMap(c => c.tasks)
}

// ---------------- Nhiệm vụ ngày (không phạt khi bỏ lỡ) ----------------

export interface DailyTaskDef {
  id: string
  text: string
  key: string
  target: number
}

export const DAILY_POOL: DailyTaskDef[] = [
  { id: 'd.harvest', text: 'Thu hoạch 5 lần', key: 'harvest', target: 5 },
  { id: 'd.game', text: 'Chơi hết một lượt minigame', key: 'game_finished', target: 1 },
  { id: 'd.feed', text: 'Cho bạn nhỏ ăn', key: 'feed', target: 1 },
  { id: 'd.cuddle', text: 'Nựng bạn nhỏ', key: 'cuddle', target: 1 },
  { id: 'd.order', text: 'Giao một đơn hàng', key: 'order', target: 1 },
  { id: 'd.visit', text: 'Ghé thăm một ngôi nhà', key: 'visit', target: 1 },
  { id: 'd.water', text: 'Tưới cây 2 lần', key: 'water', target: 2 },
  { id: 'd.clean', text: 'Dọn nhà', key: 'clean', target: 1 },
  { id: 'd.plant', text: 'Gieo 4 hạt giống', key: 'plant', target: 4 },
]

/** Băm chuỗi 32-bit (FNV-1a) — dùng chung với máy chủ để chọn nhiệm vụ ngày. */
export function fnv1a(s: string): number {
  let h = 0x811c9dc5
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i)
    h = Math.imul(h, 0x01000193) >>> 0
  }
  return h >>> 0
}

/** Ba nhiệm vụ của ngày `day` cho người chơi `uid` (xác định, không ngẫu nhiên phía client). */
export function dailyTasksFor(uid: string, day: string): DailyTaskDef[] {
  const pool = [...DAILY_POOL]
  const picked: DailyTaskDef[] = []
  let h = fnv1a(uid + ':' + day)
  for (let i = 0; i < 3; i++) {
    const idx = h % pool.length
    picked.push(pool.splice(idx, 1)[0])
    h = fnv1a(String(h) + ':' + i)
  }
  return picked
}

// ---------------- Địa điểm trên bản đồ ----------------

export type PlaceId =
  | 'home' | 'farm' | 'market' | 'bakery' | 'furniture' | 'tailor' | 'capsule' | 'orders' | 'playground'
  | 'hall' | 'npc_tra' | 'npc_la' | 'npc_moc'

export interface Place {
  id: PlaceId
  name: string
  npc?: string
  /** Chân công trình trên bản đồ (hệ 100 × 160); nhãn nằm ngay dưới. */
  x: number
  y: number
  blurb: string
}

export const PLACES: Place[] = [
  { id: 'hall', name: 'Tòa thị chính', npc: 'tra', x: 50, y: 42, blurb: 'Hộ chiếu thị trấn, chuyện của Ông Trà.' },
  { id: 'capsule', name: 'Máy capsule', x: 50, y: 64, blurb: 'Quảng trường, có máy quay bộ sưu tập.' },
  { id: 'furniture', name: 'Tiệm Nội Thất', npc: 'moc', x: 20, y: 60, blurb: 'Đồ gỗ, đèn, thảm và tường mới.' },
  { id: 'tailor', name: 'Tiệm May Mây', npc: 'may', x: 80, y: 60, blurb: 'Mũ, kính, áo và phụ kiện.' },
  { id: 'bakery', name: 'Tiệm Bánh', x: 22, y: 90, blurb: 'Mua đồ ăn hoặc nấu từ nông sản.' },
  { id: 'market', name: 'Quầy Hạt Giống', npc: 'la', x: 78, y: 90, blurb: 'Mua hạt, bán nông sản.' },
  { id: 'orders', name: 'Bảng đơn hàng', npc: 'bo', x: 50, y: 90, blurb: 'Bé Bơ cần vài thứ từ vườn.' },
  { id: 'playground', name: 'Sân chơi', npc: 'pip', x: 24, y: 124, blurb: 'Sáu trò chơi nhỏ và bảng xếp hạng.' },
  { id: 'farm', name: 'Vườn rau', x: 76, y: 124, blurb: 'Vườn của bạn, cạnh nhà.' },
  { id: 'npc_moc', name: 'Nhà Bà Mộc (NPC)', npc: 'moc', x: 16, y: 150, blurb: 'Nhà mẫu NPC, ghé xem cho vui.' },
  { id: 'home', name: 'Nhà mình', x: 50, y: 152, blurb: 'Căn nhà cuối con đường.' },
  { id: 'npc_la', name: 'Nhà Cô Lá (NPC)', npc: 'la', x: 84, y: 150, blurb: 'Nhà mẫu NPC, vườn là phòng khách.' },
  { id: 'npc_tra', name: 'Nhà Ông Trà (NPC)', npc: 'tra', x: 50, y: 17, blurb: 'Nhà mẫu NPC sau tòa thị chính.' },
]

// ---------------- Lời khen (sticker có sẵn) ----------------

export const STICKERS = [
  { id: 'warm', text: 'Ấm áp quá', emoji: '☕' },
  { id: 'cute', text: 'Pet dễ thương', emoji: '💗' },
  { id: 'stay', text: 'Muốn ở đây luôn', emoji: '🏡' },
  { id: 'garden', text: 'Vườn đẹp ghê', emoji: '🌻' },
  { id: 'style', text: 'Phối đồ có gu', emoji: '🎀' },
  { id: 'cozy', text: 'Nhìn là thấy thư giãn', emoji: '🌙' },
] as const
export type StickerId = (typeof STICKERS)[number]['id']

export const REPORT_REASONS = [
  { id: 'name', text: 'Tên không phù hợp' },
  { id: 'spam', text: 'Làm phiền / spam' },
  { id: 'other', text: 'Lý do khác' },
] as const
