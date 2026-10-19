// Máy capsule: bốn bộ theo chủ đề, chỉ đồ ngoại hình (không tăng sức mạnh).
// Tỷ lệ, danh sách và bảo hiểm được công khai trong game (màn "Tỷ lệ & quy tắc").
import { ECONOMY, type Rarity } from './economy'

export interface SeriesItem { id: string; rarity: Rarity }

export interface Series {
  id: string
  name: string
  blurb: string
  items: SeriesItem[]
  /** Phần thưởng khi có đủ 8 món. */
  reward: { item: string; title: string; pose: string }
  color: number
}

export const SERIES: Series[] = [
  {
    id: 'moon', name: 'Đêm Trăng Ngủ Ngon', blurb: 'Gối mây, sao sáng và một chiếc mũ phù thủy hơi to.', color: 0x6f62b8,
    items: [
      { id: 'bedroomWall.moon', rarity: 'common' }, { id: 'nightstand.moon', rarity: 'common' },
      { id: 'glasses.star', rarity: 'common' }, { id: 'outfit.pajamas', rarity: 'common' }, { id: 'hat.cloud', rarity: 'common' },
      { id: 'back.bat', rarity: 'rare' }, { id: 'bedroomTheme.galaxy', rarity: 'rare' }, { id: 'hat.wizard', rarity: 'special' },
    ],
    reward: { item: 'studyTheme.night', title: 'Người gác trăng', pose: 'stargaze' },
  },
  {
    id: 'ocean', name: 'Biển Xanh Mát', blurb: 'Sóng nhỏ, vỏ sò và một chú cá voi phun nước.', color: 0x4f9fcf,
    items: [
      { id: 'bathMat.wave', rarity: 'common' }, { id: 'bathToy.whale', rarity: 'common' }, { id: 'glasses.goggles', rarity: 'common' },
      { id: 'neck.lei', rarity: 'common' }, { id: 'bathToy.boat', rarity: 'common' },
      { id: 'outfit.sailor', rarity: 'rare' }, { id: 'sink.shell', rarity: 'rare' }, { id: 'bathTheme.ocean', rarity: 'special' },
    ],
    reward: { item: 'pond.koi', title: 'Bạn của biển', pose: 'splash' },
  },
  {
    id: 'spring', name: 'Vườn Xuân', blurb: 'Hoa nhí, cánh tiên và cây anh đào nở rộ.', color: 0xe891a8,
    items: [
      { id: 'hat.flower', rarity: 'common' }, { id: 'flowerBed.sunflower', rarity: 'common' }, { id: 'gardenSeat.swing', rarity: 'common' },
      { id: 'outfit.dress', rarity: 'common' }, { id: 'plant.tulip', rarity: 'common' },
      { id: 'back.fairy', rarity: 'rare' }, { id: 'tree.sakura', rarity: 'rare' }, { id: 'hat.tiara', rarity: 'special' },
    ],
    reward: { item: 'studyTheme.sakura', title: 'Sứ giả mùa xuân', pose: 'petals' },
  },
  {
    id: 'festival', name: 'Ngày Hội Nhỏ', blurb: 'Bóng bay, đèn lồng giấy và áo yukata xem pháo hoa.', color: 0xe0874f,
    items: [
      { id: 'hat.party', rarity: 'common' }, { id: 'back.balloon', rarity: 'common' }, { id: 'back.lollipop', rarity: 'common' },
      { id: 'gardenDeco.lantern', rarity: 'common' }, { id: 'hat.pumpkin', rarity: 'common' },
      { id: 'outfit.yukata', rarity: 'rare' }, { id: 'hat.antlers', rarity: 'rare' }, { id: 'neck.medal', rarity: 'special' },
    ],
    reward: { item: 'gardenDeco.tent', title: 'Linh hồn lễ hội', pose: 'confetti' },
  },
]

export function series(id: string): Series | undefined {
  return SERIES.find(s => s.id === id)
}
export function seriesOfItem(itemId: string): { series: Series; entry: SeriesItem } | undefined {
  for (const s of SERIES) {
    const entry = s.items.find(i => i.id === itemId)
    if (entry) return { series: s, entry }
  }
  return undefined
}

/** Xác suất từng món (phần trăm) — hiển thị công khai. Mỗi bậc chia đều cho các món cùng bậc. */
export function itemRates(s: Series): { id: string; rarity: Rarity; pct: number }[] {
  const r = ECONOMY.capsule.rates
  return s.items.map(i => {
    const sameTier = s.items.filter(x => x.rarity === i.rarity).length
    return { id: i.id, rarity: i.rarity, pct: Math.round((r[i.rarity] / sameTier) * 100) / 100 }
  })
}

export const RARITY_LABEL: Record<Rarity, string> = { common: 'Thường', rare: 'Hiếm', special: 'Đặc biệt' }
