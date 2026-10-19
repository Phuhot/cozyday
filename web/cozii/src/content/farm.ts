// Cây trồng, nông sản, đồ ăn và công thức. Đồ ăn là vật phẩm tiêu hao (mua lặp lại được).
// Thời gian, giá hạt và sản lượng được chốt sau mô phỏng (docs/ECONOMY_VI.md).

export interface Crop {
  id: string            // 'radish'
  name: string
  seedId: string        // 'seed.radish' (kho)
  produceId: string     // 'crop.radish' (kho)
  growSec: number
  seedPrice: number
  yield: number
  sellPrice: number
  rank: number
  /** Màu chính để vẽ. */
  color: number
  leaf: number
  blurb: string
}

export const CROPS: Crop[] = [
  { id: 'radish', name: 'Củ cải hồng', seedId: 'seed.radish', produceId: 'crop.radish', growSec: 90, seedPrice: 2, yield: 1, sellPrice: 4, rank: 1, color: 0xf29bb4, leaf: 0x7fbf7a, blurb: 'Lớn nhanh như thổi. Hợp để chơi một buổi.' },
  { id: 'carrot', name: 'Cà rốt', seedId: 'seed.carrot', produceId: 'crop.carrot', growSec: 300, seedPrice: 5, yield: 2, sellPrice: 5, rank: 1, color: 0xf2a65a, leaf: 0x6fae6a, blurb: 'Năm phút là có hai củ giòn.' },
  { id: 'strawberry', name: 'Dâu tây', seedId: 'seed.strawberry', produceId: 'crop.strawberry', growSec: 900, seedPrice: 10, yield: 3, sellPrice: 7, rank: 1, color: 0xe8566b, leaf: 0x5f9d5c, blurb: 'Mười lăm phút, ba quả đỏ mọng.' },
  { id: 'pumpkin', name: 'Bí ngô', seedId: 'seed.pumpkin', produceId: 'crop.pumpkin', growSec: 2400, seedPrice: 18, yield: 2, sellPrice: 20, rank: 2, color: 0xf0a040, leaf: 0x6f9a52, blurb: 'Bốn mươi phút. Nấu súp rất ngon.' },
  { id: 'corn', name: 'Ngô ngọt', seedId: 'seed.corn', produceId: 'crop.corn', growSec: 7200, seedPrice: 25, yield: 4, sellPrice: 15, rank: 2, color: 0xf6d35e, leaf: 0x7aa860, blurb: 'Hai giờ. Gieo rồi đi chơi đâu đó.' },
  { id: 'sunflower', name: 'Hướng dương', seedId: 'seed.sunflower', produceId: 'crop.sunflower', growSec: 14400, seedPrice: 35, yield: 3, sellPrice: 30, rank: 3, color: 0xf7c843, leaf: 0x6d9a50, blurb: 'Bốn giờ. Sáng mai quay lại là nở rộ.' },
]

/** Cây hướng dẫn: chỉ gieo được một lần trong bước hướng dẫn, lớn trong 20 giây (quy tắc riêng, ghi rõ trong game). */
export const TUTORIAL_CROP: Crop = {
  id: 'sprout', name: 'Mầm hướng dẫn', seedId: 'seed.sprout', produceId: 'crop.radish', growSec: 20, seedPrice: 0, yield: 2,
  sellPrice: 4, rank: 1, color: 0xf29bb4, leaf: 0x7fbf7a, blurb: 'Hạt giống đặc biệt của Ông Trà: lớn trong 20 giây, chỉ có một hạt.',
}

export function crop(id: string): Crop | undefined {
  return id === TUTORIAL_CROP.id ? TUTORIAL_CROP : CROPS.find(c => c.id === id)
}
export function cropByProduce(pid: string): Crop | undefined {
  return CROPS.find(c => c.produceId === pid)
}
export function cropBySeed(sid: string): Crop | undefined {
  return sid === TUTORIAL_CROP.seedId ? TUTORIAL_CROP : CROPS.find(c => c.seedId === sid)
}

export interface Food {
  id: string
  name: string
  /** Giá mua ở Tiệm Bánh (0 = chỉ nấu được). */
  price: number
  fullness: number
  happiness: number
  blurb: string
}

// Món ăn tưởng tượng trong game (không phải hướng dẫn dinh dưỡng cho thú thật).
export const FOODS: Food[] = [
  { id: 'food.apple', name: 'Táo giòn', price: 6, fullness: 18, happiness: 0, blurb: 'Đỏ au, cắn nghe rộp rộp.' },
  { id: 'food.oatcookie', name: 'Bánh yến mạch', price: 12, fullness: 25, happiness: 6, blurb: 'Thơm bơ, giòn tan.' },
  { id: 'food.riceball', name: 'Cơm nắm', price: 16, fullness: 35, happiness: 4, blurb: 'Tròn tròn, có lá rong biển.' },
  { id: 'food.veggiesoup', name: 'Súp rau', price: 24, fullness: 45, happiness: 8, blurb: 'Ấm bụng ngày mưa.' },
  { id: 'food.picnic', name: 'Hộp picnic', price: 50, fullness: 70, happiness: 20, blurb: 'Bánh mì, dâu tây và một tấm khăn kẻ ô.' },
  { id: 'food.carrot', name: 'Cà rốt nướng', price: 0, fullness: 20, happiness: 4, blurb: 'Nấu từ cà rốt nhà trồng.' },
]
export function food(id: string): Food | undefined {
  return FOODS.find(f => f.id === id)
}
export const MAX_FOOD_PER_PURCHASE = 10

export interface Recipe {
  id: string
  output: string
  count: number
  needs: Record<string, number>
  rank: number
}

/** Nấu ở Tiệm Bánh bằng nông sản nhà trồng — rẻ hơn mua sẵn. */
export const RECIPES: Recipe[] = [
  { id: 'recipe.carrot', output: 'food.carrot', count: 1, needs: { 'crop.carrot': 1 }, rank: 1 },
  { id: 'recipe.soup', output: 'food.veggiesoup', count: 1, needs: { 'crop.carrot': 1, 'crop.radish': 2 }, rank: 1 },
  { id: 'recipe.picnic', output: 'food.picnic', count: 1, needs: { 'crop.strawberry': 2, 'crop.corn': 1, 'crop.radish': 1 }, rank: 2 },
]
export function recipe(id: string): Recipe | undefined {
  return RECIPES.find(r => r.id === id)
}

export const STOCK_NAME = (id: string): string => {
  if (id.startsWith('seed.')) return 'Hạt ' + (cropBySeed(id)?.name.toLowerCase() ?? id)
  if (id.startsWith('crop.')) return cropByProduce(id)?.name ?? id
  return food(id)?.name ?? id
}
