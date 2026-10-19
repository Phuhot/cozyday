// MỌI CON SỐ KINH TẾ CỦA COZII! nằm ở file này.
// File được sinh sang SQL (scripts/gen-content-sql.ts → supabase/migrations/*_content.sql) để máy chủ dùng đúng cùng số liệu.
// Lý do chọn từng con số: docs/ECONOMY_VI.md (có bảng mô phỏng chạy bằng `npm run sim:economy`).

export const ECONOMY = {
  /** Giá đồ trong Cozii = giá gốc bản iOS × hệ số này (làm tròn 5 xu). */
  priceMultiplier: 3,
  /** Loài pet (chỉ là ngoại hình) đắt hơn một chút. */
  speciesPriceMultiplier: 4,

  start: { coins: 120, tickets: 1 },

  // ---- Hạng thị trấn: 1 + số chương hộ chiếu đã hoàn thành (tối đa 6) ----
  maxRank: 6,

  // ---- Nông trại ----
  farm: {
    startPlots: 4,
    maxPlots: 12,
    /** Giá mở ô thứ 5…12 và hạng cần có. */
    plotPrices: [
      { plot: 5, price: 80, rank: 1 }, { plot: 6, price: 80, rank: 1 },
      { plot: 7, price: 150, rank: 2 }, { plot: 8, price: 150, rank: 2 },
      { plot: 9, price: 250, rank: 3 }, { plot: 10, price: 250, rank: 3 },
      { plot: 11, price: 400, rank: 4 }, { plot: 12, price: 400, rank: 4 },
    ],
    /** Tự tưới: giảm phần trăm tổng thời gian lớn, một lần mỗi vụ. */
    selfWaterCutPct: 15,
    /** Bạn bè tưới giúp: mỗi lượt giảm %, tối đa số lượt mỗi vụ. */
    helpWaterCutPct: 10,
    maxHelpsPerCrop: 2,
    /** Trần tổng mức giảm (%). */
    maxCutPct: 35,
    /** Gói hạt miễn phí: khi hết xu mua hạt và vườn trống. Một lần mỗi ngày. */
    freeSeedPack: { seed: 'seed.radish', count: 4 },
    /** Tối đa số hạt/nông sản/đồ ăn của một loại trong kho. */
    maxStack: 999,
  },

  // ---- Chăm pet ----
  care: {
    floor: 20,
    needsCareBelow: 35,
    /** Dưới mức này chăm mới tăng thân thiết (pet thật sự cần). */
    affectionBelow: 70,
    perHour: { fullness: 3, cleanliness: 2, happiness: 2.5 },
    maxDecayHours: 24,
    initial: { fullness: 80, cleanliness: 85, happiness: 80 },
    cleanTo: 100,
    cuddleGain: 35,
    /** Thời gian vuốt thật (giây) để hoàn thành một lượt nựng; nghỉ quá 0,25 giây giữa hai lần vuốt thì không cộng. */
    cuddleSeconds: 3.5,
    playGain: 15,
    freeMealTo: 55,
    fullEnough: 95,
    cleanEnough: 95,
    /** Thưởng xu khi chăm lúc chỉ số dưới needsCareBelow. */
    coins: { feed: 2, clean: 3, cuddle: 2 },
    rewardedPerKindPerDay: 2,
    dailyCoinCap: 12,
    /** Thân thiết mỗi lần chăm đúng nhu cầu / mỗi lượt chơi hợp lệ, trần mỗi ngày. */
    affectionPerCare: 2,
    affectionPerGame: 1,
    dailyAffectionCap: 12,
  },

  /** Ngưỡng thân thiết của từng bậc (bậc 1 = 0). */
  affectionLevels: [0, 15, 40, 80, 130, 200, 290, 400],

  // ---- Đơn hàng NPC ----
  orders: {
    active: 3,
    /** Thưởng = tổng giá bán nông sản × hệ số, làm tròn 5. */
    rewardMultiplier: 1.5,
    townPointsPerOrder: 1,
    freeRerollsPerDay: 3,
    maxCompletedPerDay: 8,
  },

  // ---- Sân chơi ----
  games: {
    dailyCoinCap: 80,
    maxCoinsPerRun: 12,
    /** Lượt hết hạn nếu không nộp trong khoảng này (giây). */
    runTtlSec: 1800,
  },

  // ---- Nhiệm vụ ngày ----
  daily: { tasks: 3, coinsPerTask: 20, allDoneTickets: 1 },

  // ---- Thăm nhà ----
  social: {
    visitCoins: 3,
    maxRewardedVisitsPerDay: 4,
    helpWaterCoins: 3,
    maxHelpWaterPerDay: 3,
    /** Một lời khen cho mỗi nhà mỗi ngày; tối đa số lời khen gửi mỗi ngày. */
    maxComplimentsPerDay: 10,
    maxFriends: 60,
    maxPendingRequests: 30,
  },

  // ---- Capsule ----
  capsule: {
    ticketPriceCoins: 120,
    maxTicketBuysPerDay: 2,
    rates: { common: 70, rare: 25, special: 5 },
    /** Bảo hiểm: lượt thứ N kể từ lần ra hiếm/đặc biệt chắc chắn ra hiếm trở lên. */
    rarePity: 8,
    /** Lượt thứ N kể từ lần ra đặc biệt chắc chắn ra đặc biệt. */
    specialPity: 30,
    shardsForDuplicate: { common: 4, rare: 10, special: 25 },
    shardCost: { common: 25, rare: 60, special: 150 },
  },

  presets: { outfits: 4, layoutsPerRoom: 2 },
} as const

export type Rarity = 'common' | 'rare' | 'special'
