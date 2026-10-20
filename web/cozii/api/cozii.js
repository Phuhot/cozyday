// SINH TỰ ĐỘNG từ server/api.ts bằng `npm run build:api` — đừng sửa tay. sha:a0dcbf6560576cc2
// server/auth.ts
var HttpError = class extends Error {
  status;
  code;
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
};
var cache = /* @__PURE__ */ new Map();
function supabaseEnv() {
  const url = process.env.SUPABASE_URL ?? process.env.VITE_SUPABASE_URL;
  const key = process.env.SUPABASE_PUBLISHABLE_KEY ?? process.env.VITE_SUPABASE_PUBLISHABLE_KEY ?? process.env.VITE_SUPABASE_ANON_KEY;
  return { url, key };
}
function devAuthAllowed() {
  return process.env.COZII_DEV_AUTH === "1" && !process.env.VERCEL && process.env.NODE_ENV !== "production";
}
var UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
async function authenticate(header) {
  const token = header?.startsWith("Bearer ") ? header.slice(7).trim() : null;
  if (!token) throw new HttpError(401, "auth", "B\u1EA1n ch\u01B0a \u0111\u0103ng nh\u1EADp.");
  if (token.startsWith("dev:")) {
    if (!devAuthAllowed()) throw new HttpError(401, "auth", "Phi\xEAn \u0111\u0103ng nh\u1EADp kh\xF4ng h\u1EE3p l\u1EC7.");
    const [, id, anon] = token.split(":");
    if (!UUID.test(id)) throw new HttpError(401, "auth", "Phi\xEAn \u0111\u0103ng nh\u1EADp kh\xF4ng h\u1EE3p l\u1EC7.");
    return { id, email: anon === "anon" ? null : `${id.slice(0, 6)}@dev.local`, isAnonymous: anon === "anon" };
  }
  const hit = cache.get(token);
  if (hit && hit.until > Date.now()) return hit.user;
  const { url, key } = supabaseEnv();
  if (!url || !key) throw new HttpError(500, "config", "M\xE1y ch\u1EE7 ch\u01B0a c\u1EA5u h\xECnh SUPABASE_URL / publishable key.");
  let res;
  try {
    res = await fetch(`${url.replace(/\/$/, "")}/auth/v1/user`, { headers: { apikey: key, Authorization: `Bearer ${token}` } });
  } catch {
    throw new HttpError(503, "auth_unreachable", "Kh\xF4ng k\u1EBFt n\u1ED1i \u0111\u01B0\u1EE3c d\u1ECBch v\u1EE5 \u0111\u0103ng nh\u1EADp.");
  }
  if (res.status === 401 || res.status === 403) throw new HttpError(401, "auth", "Phi\xEAn \u0111\u0103ng nh\u1EADp \u0111\xE3 h\u1EBFt h\u1EA1n. H\xE3y t\u1EA3i l\u1EA1i trang.");
  if (!res.ok) throw new HttpError(503, "auth_unreachable", "D\u1ECBch v\u1EE5 \u0111\u0103ng nh\u1EADp \u0111ang b\u1EADn.");
  const u = await res.json();
  if (!u.id || !UUID.test(u.id)) throw new HttpError(401, "auth", "Phi\xEAn \u0111\u0103ng nh\u1EADp kh\xF4ng h\u1EE3p l\u1EC7.");
  const user = { id: u.id, email: u.email ?? null, isAnonymous: !!u.is_anonymous };
  cache.set(token, { user, until: Date.now() + 6e4 });
  if (cache.size > 500) cache.delete(cache.keys().next().value);
  return user;
}

// server/ops.ts
import { randomInt, randomUUID } from "node:crypto";

// src/content/economy.ts
var ECONOMY = {
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
      { plot: 5, price: 100, rank: 1 },
      { plot: 6, price: 100, rank: 1 },
      { plot: 7, price: 250, rank: 2 },
      { plot: 8, price: 250, rank: 2 },
      { plot: 9, price: 500, rank: 3 },
      { plot: 10, price: 500, rank: 3 },
      { plot: 11, price: 900, rank: 4 },
      { plot: 12, price: 900, rank: 4 }
    ],
    /**
     * Quầy Hạt Giống trả đủ giá tới khi tiền LÃI (giá bán − giá vốn hạt mỗi quả) trong ngày đạt mức này; sau đó mua
     * đúng giá vốn (hòa vốn, không bao giờ lỗ). Chặn vòng lặp cày củ cải vô hạn. Đơn hàng không bị tính.
     */
    marketProfitPerDay: 250,
    /** Tự tưới: giảm phần trăm tổng thời gian lớn, một lần mỗi vụ. */
    selfWaterCutPct: 15,
    /** Bạn bè tưới giúp: mỗi lượt giảm %, tối đa số lượt mỗi vụ. */
    helpWaterCutPct: 10,
    maxHelpsPerCrop: 2,
    /** Trần tổng mức giảm (%). */
    maxCutPct: 35,
    /** Gói hạt miễn phí: khi hết xu mua hạt và vườn trống. Một lần mỗi ngày. */
    freeSeedPack: { seed: "seed.radish", count: 4 },
    /** Tối đa số hạt/nông sản/đồ ăn của một loại trong kho. */
    maxStack: 999
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
    dailyAffectionCap: 12
  },
  /** Ngưỡng thân thiết của từng bậc (bậc 1 = 0). */
  affectionLevels: [0, 15, 40, 80, 130, 200, 290, 400],
  // ---- Đơn hàng NPC ----
  orders: {
    active: 3,
    /** Thưởng = tổng giá bán nông sản × hệ số, làm tròn 5. */
    rewardMultiplier: 1.4,
    townPointsPerOrder: 1,
    freeRerollsPerDay: 3,
    maxCompletedPerDay: 4
  },
  // ---- Sân chơi ----
  games: {
    dailyCoinCap: 80,
    maxCoinsPerRun: 12,
    /** Lượt hết hạn nếu không nộp trong khoảng này (giây). */
    runTtlSec: 1800
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
    maxPendingRequests: 30
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
    shardCost: { common: 25, rare: 60, special: 150 }
  },
  presets: { outfits: 4, layoutsPerRoom: 2 }
};

// src/content/catalog.ts
var ROWS = [
  ["desk.pine", "desk", "B\xE0n g\u1ED7 th\xF4ng", 0, 1, "M\u1ED9c m\u1EA1c, v\u1EEBa \u0111\u1EE7 cho m\u1ED9t cu\u1ED1n s\u1ED5."],
  ["desk.lavender", "desk", "B\xE0n lavender", 40, 1, "M\xE0u t\xEDm nh\u1EA1t d\u1ECBu m\u1EAFt."],
  ["desk.sage", "desk", "B\xE0n vi\u1EBFt xanh sage", 70, 1, "R\u1ED9ng r\xE3i, c\xF3 ng\u0103n k\xE9o nh\u1ECF."],
  ["seat.rug", "seat", "Th\u1EA3m tr\xF2n kem", 0, 1, "Ch\u1ED7 n\u1EB1m y\xEAu th\xEDch c\u1EE7a m\xE8o."],
  ["seat.cushion", "seat", "\u0110\u1EC7m ng\u1ED3i t\xEDm", 30, 1, "\xCAm nh\u01B0 m\xE2y."],
  ["seat.armchair", "seat", "Gh\u1EBF b\xE0nh nh\u1ECF", 90, 1, "H\u1EE3p \u0111\u1EC3 \u0111\u1ECDc s\xE1ch bu\u1ED5i t\u1ED1i."],
  ["plant.cactus", "plant", "X\u01B0\u01A1ng r\u1ED3ng mini", 0, 1, "Kh\xF4ng c\u1EA7n t\u01B0\u1EDBi nhi\u1EC1u."],
  ["plant.monstera", "plant", "C\xE2y l\xE1 x\u1EBB", 35, 1, "L\xE1 to, xanh m\xE1t."],
  ["plant.tulip", "plant", "Ch\u1EADu tulip", 55, 1, "Ba b\xF4ng hoa nh\u1ECF."],
  ["lamp.candle", "lamp", "N\u1EBFn th\u01A1m", 20, 1, "\xC1nh s\xE1ng \u1EA5m, m\xF9i vani."],
  ["lamp.desk", "lamp", "\u0110\xE8n b\xE0n tr\xF2n", 45, 1, "\u0110\u1EE7 s\xE1ng cho bu\u1ED5i h\u1ECDc mu\u1ED9n."],
  ["lamp.paper", "lamp", "\u0110\xE8n gi\u1EA5y", 75, 1, "Tr\xF2n v\xE0 m\u1EC1m nh\u01B0 m\u1EB7t tr\u0103ng."],
  ["wall.clock", "wall", "\u0110\u1ED3ng h\u1ED3 tr\xF2n", 25, 1, "Nh\u1EAFc nh\u1EB9 r\u1EB1ng th\u1EDDi gian v\u1EABn tr\xF4i."],
  ["wall.poster", "wall", "Tranh \u0111\u1ED3i xanh", 35, 1, "M\u1ED9t bu\u1ED5i s\xE1ng y\xEAn t\u0129nh."],
  ["wall.shelf", "wall", "K\u1EC7 s\xE1ch nh\u1ECF", 60, 1, "Ba cu\u1ED1n s\xE1ch v\xE0 m\u1ED9t ch\u1EADu c\xE2y."],
  ["wall.corkboard", "wall", "B\u1EA3ng ghim \u1EA3nh", 45, 1, "\u1EA2nh k\u1EF7 ni\u1EC7m v\xE0 v\xE0i t\u1EDD gi\u1EA5y nh\u1EDB."],
  ["lamp.mushroom", "lamp", "\u0110\xE8n n\u1EA5m", 55, 1, "Chi\u1EBFc n\u1EA5m \u0111\u1ECF ch\u1EA5m bi t\u1ECFa s\xE1ng."],
  ["desk.computer", "desk", "B\xE0n c\xF3 m\xE1y t\xEDnh", 110, 4, "M\xE0n h\xECnh nh\u1ECF d\xE1n \u0111\u1EA7y sticker."],
  ["plant.bonsai", "plant", "C\xE2y bonsai", 80, 3, "Ki\xEAn nh\u1EABn t\u1EEBng ch\xFAt m\u1ED9t."],
  ["seat.beanbag", "seat", "Gh\u1EBF l\u01B0\u1EDDi", 65, 1, "Ng\u1ED3i xu\u1ED1ng l\xE0 kh\xF4ng mu\u1ED1n d\u1EADy."],
  ["studyTheme.cream", "studyTheme", "Kem \u1EA5m", 0, 1, "T\u01B0\u1EDDng t\xEDm nh\u1EA1t, s\xE0n g\u1ED7 s\xE1ng."],
  ["studyTheme.mint", "studyTheme", "S\u1ECDc b\u1EA1c h\xE0", 40, 1, "T\u01B0\u1EDDng s\u1ECDc xanh m\xE1t, s\xE0n g\u1ED7."],
  ["studyTheme.night", "studyTheme", "\u0110\xEAm sao", 70, 3, "T\u01B0\u1EDDng xanh \u0111\xEAm \u0111i\u1EC3m sao, c\u1EEDa s\u1ED5 c\xF3 tr\u0103ng."],
  ["studyTheme.sakura", "studyTheme", "Hoa anh \u0111\xE0o", 90, 5, "C\xE1nh hoa h\u1ED3ng bay ngo\xE0i c\u1EEDa s\u1ED5."],
  ["bedroomTheme.lilac", "bedroomTheme", "T\xEDm o\u1EA3i h\u01B0\u01A1ng", 0, 1, "D\u1ECBu nh\u1EB9 cho gi\u1EA5c ng\u1EE7."],
  ["bedroomTheme.cloud", "bedroomTheme", "M\xE2y xanh", 40, 1, "T\u01B0\u1EDDng xanh tr\u1EDDi c\xF3 m\xE2y tr\u1EAFng."],
  ["bedroomTheme.candy", "bedroomTheme", "S\u1ECDc k\u1EB9o ng\u1ECDt", 50, 1, "S\u1ECDc h\u1ED3ng tr\u1EAFng nh\u01B0 k\u1EB9o."],
  ["bedroomTheme.galaxy", "bedroomTheme", "Thi\xEAn h\xE0", 100, 5, "Ng\u1EE7 gi\u1EEFa nh\u1EEFng v\xEC sao."],
  ["bed.mat", "bed", "N\u1EC7m \u0111\u01A1n", 0, 1, "N\u1EC7m m\u1ECFng, g\u1ED1i tr\xF2n."],
  ["bed.wood", "bed", "Gi\u01B0\u1EDDng g\u1ED7", 60, 1, "Ch\u0103n k\u1EBB \xF4 \u1EA5m \xE1p."],
  ["bed.canopy", "bed", "Gi\u01B0\u1EDDng r\xE8m", 120, 4, "R\xE8m voan nh\u01B0 trong truy\u1EC7n c\u1ED5 t\xEDch."],
  ["bed.cloud", "bed", "Gi\u01B0\u1EDDng \u0111\xE1m m\xE2y", 150, 7, "M\u1EC1m nh\u01B0 \u0111ang bay."],
  ["nightstand.crate", "nightstand", "Th\xF9ng g\u1ED7", 0, 1, "\u0110\u1EB7t c\u1ED1c n\u01B0\u1EDBc v\xE0 cu\u1ED1n s\xE1ch."],
  ["nightstand.lamp", "nightstand", "T\u1EE7 & \u0111\xE8n ng\u1EE7", 40, 1, "Ch\u1EE5p \u0111\xE8n v\xE0ng d\u1ECBu."],
  ["nightstand.radio", "nightstand", "Radio c\u1ED5", 55, 1, "Ph\xE1t nh\u1EA1c nh\u1EB9 tr\u01B0\u1EDBc khi ng\u1EE7."],
  ["nightstand.moon", "nightstand", "\u0110\xE8n m\u1EB7t tr\u0103ng", 70, 3, "M\u1ED9t v\u1EA7ng tr\u0103ng nh\u1ECF b\xEAn g\u1ED1i."],
  ["bedroomWall.garland", "bedroomWall", "D\xE2y c\u1EDD", 25, 1, "C\u1EDD tam gi\xE1c nhi\u1EC1u m\xE0u."],
  ["bedroomWall.fairy", "bedroomWall", "D\xE2y \u0111\xE8n \u0111om \u0111\xF3m", 45, 1, "L\u1EA5p l\xE1nh m\u1ED7i t\u1ED1i."],
  ["bedroomWall.moon", "bedroomWall", "Tranh tr\u0103ng sao", 50, 1, "Tr\u0103ng khuy\u1EBFt ng\u1EE7 tr\xEAn m\xE2y."],
  ["bedroomWall.dreamcatcher", "bedroomWall", "L\u01B0\u1EDBi b\u1EAFt gi\u1EA5c m\u01A1", 65, 3, "Gi\u1EEF l\u1EA1i nh\u1EEFng gi\u1EA5c m\u01A1 \u0111\u1EB9p."],
  ["closet.dresser", "closet", "T\u1EE7 ng\u0103n k\xE9o", 50, 1, "Ba ng\u0103n tay n\u1EAFm tr\xF2n."],
  ["closet.mirror", "closet", "G\u01B0\u01A1ng \u0111\u1EE9ng", 60, 1, "Ng\u1EAFm b\u1ED9 \u0111\u1ED3 m\u1EDBi."],
  ["closet.wardrobe", "closet", "T\u1EE7 qu\u1EA7n \xE1o", 80, 1, "Hai c\xE1nh, c\xF3 m\xF3c treo kh\u0103n."],
  ["closet.vanity", "closet", "B\xE0n trang \u0111i\u1EC3m", 95, 4, "G\u01B0\u01A1ng tr\xF2n vi\u1EC1n \u0111\xE8n."],
  ["bedroomRug.round", "bedroomRug", "Th\u1EA3m tr\xF2n", 0, 1, "Th\u1EA3m len m\u1EC1m."],
  ["bedroomRug.heart", "bedroomRug", "Th\u1EA3m tr\xE1i tim", 35, 1, "H\u1ED3ng v\xE0 l\xF4ng x\xF9."],
  ["bedroomRug.cloud", "bedroomRug", "Th\u1EA3m m\xE2y", 45, 1, "B\u01B0\u1EDBc ch\xE2n l\xEAn m\xE2y."],
  ["bedroomRug.rainbow", "bedroomRug", "Th\u1EA3m c\u1EA7u v\u1ED3ng", 70, 3, "B\u1EA3y s\u1EAFc d\u01B0\u1EDBi ch\xE2n."],
  ["plush.yarn", "plush", "Cu\u1ED9n len", 15, 1, "\u0110\u1ED3 ch\u01A1i y\xEAu th\xEDch mu\xF4n thu\u1EDF."],
  ["plush.ball", "plush", "B\xF3ng s\u1ECDc", 20, 1, "L\u0103n l\xF4ng l\u1ED1c kh\u1EAFp ph\xF2ng."],
  ["plush.teddy", "plush", "G\u1EA5u b\xF4ng", 40, 1, "B\u1EA1n ng\u1EE7 c\xF9ng m\u1ED7i \u0111\xEAm."],
  ["plush.dino", "plush", "Kh\u1EE7ng long b\xF4ng", 60, 3, "Hung d\u1EEF\u2026 m\u1ED9t ch\xFAt x\xEDu."],
  ["kitchenTheme.mint", "kitchenTheme", "G\u1EA1ch b\u1EA1c h\xE0", 0, 2, "G\u1EA1ch men xanh nh\u1EA1t."],
  ["kitchenTheme.gingham", "kitchenTheme", "Ca r\xF4 \u0111\u1ECF", 45, 2, "Nh\u01B0 m\u1ED9t bu\u1ED5i d\xE3 ngo\u1EA1i."],
  ["kitchenTheme.lemon", "kitchenTheme", "Chanh v\xE0ng", 55, 2, "T\u01B0\u1EDDng v\xE0ng chanh t\u01B0\u01A1i s\xE1ng."],
  ["kitchenTheme.wood", "kitchenTheme", "G\u1ED7 \u1EA5m", 75, 3, "\u1ED0p g\u1ED7 ki\u1EC3u nh\xE0 g\u1ED7 tr\xEAn n\xFAi."],
  ["stove.basic", "stove", "B\u1EBFp nh\u1ECF", 0, 2, "Hai b\u1EBFp v\xE0 m\u1ED9t chi\u1EBFc n\u1ED3i."],
  ["stove.retro", "stove", "B\u1EBFp c\u1ED5 \u0111i\u1EC3n", 70, 2, "M\xE0u kem, n\xFAm xoay tr\xF2n."],
  ["stove.oven", "stove", "L\xF2 n\u01B0\u1EDBng b\xE1nh", 90, 4, "M\xF9i b\xE1nh quy th\u01A1m l\u1EEBng."],
  ["stove.hearth", "stove", "B\u1EBFp c\u1EE7i", 110, 6, "L\u1EEDa reo t\xED t\xE1ch."],
  ["fridge.mini", "fridge", "T\u1EE7 l\u1EA1nh mini", 30, 2, "V\u1EEBa \u0111\u1EE7 s\u1EEFa v\xE0 tr\xE1i c\xE2y."],
  ["fridge.retro", "fridge", "T\u1EE7 l\u1EA1nh retro", 70, 2, "Bo tr\xF2n m\xE0u xanh ng\u1ECDc."],
  ["fridge.pink", "fridge", "T\u1EE7 l\u1EA1nh h\u1ED3ng", 80, 3, "M\xE0u h\u1ED3ng s\u1EEFa d\xE2u."],
  ["fridge.magnets", "fridge", "T\u1EE7 l\u1EA1nh nam ch\xE2m", 95, 4, "D\xE1n \u0111\u1EA7y nam ch\xE2m v\xE0 tranh v\u1EBD."],
  ["dining.stool", "dining", "B\xE0n \u0111\u1EA9u", 0, 2, "B\xE0n th\u1EA5p v\xE0 m\u1ED9t chi\u1EBFc \u0111\u1EA9u."],
  ["dining.round", "dining", "B\xE0n tr\xF2n", 50, 2, "Hai gh\u1EBF t\u1EF1a nh\u1ECF."],
  ["dining.picnic", "dining", "B\xE0n kh\u0103n ca r\xF4", 65, 3, "Kh\u0103n tr\u1EA3i b\xE0n \u0111\u1ECF tr\u1EAFng."],
  ["dining.long", "dining", "B\xE0n d\xE0i c\xF3 n\u1EBFn", 100, 5, "Cho nh\u1EEFng b\u1EEFa t\u1ED1i th\u1EADt \u0111\u1EB7c bi\u1EC7t."],
  ["kitchenWall.clock", "kitchenWall", "\u0110\u1ED3ng h\u1ED3 tr\xE1i chanh", 30, 2, "T\xEDch t\u1EAFc v\u1ECB chua."],
  ["kitchenWall.pans", "kitchenWall", "Gi\xE1 treo n\u1ED3i", 35, 2, "Ch\u1EA3o, mu\xF4i, x\u1EBBng \u0111\u1EE7 c\u1EA3."],
  ["kitchenWall.fruit", "kitchenWall", "Tranh tr\xE1i c\xE2y", 40, 2, "L\xEA, t\xE1o v\xE0 ch\xF9m nho."],
  ["kitchenWall.jars", "kitchenWall", "K\u1EC7 h\u0169 gia v\u1ECB", 45, 3, "H\u0169 k\u1EB9o, h\u0169 b\xE1nh, h\u0169 tr\xE0."],
  ["treat.tea", "treat", "\u1EA4m tr\xE0", 15, 2, "Tr\xE0 n\xF3ng v\xE0 m\u1ED9t chi\u1EBFc t\xE1ch."],
  ["treat.bread", "treat", "Gi\u1ECF b\xE1nh m\xEC", 25, 2, "B\xE1nh m\xEC m\u1EDBi ra l\xF2."],
  ["treat.ramen", "treat", "B\xE1t m\xEC", 30, 2, "C\xF3 tr\u1EE9ng v\xE0 h\xE0nh l\xE1."],
  ["treat.pizza", "treat", "Pizza", 35, 3, "M\u1ED9t l\xE1t \u0111\xE3 b\u1ECB \u0103n m\u1EA5t."],
  ["treat.cake", "treat", "B\xE1nh kem d\xE2u", 40, 3, "M\u1EEBng m\u1ED9t ng\xE0y l\xE0m vi\u1EC7c t\u1ED1t."],
  ["bathTheme.aqua", "bathTheme", "G\u1EA1ch xanh n\u01B0\u1EDBc", 0, 3, "M\xE1t v\xE0 s\u1EA1ch s\u1EBD."],
  ["bathTheme.pink", "bathTheme", "G\u1EA1ch h\u1ED3ng", 40, 3, "H\u1ED3ng ph\u1EA5n d\u1EC5 th\u01B0\u01A1ng."],
  ["bathTheme.ocean", "bathTheme", "\u0110\u1EA1i d\u01B0\u01A1ng", 70, 4, "S\xF3ng v\xE0 bong b\xF3ng tr\xEAn t\u01B0\u1EDDng."],
  ["bathTheme.marble", "bathTheme", "\u0110\xE1 c\u1EA9m th\u1EA1ch", 90, 5, "Sang tr\u1ECDng nh\u01B0 spa."],
  ["tub.basin", "tub", "Ch\u1EADu t\u1EAFm g\u1ED7", 0, 3, "Ch\u1EADu tr\xF2n ki\u1EC3u su\u1ED1i n\u01B0\u1EDBc n\xF3ng."],
  ["tub.shower", "tub", "V\xF2i sen", 60, 3, "R\xE8m t\u1EAFm ch\u1EA5m bi."],
  ["tub.claw", "tub", "B\u1ED3n t\u1EAFm ch\xE2n", 80, 3, "B\u1ED3n s\u1EE9 tr\u1EAFng c\xF3 ch\xE2n."],
  ["tub.bubble", "tub", "B\u1ED3n \u0111\u1EA7y b\u1ECDt", 100, 5, "B\u1ECDt x\xE0 ph\xF2ng tr\xE0n ra ngo\xE0i."],
  ["sink.basic", "sink", "B\u1ED3n r\u1EEDa", 0, 3, "B\u1ED3n r\u1EEDa tay v\xE0 c\u1ED1c b\xE0n ch\u1EA3i."],
  ["sink.mirror", "sink", "B\u1ED3n r\u1EEDa & g\u01B0\u01A1ng", 45, 3, "G\u01B0\u01A1ng tr\xF2n vi\u1EC1n g\u1ED7."],
  ["sink.shell", "sink", "G\u01B0\u01A1ng v\u1ECF s\xF2", 75, 4, "Nh\u01B0 n\xE0ng ti\xEAn c\xE1."],
  ["bathShelf.towels", "bathShelf", "K\u1EC7 kh\u0103n", 25, 3, "Kh\u0103n g\u1EA5p g\u1ECDn ba m\xE0u."],
  ["bathShelf.bottles", "bathShelf", "K\u1EC7 chai l\u1ECD", 35, 3, "D\u1EA7u g\u1ED9i, s\u1EEFa t\u1EAFm, n\u1EBFn th\u01A1m."],
  ["bathShelf.fern", "bathShelf", "K\u1EC7 d\u01B0\u01A1ng x\u1EC9", 45, 4, "C\xE2y th\xEDch h\u01A1i \u1EA9m."],
  ["bathMat.basic", "bathMat", "Th\u1EA3m ch\xE2n", 0, 3, "Th\u1EA3m b\xF4ng h\xFAt n\u01B0\u1EDBc."],
  ["bathMat.duck", "bathMat", "Th\u1EA3m v\u1ECBt v\xE0ng", 30, 3, "H\xECnh ch\xFA v\u1ECBt nh\u1ECF."],
  ["bathMat.wave", "bathMat", "Th\u1EA3m s\xF3ng", 40, 4, "Xanh nh\u01B0 bi\u1EC3n."],
  ["bathToy.duck", "bathToy", "V\u1ECBt cao su", 10, 3, "K\xEAu ch\xEDt ch\xEDt."],
  ["bathToy.boat", "bathToy", "Thuy\u1EC1n gi\u1EA5y", 20, 3, "Ra kh\u01A1i trong b\u1ED3n t\u1EAFm."],
  ["bathToy.bubbles", "bathToy", "Bong b\xF3ng x\xE0 ph\xF2ng", 25, 3, "Bay l\u01A1 l\u1EEDng kh\u1EAFp ph\xF2ng."],
  ["bathToy.whale", "bathToy", "C\xE1 voi phun n\u01B0\u1EDBc", 45, 4, "Phun m\u1ED9t tia n\u01B0\u1EDBc nh\u1ECF."],
  ["gardenTheme.day", "gardenTheme", "Ng\xE0y n\u1EAFng", 0, 4, "Tr\u1EDDi xanh, m\xE2y tr\u1EAFng, c\u1ECF non."],
  ["gardenTheme.sunset", "gardenTheme", "Ho\xE0ng h\xF4n", 50, 4, "Tr\u1EDDi cam h\u1ED3ng cu\u1ED1i ng\xE0y."],
  ["gardenTheme.night", "gardenTheme", "\u0110\xEAm \u0111om \u0111\xF3m", 80, 5, "Tr\u0103ng tr\xF2n v\xE0 \u0111om \u0111\xF3m."],
  ["gardenTheme.snow", "gardenTheme", "M\xF9a \u0111\xF4ng", 100, 6, "Tuy\u1EBFt ph\u1EE7 tr\u1EAFng khu v\u01B0\u1EDDn."],
  ["tree.sapling", "tree", "C\xE2y non", 0, 4, "R\u1ED3i s\u1EBD l\u1EDBn, nh\u01B0 b\u1EA1n."],
  ["tree.apple", "tree", "C\xE2y t\xE1o", 60, 4, "T\xE1o \u0111\u1ECF ch\xEDn m\u1ECDng."],
  ["tree.pine", "tree", "C\xE2y th\xF4ng", 70, 5, "Xanh quanh n\u0103m."],
  ["tree.sakura", "tree", "C\xE2y anh \u0111\xE0o", 100, 6, "Hoa h\u1ED3ng ph\u1EE7 k\xEDn c\xE0nh."],
  ["flowerBed.daisy", "flowerBed", "Hoa c\xFAc", 0, 4, "C\xFAc tr\u1EAFng nh\u1EE5y v\xE0ng."],
  ["flowerBed.tulip", "flowerBed", "Lu\u1ED1ng tulip", 40, 4, "\u0110\u1ECF, v\xE0ng v\xE0 h\u1ED3ng."],
  ["flowerBed.mushroom", "flowerBed", "N\u1EA5m \u0111\u1ECF", 45, 4, "N\u1EA5m ch\u1EA5m bi m\u1ECDc sau m\u01B0a."],
  ["flowerBed.sunflower", "flowerBed", "H\u01B0\u1EDBng d\u01B0\u01A1ng", 55, 5, "Lu\xF4n quay v\u1EC1 ph\xEDa m\u1EB7t tr\u1EDDi."],
  ["gardenSeat.stump", "gardenSeat", "G\u1ED1c c\xE2y", 0, 4, "Gh\u1EBF t\u1EF1 nhi\xEAn."],
  ["gardenSeat.bench", "gardenSeat", "Gh\u1EBF b\u0103ng", 50, 4, "Ng\u1ED3i ng\u1EAFm m\xE2y tr\xF4i."],
  ["gardenSeat.swing", "gardenSeat", "X\xEDch \u0111u", 85, 5, "\u0110ung \u0111\u01B0a nh\xE8 nh\u1EB9."],
  ["gardenSeat.hammock", "gardenSeat", "V\xF5ng", 95, 6, "Ng\u1EE7 tr\u01B0a gi\u1EEFa v\u01B0\u1EDDn."],
  ["pond.puddle", "pond", "V\u0169ng n\u01B0\u1EDBc", 0, 4, "\u0110\u1EC3 nh\u1EA3y v\xE0o sau c\u01A1n m\u01B0a."],
  ["pond.lily", "pond", "H\u1ED3 hoa s\xFAng", 60, 4, "C\xF3 m\u1ED9t ch\xFA \u1EBFch ng\u1ED3i ch\u01A1i."],
  ["pond.koi", "pond", "H\u1ED3 c\xE1 koi", 90, 5, "Hai ch\xFA c\xE1 \u0111\u1ECF tr\u1EAFng."],
  ["pond.fountain", "pond", "\u0110\xE0i phun n\u01B0\u1EDBc", 110, 6, "N\u01B0\u1EDBc reo r\xF3c r\xE1ch."],
  ["gardenDeco.fence", "gardenDeco", "H\xE0ng r\xE0o g\u1ED7", 20, 4, "R\xE0o tr\u1EAFng nh\u1ECF xinh."],
  ["gardenDeco.mailbox", "gardenDeco", "H\u1ED9p th\u01B0", 30, 4, "Ch\u1EDD th\u01B0 t\u1EEB b\u1EA1n b\xE8."],
  ["gardenDeco.birdhouse", "gardenDeco", "Nh\xE0 chim", 40, 4, "C\xF3 ch\xFA chim v\xE0ng gh\xE9 th\u0103m."],
  ["gardenDeco.lantern", "gardenDeco", "\u0110\xE8n l\u1ED3ng gi\u1EA5y", 50, 5, "S\xE1ng d\u1ECBu khi tr\u1EDDi t\u1ED1i."],
  ["gardenDeco.tent", "gardenDeco", "L\u1EC1u c\u1EAFm tr\u1EA1i", 120, 7, "C\u1EAFm tr\u1EA1i ngay trong v\u01B0\u1EDDn."],
  ["species.cat", "species", "M\xE8o", 0, 1, "Tai nh\u1ECDn, \u0111u\xF4i cong, th\xEDch n\u1EB1m th\u1EA3m."],
  ["species.bunny", "species", "Th\u1ECF", 60, 2, "Tai d\xE0i, \u0111u\xF4i b\xF4ng, nh\u1EA3y l\xF2 c\xF2 khi vui."],
  ["species.hamster", "species", "Hamster", 70, 3, "M\xE1 ph\xFAng ph\xEDnh, gi\u1EA5u h\u1EA1t trong m\xE1."],
  ["species.bear", "species", "G\u1EA5u nh\u1ECF", 80, 4, "Tai tr\xF2n, m\xF5m s\xE1ng m\xE0u, r\u1EA5t th\xEDch m\u1EADt ong."],
  ["species.fox", "species", "C\xE1o", 100, 6, "\u0110u\xF4i x\xF9 ch\xF3p tr\u1EAFng, t\xF2 m\xF2 m\u1ECDi th\u1EE9."],
  ["species.puppy", "species", "C\xFAn con", 80, 2, "Tai c\u1EE5p, \u0111u\xF4i ngo\xE1y t\xEDt khi g\u1EB7p b\u1EA1n."],
  ["species.duck", "species", "V\u1ECBt con", 60, 2, "M\u1ECF cam, l\u1EA1ch b\u1EA1ch theo b\u1EA1n kh\u1EAFp nh\xE0."],
  ["species.frog", "species", "\u1EBEch xanh", 70, 3, "\u1ED8p \u1ED9p, th\xEDch ng\u1ED3i tr\xEAn l\xE1 s\xFAng."],
  ["species.capybara", "species", "Capybara", 90, 3, "B\xECnh th\u1EA3n tr\u01B0\u1EDBc m\u1ECDi chuy\u1EC7n, m\xEA t\u1EAFm su\u1ED1i n\u01B0\u1EDBc n\xF3ng."],
  ["species.panda", "species", "G\u1EA5u tr\xFAc", 110, 5, "M\u1EAFt qu\u1EA7ng tr\xF2n, m\xEA m\u0103ng tre."],
  ["species.penguin", "species", "Chim c\xE1nh c\u1EE5t", 100, 5, "B\u1EE5ng tr\xF2n, \u0111i l\u1EA1ch b\u1EA1ch."],
  ["fur.cream", "fur", "Kem s\u1EEFa", 0, 1, "M\xE0u l\xF4ng nguy\xEAn b\u1EA3n."],
  ["fur.snow", "fur", "Tr\u1EAFng tuy\u1EBFt", 25, 1, "Tr\u1EAFng m\u1ECBn nh\u01B0 b\xF4ng."],
  ["fur.ginger", "fur", "Cam g\u1EEBng", 30, 1, "\u1EA4m \xE1p nh\u01B0 n\u1EAFng chi\u1EC1u."],
  ["fur.smoke", "fur", "X\xE1m kh\xF3i", 30, 1, "D\u1ECBu d\xE0ng, h\u01A1i b\xED \u1EA9n."],
  ["fur.cocoa", "fur", "N\xE2u cacao", 35, 1, "Nh\u01B0 m\u1ED9t c\u1ED1c cacao n\xF3ng."],
  ["fur.peach", "fur", "H\u1ED3ng \u0111\xE0o", 40, 2, "Ng\u1ECDt ng\xE0o v\xE0 vui t\u01B0\u01A1i."],
  ["fur.midnight", "fur", "\u0110en n\u1EEDa \u0111\xEAm", 45, 3, "L\xF4ng \u0111en, m\u1EAFt v\xE0ng nh\u01B0 tr\u0103ng."],
  ["fur.lilac", "fur", "T\xEDm lilac", 55, 5, "Hi\u1EBFm c\xF3, nh\u01B0 hoa t\u1EED \u0111inh h\u01B0\u01A1ng."],
  ["fur.honey", "fur", "V\xE0ng m\u1EADt ong", 35, 1, "V\xE0ng \u01B0\u01A1m nh\u01B0 n\u1EAFng s\u1EDBm."],
  ["fur.mint", "fur", "Xanh b\u1EA1c h\xE0", 45, 3, "M\xE1t l\u1EA1nh, h\u1EE3p v\u1EDBi \u1EBFch v\xE0 v\u1ECBt."],
  ["fur.sky", "fur", "Xanh da tr\u1EDDi", 50, 4, "Nh\u01B0 m\u1ED9t bu\u1ED5i tr\u01B0a kh\xF4ng m\xE2y."],
  ["hat.sprout", "hat", "M\u1EA7m l\xE1", 0, 1, "Chi\u1EBFc l\xE1 nh\u1ECF m\u1ECDc tr\xEAn \u0111\u1EA7u."],
  ["hat.bow", "hat", "N\u01A1 h\u1ED3ng", 20, 1, "Nh\u1ECF xinh, c\xE0i m\u1ED9t b\xEAn tai."],
  ["hat.party", "hat", "M\u0169 ti\u1EC7c", 25, 1, "M\u1ED7i ng\xE0y \u0111\u1EC1u \u0111\xE1ng \u0103n m\u1EEBng."],
  ["hat.beanie", "hat", "M\u0169 len", 30, 1, "C\xF3 qu\u1EA3 b\xF4ng tr\xEAn ch\xF3p."],
  ["hat.flower", "hat", "V\xF2ng hoa", 35, 1, "Hoa c\xFAc tr\u1EAFng v\xE0 v\xE0ng."],
  ["hat.straw", "hat", "M\u0169 c\xF3i", 40, 2, "Cho nh\u1EEFng bu\u1ED5i d\xE3 ngo\u1EA1i."],
  ["hat.wizard", "hat", "M\u0169 ph\xF9 th\u1EE7y", 90, 6, "\u0110\u1EA7y sao, h\u01A1i to so v\u1EDBi \u0111\u1EA7u."],
  ["hat.crown", "hat", "V\u01B0\u01A1ng mi\u1EC7n", 120, 8, "D\xE0nh cho ng\u01B0\u1EDDi ch\u0103m ch\u1EC9 l\xE2u ng\xE0y."],
  ["hat.catears", "hat", "B\u1EDDm tai m\xE8o", 30, 1, "Th\xEAm m\u1ED9t \u0111\xF4i tai n\u1EEFa."],
  ["hat.cap", "hat", "M\u0169 l\u01B0\u1EE1i trai", 30, 1, "\u0110\u1ED9i ng\u01B0\u1EE3c cho ng\u1EA7u."],
  ["hat.beret", "hat", "M\u0169 n\u1ED3i", 35, 1, "Ngh\u1EC7 s\u0129 Paris."],
  ["hat.santa", "hat", "M\u0169 Noel", 40, 1, "Ho ho ho!"],
  ["hat.antlers", "hat", "G\u1EA1c tu\u1EA7n l\u1ED9c", 40, 1, "K\xE9o xe tr\u01B0\u1EE3t tuy\u1EBFt gi\xFAp \xF4ng gi\xE0 Noel."],
  ["hat.chef", "hat", "M\u0169 \u0111\u1EA7u b\u1EBFp", 45, 2, "H\xF4m nay n\u1EA5u m\xF3n g\xEC nh\u1EC9?"],
  ["hat.pumpkin", "hat", "M\u0169 b\xED ng\xF4", 45, 2, "Cho m\xF9a l\u1EC5 h\u1ED9i h\xF3a trang."],
  ["hat.frog", "hat", "M\u0169 \u1EBFch", 50, 3, "Hai con m\u1EAFt l\u1ED3i tr\xEAn \u0111\u1EC9nh."],
  ["hat.headphones", "hat", "Tai nghe", 55, 3, "Nghe lo-fi khi t\u1EADp trung."],
  ["hat.cowboy", "hat", "M\u0169 cao b\u1ED3i", 60, 4, "Yee-haw!"],
  ["hat.cloud", "hat", "\u0110\xE1m m\xE2y nh\u1ECF", 65, 4, "M\u1ED9t \u0111\xE1m m\xE2y \u0111i theo tr\xEAn \u0111\u1EA7u."],
  ["hat.halo", "hat", "V\xF2ng thi\xEAn th\u1EA7n", 70, 5, "Ngoan c\u1EA3 tu\u1EA7n r\u1ED3i \u0111\xF3."],
  ["hat.tiara", "hat", "V\u01B0\u01A1ng mi\u1EC7n pha l\xEA", 80, 5, "L\u1EA5p l\xE1nh nh\u01B0 c\xF4ng ch\xFAa."],
  ["glasses.round", "glasses", "K\xEDnh tr\xF2n", 30, 1, "Tr\xF4ng th\u1EADt th\xF4ng th\xE1i."],
  ["glasses.sun", "glasses", "K\xEDnh r\xE2m", 40, 1, "Ng\u1EA7u m\u1ED9t ch\xFAt c\u0169ng \u0111\u01B0\u1EE3c."],
  ["glasses.heart", "glasses", "K\xEDnh tr\xE1i tim", 45, 3, "Nh\xECn \u0111\xE2u c\u0169ng th\u1EA5y d\u1EC5 th\u01B0\u01A1ng."],
  ["glasses.monocle", "glasses", "K\xEDnh m\u1ED9t m\u1EAFt", 60, 5, "Qu\xFD \xF4ng, qu\xFD c\xF4 l\u1ECBch l\xE3m."],
  ["glasses.nerd", "glasses", "K\xEDnh g\u1ECDng vu\xF4ng", 30, 1, "M\u1ECDt s\xE1ch ch\xEDnh hi\u1EC7u."],
  ["glasses.goggles", "glasses", "K\xEDnh b\u01A1i", 35, 1, "S\u1EB5n s\xE0ng l\u1EB7n xu\u1ED1ng h\u1ED3."],
  ["glasses.star", "glasses", "K\xEDnh ng\xF4i sao", 40, 2, "Ng\xF4i sao c\u1EE7a bu\u1ED5i ti\u1EC7c."],
  ["glasses.aviator", "glasses", "K\xEDnh phi c\xF4ng", 55, 4, "Bay l\xEAn n\xE0o!"],
  ["glasses.pixel", "glasses", "K\xEDnh pixel", 65, 5, "Deal with it."],
  ["neck.bowtie", "neck", "N\u01A1 c\u1ED5", 20, 1, "Ch\u1EC9n chu cho ng\xE0y l\xE0m vi\u1EC7c."],
  ["neck.scarf", "neck", "Kh\u0103n len", 25, 1, "\u1EA4m c\u1ED5 nh\u1EEFng ng\xE0y se l\u1EA1nh."],
  ["neck.bandana", "neck", "Kh\u0103n bandana", 25, 1, "H\u1ECDa ti\u1EBFt ch\u1EA5m bi."],
  ["neck.bell", "neck", "V\xF2ng chu\xF4ng", 30, 1, "Leng keng m\u1ED7i b\u01B0\u1EDBc \u0111i."],
  ["neck.lei", "neck", "V\xF2ng hoa c\u1ED5", 35, 3, "Nh\u01B0 v\u1EEBa \u0111i ngh\u1EC9 bi\u1EC3n v\u1EC1."],
  ["neck.collar", "neck", "V\xF2ng c\u1ED5 th\u1EBB t\xEAn", 20, 1, "Th\u1EBB t\xEAn h\xECnh tr\xE1i tim."],
  ["neck.tie", "neck", "C\xE0 v\u1EA1t", 30, 1, "H\u1ECDp h\xE0nh nghi\xEAm t\xFAc."],
  ["neck.ruff", "neck", "C\u1ED5 \xE1o b\xE8o", 40, 2, "B\xE8o nh\xFAn tr\u1EAFng tinh."],
  ["neck.pearls", "neck", "Chu\u1ED7i ng\u1ECDc trai", 60, 4, "Qu\xFD ph\xE1i nh\u1EB9 nh\xE0ng."],
  ["neck.medal", "neck", "Huy ch\u01B0\u01A1ng v\xE0ng", 80, 6, "Qu\xE1n qu\xE2n ch\u0103m ch\u1EC9."],
  ["outfit.sweater", "outfit", "\xC1o len", 50, 1, "\xC1o len s\u1ECDc, m\u1EC1m v\xE0 \u1EA5m."],
  ["outfit.overalls", "outfit", "Y\u1EBFm jean", 55, 2, "C\xF3 t\xFAi nh\u1ECF \u0111\u1EF1ng b\xFAt ch\xEC."],
  ["outfit.raincoat", "outfit", "\xC1o m\u01B0a v\xE0ng", 60, 3, "S\u1EB5n s\xE0ng cho ng\xE0y m\u01B0a."],
  ["outfit.cape", "outfit", "\xC1o cho\xE0ng", 90, 6, "\xC1o cho\xE0ng si\xEAu anh h\xF9ng."],
  ["outfit.apron", "outfit", "T\u1EA1p d\u1EC1", 40, 1, "C\xF3 t\xFAi nh\u1ECF h\xECnh tr\xE1i tim."],
  ["outfit.pajamas", "outfit", "\u0110\u1ED3 ng\u1EE7 sao", 50, 1, "Xanh \u0111\xEAm in sao v\xE0ng."],
  ["outfit.hoodie", "outfit", "\xC1o hoodie", 55, 1, "R\u1ED9ng r\xE3i, c\xF3 d\xE2y r\xFAt."],
  ["outfit.dress", "outfit", "V\xE1y hoa", 60, 2, "Hoa nh\xED tr\xEAn n\u1EC1n v\xE0ng."],
  ["outfit.tutu", "outfit", "V\xE1y tutu", 65, 3, "Xoay m\u1ED9t v\xF2ng n\xE0o."],
  ["outfit.sailor", "outfit", "\xC1o th\u1EE7y th\u1EE7", 70, 4, "C\u1ED5 xanh, n\u01A1 \u0111\u1ECF."],
  ["outfit.yukata", "outfit", "\xC1o yukata", 85, 5, "\u0110i xem ph\xE1o hoa m\xF9a h\xE8."],
  ["outfit.tux", "outfit", "\xC1o vest", 90, 6, "B\u1EA3nh bao d\u1EF1 ti\u1EC7c."],
  ["outfit.astronaut", "outfit", "\u0110\u1ED3 phi h\xE0nh gia", 130, 8, "M\u1EE5c ti\xEAu: m\u1EB7t tr\u0103ng."],
  ["back.lollipop", "back", "K\u1EB9o m\xFAt", 20, 1, "K\u1EB9o c\u1EA7u v\u1ED3ng xo\u1EAFn \u1ED1c."],
  ["back.balloon", "back", "B\xF3ng bay", 25, 1, "B\xF3ng bay h\xECnh tr\xE1i tim."],
  ["back.backpack", "back", "Ba l\xF4 nh\u1ECF", 40, 1, "\u0110\u1EF1ng b\xFAt, s\u1ED5 v\xE0 \u0111\u1ED3 \u0103n v\u1EB7t."],
  ["back.umbrella", "back", "\xD4 che n\u1EAFng", 45, 2, "\xD4 gi\u1EA5y ki\u1EC3u c\u1ED5 \u0111i\u1EC3n."],
  ["back.bat", "back", "C\xE1nh d\u01A1i", 60, 3, "H\u01A1i tinh ngh\u1ECBch m\u1ED9t ch\xFAt."],
  ["back.guitar", "back", "\u0110\xE0n ghi-ta", 75, 4, "H\xE1t m\u1ED9t b\xE0i cho b\u1EA1n nghe."],
  ["back.fairy", "back", "C\xE1nh ti\xEAn", 80, 4, "Trong su\u1ED1t, l\u1EA5p l\xE1nh."],
  ["back.wings", "back", "C\xE1nh thi\xEAn th\u1EA7n", 90, 5, "L\xF4ng v\u0169 tr\u1EAFng mu\u1ED1t."]
];
var CAPSULE_ONLY = /* @__PURE__ */ new Set([
  "bedroomWall.moon",
  "nightstand.moon",
  "glasses.star",
  "outfit.pajamas",
  "hat.cloud",
  "back.bat",
  "bedroomTheme.galaxy",
  "hat.wizard",
  "bathMat.wave",
  "bathToy.whale",
  "glasses.goggles",
  "neck.lei",
  "bathToy.boat",
  "outfit.sailor",
  "sink.shell",
  "bathTheme.ocean",
  "hat.flower",
  "flowerBed.sunflower",
  "gardenSeat.swing",
  "outfit.dress",
  "plant.tulip",
  "back.fairy",
  "tree.sakura",
  "hat.tiara",
  "hat.party",
  "back.balloon",
  "back.lollipop",
  "gardenDeco.lantern",
  "hat.pumpkin",
  "outfit.yukata",
  "hat.antlers",
  "neck.medal"
]);
var SERIES_REWARD_ITEMS = /* @__PURE__ */ new Set(["studyTheme.night", "pond.koi", "studyTheme.sakura", "gardenDeco.tent"]);
var BLURB_OVERRIDE = {
  "treat.cake": "M\u1EEBng m\u1ED9t ng\xE0y th\u1EADt vui.",
  "hat.crown": "D\xE0nh cho ng\u01B0\u1EDDi \u0111\xE3 \u1EDF Cozii l\xE2u ng\xE0y.",
  "neck.medal": "Qu\xE1n qu\xE2n c\u1EE7a ng\xE0y h\u1ED9i.",
  "neck.bowtie": "Ch\u1EC9n chu cho m\u1ED9t bu\u1ED5i h\u1EB9n.",
  "neck.tie": "Nghi\xEAm t\xFAc\u2026 \u0111\u01B0\u1EE3c n\u0103m ph\xFAt.",
  "hat.headphones": "Nghe lo-fi khi th\u01B0 gi\xE3n.",
  "desk.lavender": "M\xE0u t\xEDm nh\u1EA1t d\u1ECBu m\u1EAFt.",
  "lamp.desk": "\u0110\u1EE7 s\xE1ng cho bu\u1ED5i \u0111\u1ECDc truy\u1EC7n mu\u1ED9n.",
  "desk.computer": "M\xE0n h\xECnh nh\u1ECF d\xE1n \u0111\u1EA7y sticker.",
  "wall.clock": "T\xEDch t\u1EAFc, ch\u1EB3ng ai v\u1ED9i c\u1EA3.",
  "plant.bonsai": "Ki\xEAn nh\u1EABn t\u1EEBng ch\xFAt m\u1ED9t.",
  "seat.armchair": "H\u1EE3p \u0111\u1EC3 \u0111\u1ECDc s\xE1ch bu\u1ED5i t\u1ED1i.",
  "gardenDeco.mailbox": "Ch\u1EDD th\u01B0 t\u1EEB b\u1EA1n b\xE8."
};
function rankFor(level) {
  if (level <= 2) return 1;
  if (level <= 4) return 2;
  if (level === 5) return 3;
  if (level === 6) return 4;
  return 5;
}
function round5(n) {
  return Math.max(5, Math.round(n / 5) * 5);
}
var ITEMS = ROWS.map(([id, slot, name, base, level, blurb]) => {
  const source = SERIES_REWARD_ITEMS.has(id) ? "reward" : CAPSULE_ONLY.has(id) ? "capsule" : base === 0 ? "starter" : "shop";
  const mult = slot === "species" ? ECONOMY.speciesPriceMultiplier : ECONOMY.priceMultiplier;
  return {
    id,
    slot,
    name,
    price: source === "shop" ? round5(base * mult) : 0,
    rank: rankFor(level),
    blurb: BLURB_OVERRIDE[id] ?? blurb,
    source
  };
});
var BY_ID = new Map(ITEMS.map((i) => [i.id, i]));
function item(id) {
  return BY_ID.get(id);
}
var PET_SLOTS = ["species", "fur", "hat", "glasses", "neck", "outfit", "back"];
function isPetSlot(s) {
  return PET_SLOTS.includes(s);
}
var ROOMS = [
  { id: "study", name: "Ph\xF2ng ch\xEDnh", themeSlot: "studyTheme", slots: ["wall", "lamp", "desk", "plant", "seat"], rank: 1, defaultTheme: "studyTheme.cream", petHome: 0.2 },
  { id: "bedroom", name: "Ph\xF2ng ng\u1EE7", themeSlot: "bedroomTheme", slots: ["bed", "nightstand", "bedroomWall", "closet", "bedroomRug", "plush"], rank: 2, defaultTheme: "bedroomTheme.lilac", petHome: 0.22 },
  { id: "kitchen", name: "B\u1EBFp nh\u1ECF", themeSlot: "kitchenTheme", slots: ["stove", "fridge", "dining", "kitchenWall", "treat"], rank: 3, defaultTheme: "kitchenTheme.mint", petHome: 0.42 },
  { id: "bath", name: "Ph\xF2ng t\u1EAFm", themeSlot: "bathTheme", slots: ["tub", "sink", "bathShelf", "bathMat", "bathToy"], rank: 4, defaultTheme: "bathTheme.aqua", petHome: 0.26 },
  { id: "garden", name: "S\xE2n tr\u01B0\u1EDBc", themeSlot: "gardenTheme", slots: ["tree", "flowerBed", "gardenSeat", "pond", "gardenDeco"], rank: 5, defaultTheme: "gardenTheme.day", petHome: 0.34 }
];
function room(id) {
  return ROOMS.find((r) => r.id === id);
}
var MAX_NUDGE = 6;
function defaultOwned() {
  return ITEMS.filter((i) => i.source === "starter").map((i) => i.id);
}

// src/content/farm.ts
var CROPS = [
  { id: "radish", name: "C\u1EE7 c\u1EA3i h\u1ED3ng", seedId: "seed.radish", produceId: "crop.radish", growSec: 90, seedPrice: 2, yield: 1, sellPrice: 3, rank: 1, color: 15899572, leaf: 8372090, blurb: "L\u1EDBn nhanh nh\u01B0 th\u1ED5i. H\u1EE3p \u0111\u1EC3 ch\u01A1i m\u1ED9t bu\u1ED5i." },
  { id: "carrot", name: "C\xE0 r\u1ED1t", seedId: "seed.carrot", produceId: "crop.carrot", growSec: 300, seedPrice: 4, yield: 2, sellPrice: 4, rank: 1, color: 15902298, leaf: 7319146, blurb: "N\u0103m ph\xFAt l\xE0 c\xF3 hai c\u1EE7 gi\xF2n." },
  { id: "strawberry", name: "D\xE2u t\xE2y", seedId: "seed.strawberry", produceId: "crop.strawberry", growSec: 900, seedPrice: 6, yield: 3, sellPrice: 4, rank: 1, color: 15226475, leaf: 6266204, blurb: "M\u01B0\u1EDDi l\u0103m ph\xFAt, ba qu\u1EA3 \u0111\u1ECF m\u1ECDng." },
  { id: "pumpkin", name: "B\xED ng\xF4", seedId: "seed.pumpkin", produceId: "crop.pumpkin", growSec: 2400, seedPrice: 10, yield: 2, sellPrice: 9, rank: 2, color: 15769664, leaf: 7314002, blurb: "B\u1ED1n m\u01B0\u01A1i ph\xFAt. N\u1EA5u s\xFAp r\u1EA5t ngon." },
  { id: "corn", name: "Ng\xF4 ng\u1ECDt", seedId: "seed.corn", produceId: "crop.corn", growSec: 7200, seedPrice: 16, yield: 4, sellPrice: 7, rank: 2, color: 16175966, leaf: 8038496, blurb: "Hai gi\u1EDD. Gieo r\u1ED3i \u0111i ch\u01A1i \u0111\xE2u \u0111\xF3." },
  { id: "sunflower", name: "H\u01B0\u1EDBng d\u01B0\u01A1ng", seedId: "seed.sunflower", produceId: "crop.sunflower", growSec: 14400, seedPrice: 21, yield: 3, sellPrice: 12, rank: 3, color: 16238659, leaf: 7182928, blurb: "B\u1ED1n gi\u1EDD. S\xE1ng mai quay l\u1EA1i l\xE0 n\u1EDF r\u1ED9." }
];
var TUTORIAL_CROP = {
  id: "sprout",
  name: "M\u1EA7m h\u01B0\u1EDBng d\u1EABn",
  seedId: "seed.sprout",
  produceId: "crop.radish",
  growSec: 20,
  seedPrice: 0,
  yield: 2,
  sellPrice: 4,
  rank: 1,
  color: 15899572,
  leaf: 8372090,
  blurb: "H\u1EA1t gi\u1ED1ng \u0111\u1EB7c bi\u1EC7t c\u1EE7a \xD4ng Tr\xE0: l\u1EDBn trong 20 gi\xE2y, ch\u1EC9 c\xF3 m\u1ED9t h\u1EA1t."
};
function crop(id) {
  return id === TUTORIAL_CROP.id ? TUTORIAL_CROP : CROPS.find((c) => c.id === id);
}
function cropBySeed(sid) {
  return sid === TUTORIAL_CROP.seedId ? TUTORIAL_CROP : CROPS.find((c) => c.seedId === sid);
}
var FOODS = [
  { id: "food.apple", name: "T\xE1o gi\xF2n", price: 6, fullness: 18, happiness: 0, blurb: "\u0110\u1ECF au, c\u1EAFn nghe r\u1ED9p r\u1ED9p." },
  { id: "food.oatcookie", name: "B\xE1nh y\u1EBFn m\u1EA1ch", price: 12, fullness: 25, happiness: 6, blurb: "Th\u01A1m b\u01A1, gi\xF2n tan." },
  { id: "food.riceball", name: "C\u01A1m n\u1EAFm", price: 16, fullness: 35, happiness: 4, blurb: "Tr\xF2n tr\xF2n, c\xF3 l\xE1 rong bi\u1EC3n." },
  { id: "food.veggiesoup", name: "S\xFAp rau", price: 24, fullness: 45, happiness: 8, blurb: "\u1EA4m b\u1EE5ng ng\xE0y m\u01B0a." },
  { id: "food.picnic", name: "H\u1ED9p picnic", price: 50, fullness: 70, happiness: 20, blurb: "B\xE1nh m\xEC, d\xE2u t\xE2y v\xE0 m\u1ED9t t\u1EA5m kh\u0103n k\u1EBB \xF4." },
  { id: "food.carrot", name: "C\xE0 r\u1ED1t n\u01B0\u1EDBng", price: 0, fullness: 20, happiness: 4, blurb: "N\u1EA5u t\u1EEB c\xE0 r\u1ED1t nh\xE0 tr\u1ED3ng." }
];
function food(id) {
  return FOODS.find((f) => f.id === id);
}
var RECIPES = [
  { id: "recipe.carrot", output: "food.carrot", count: 1, needs: { "crop.carrot": 1 }, rank: 1 },
  { id: "recipe.soup", output: "food.veggiesoup", count: 1, needs: { "crop.carrot": 1, "crop.radish": 2 }, rank: 1 },
  { id: "recipe.picnic", output: "food.picnic", count: 1, needs: { "crop.strawberry": 2, "crop.corn": 1, "crop.radish": 1 }, rank: 2 }
];
function recipe(id) {
  return RECIPES.find((r) => r.id === id);
}

// src/content/capsule.ts
var SERIES = [
  {
    id: "moon",
    name: "\u0110\xEAm Tr\u0103ng Ng\u1EE7 Ngon",
    blurb: "G\u1ED1i m\xE2y, sao s\xE1ng v\xE0 m\u1ED9t chi\u1EBFc m\u0169 ph\xF9 th\u1EE7y h\u01A1i to.",
    color: 7299768,
    items: [
      { id: "bedroomWall.moon", rarity: "common" },
      { id: "nightstand.moon", rarity: "common" },
      { id: "glasses.star", rarity: "common" },
      { id: "outfit.pajamas", rarity: "common" },
      { id: "hat.cloud", rarity: "common" },
      { id: "back.bat", rarity: "rare" },
      { id: "bedroomTheme.galaxy", rarity: "rare" },
      { id: "hat.wizard", rarity: "special" }
    ],
    reward: { item: "studyTheme.night", title: "Ng\u01B0\u1EDDi g\xE1c tr\u0103ng", pose: "stargaze" }
  },
  {
    id: "ocean",
    name: "Bi\u1EC3n Xanh M\xE1t",
    blurb: "S\xF3ng nh\u1ECF, v\u1ECF s\xF2 v\xE0 m\u1ED9t ch\xFA c\xE1 voi phun n\u01B0\u1EDBc.",
    color: 5218255,
    items: [
      { id: "bathMat.wave", rarity: "common" },
      { id: "bathToy.whale", rarity: "common" },
      { id: "glasses.goggles", rarity: "common" },
      { id: "neck.lei", rarity: "common" },
      { id: "bathToy.boat", rarity: "common" },
      { id: "outfit.sailor", rarity: "rare" },
      { id: "sink.shell", rarity: "rare" },
      { id: "bathTheme.ocean", rarity: "special" }
    ],
    reward: { item: "pond.koi", title: "B\u1EA1n c\u1EE7a bi\u1EC3n", pose: "splash" }
  },
  {
    id: "spring",
    name: "V\u01B0\u1EDDn Xu\xE2n",
    blurb: "Hoa nh\xED, c\xE1nh ti\xEAn v\xE0 c\xE2y anh \u0111\xE0o n\u1EDF r\u1ED9.",
    color: 15241640,
    items: [
      { id: "hat.flower", rarity: "common" },
      { id: "flowerBed.sunflower", rarity: "common" },
      { id: "gardenSeat.swing", rarity: "common" },
      { id: "outfit.dress", rarity: "common" },
      { id: "plant.tulip", rarity: "common" },
      { id: "back.fairy", rarity: "rare" },
      { id: "tree.sakura", rarity: "rare" },
      { id: "hat.tiara", rarity: "special" }
    ],
    reward: { item: "studyTheme.sakura", title: "S\u1EE9 gi\u1EA3 m\xF9a xu\xE2n", pose: "petals" }
  },
  {
    id: "festival",
    name: "Ng\xE0y H\u1ED9i Nh\u1ECF",
    blurb: "B\xF3ng bay, \u0111\xE8n l\u1ED3ng gi\u1EA5y v\xE0 \xE1o yukata xem ph\xE1o hoa.",
    color: 14714703,
    items: [
      { id: "hat.party", rarity: "common" },
      { id: "back.balloon", rarity: "common" },
      { id: "back.lollipop", rarity: "common" },
      { id: "gardenDeco.lantern", rarity: "common" },
      { id: "hat.pumpkin", rarity: "common" },
      { id: "outfit.yukata", rarity: "rare" },
      { id: "hat.antlers", rarity: "rare" },
      { id: "neck.medal", rarity: "special" }
    ],
    reward: { item: "gardenDeco.tent", title: "Linh h\u1ED3n l\u1EC5 h\u1ED9i", pose: "confetti" }
  }
];
function series(id) {
  return SERIES.find((s) => s.id === id);
}

// src/content/town.ts
var NPCS = [
  {
    id: "tra",
    name: "\xD4ng Tr\xE0",
    role: "Tr\u01B0\u1EDFng th\u1ECB tr\u1EA5n",
    personality: "Ch\u1EADm r\xE3i, hay pha tr\xE0, nh\u1EDB t\xEAn t\u1EEBng ng\u01B0\u1EDDi.",
    look: { species: "capybara", fur: "cocoa", hat: "hat.straw", neck: "neck.bowtie", stage: "grown" },
    lines: [
      "Tr\xE0 v\u1EEBa pha. Ng\u1ED3i xu\u1ED1ng m\u1ED9t ch\xFAt r\u1ED3i h\u1EB5ng \u0111i ti\u1EBFp.",
      "\u0110\xE8n trong th\u1ECB tr\u1EA5n s\xE1ng th\xEAm m\u1ED9t ng\u1ECDn. Ch\u1EAFc l\xE0 nh\u1EDD ch\xE1u.",
      "Kh\xF4ng ai \u1EDF Cozii ph\u1EA3i v\u1ED9i c\u1EA3."
    ],
    progressLines: {
      2: "Ph\xF2ng ng\u1EE7 \u0111\xE3 s\u1EEDa xong. T\u1ED1i nay ng\u1EE7 ngon nh\xE9.",
      3: "B\u1EBFp nh\u1ECF m\u1EDF c\u1EEDa r\u1ED3i. M\xF9i b\xE1nh lan ra t\u1EADn qu\u1EA3ng tr\u01B0\u1EDDng.",
      4: "Ph\xF2ng t\u1EAFm c\xF3 n\u01B0\u1EDBc n\xF3ng r\u1ED3i. \xD4ng \u0111\xE3 th\u1EED, r\u1EA5t d\u1EC5 ch\u1ECBu.",
      5: "S\xE2n tr\u01B0\u1EDBc nh\xE0 ch\xE1u gi\u1EDD \u0111\u1EE7 ch\u1ED7 cho m\u1ED9t b\u1EEFa ti\u1EC7c nh\u1ECF.",
      6: "Ng\xE0y h\u1ED9i n\u0103m nay vui nh\u1EA5t t\u1EEB tr\u01B0\u1EDBc t\u1EDBi gi\u1EDD."
    }
  },
  {
    id: "la",
    name: "C\xF4 L\xE1",
    role: "Qu\u1EA7y h\u1EA1t gi\u1ED1ng",
    personality: "Nhanh nh\u1EA3u, m\xEA c\xE2y, n\xF3i chuy\u1EC7n b\u1EB1ng d\u1EA5u ch\u1EA5m than.",
    look: { species: "frog", fur: "mint", hat: "hat.sprout", outfit: "outfit.overalls", stage: "grown" },
    lines: [
      "H\u1EA1t m\u1EDBi v\u1EC1! C\xE1i n\xE0o c\u0169ng n\u1EA3y m\u1EA7m h\u1EBFt!",
      "C\xE2y kh\xF4ng gi\u1EADn n\u1EBFu ch\xE1u qu\xEAn t\u01B0\u1EDBi \u0111\xE2u. C\xE2y ch\u1EC9 l\u1EDBn ch\u1EADm h\u01A1n ch\xFAt th\xF4i.",
      "C\u1EE7 c\u1EA3i h\u1ED3ng l\u1EDBn nhanh l\u1EAFm, th\u1EED \u0111i!"
    ]
  },
  {
    id: "moc",
    name: "B\xE0 M\u1ED9c",
    role: "Ti\u1EC7m N\u1ED9i Th\u1EA5t",
    personality: "Hi\u1EC1n, kh\xE9o tay, th\xEDch k\u1EC3 chuy\u1EC7n v\u1EC1 t\u1EEBng m\xF3n \u0111\u1ED3.",
    look: { species: "bear", fur: "cocoa", glasses: "glasses.round", outfit: "outfit.apron", stage: "grown" },
    lines: [
      "M\xF3n n\xE0o \u1EDF \u0111\xE2y c\u0169ng c\xF3 m\u1ED9t c\xE2u chuy\u1EC7n.",
      "\u0110\u1EB7t \u0111\u1ED3 theo \xFD m\xECnh l\xE0 \u0111\u01B0\u1EE3c. Nh\xE0 l\xE0 c\u1EE7a ch\xE1u m\xE0.",
      "B\xE0 v\u1EEBa \u0111\xE1nh b\xF3ng l\u1EA1i c\xE1i gh\u1EBF b\xE0nh. Ng\u1ED3i th\u1EED kh\xF4ng?"
    ]
  },
  {
    id: "may",
    name: "Anh M\xE2y",
    role: "Ti\u1EC7m May M\xE2y",
    personality: "\u0110i\u1EC7u \u0111\xE0, khen th\u1EADt l\xF2ng, h\u01A1i hay qu\xEAn.",
    look: { species: "bunny", fur: "lilac", hat: "hat.beret", neck: "neck.scarf", stage: "grown" },
    lines: [
      "M\xE0u n\xE0y h\u1EE3p v\u1EDBi b\u1EA1n nh\u1ECF c\u1EE7a b\u1EA1n gh\xEA.",
      "M\u1EB7c th\u1EED tho\u1EA3i m\xE1i, kh\xF4ng mua c\u0169ng kh\xF4ng sao.",
      "H\xF4m qua anh may nh\u1EA7m m\u1ED9t chi\u1EBFc m\u0169 cho m\xE8o th\xE0nh m\u0169 cho th\u1ECF. V\u1EABn \u0111\u1EB9p."
    ]
  },
  {
    id: "bo",
    name: "B\xE9 B\u01A1",
    role: "B\u01B0u t\xE1 & b\u1EA3ng \u0111\u01A1n h\xE0ng",
    personality: "L\u1EA1ch b\u1EA1ch, ch\u0103m ch\u1EC9, hay \u0111\u1EBFm.",
    look: { species: "duck", fur: "honey", hat: "hat.cap", back: "back.backpack", stage: "little" },
    lines: [
      "C\xF3 \u0111\u01A1n m\u1EDBi! Kh\xF4ng g\u1EA5p \u0111\xE2u, l\xFAc n\xE0o r\u1EA3nh th\xEC l\xE0m.",
      "M\u1ED9t, hai, ba... \u0111\u1EE7 c\xE0 r\u1ED1t r\u1ED3i!",
      "Th\u01B0 c\u1EE7a b\u1EA1n \u0111\xE2y. B\u01A1 ch\u01B0a \u0111\u1ECDc tr\u1ED9m \u0111\xE2u."
    ]
  },
  {
    id: "pip",
    name: "Pip",
    role: "S\xE2n ch\u01A1i",
    personality: "Tinh ngh\u1ECBch, th\xEDch thi \u0111\u1EA5u nh\u01B0ng thua c\u0169ng c\u01B0\u1EDDi.",
    look: { species: "fox", fur: "ginger", glasses: "glasses.sun", neck: "neck.bandana", stage: "growing" },
    lines: [
      "Ch\u01A1i m\u1ED9t v\xE1n kh\xF4ng? Thua c\u0169ng ch\u1EB3ng m\u1EA5t g\xEC.",
      "K\u1EF7 l\u1EE5c c\u1EE7a Pip l\xE0... \xE0 th\xF4i, b\xED m\u1EADt.",
      "Th\u1EED th\xE1ch tu\u1EA7n m\u1EDBi \u0111\xE3 c\xF3. Ai c\u0169ng ch\u01A1i c\xF9ng m\u1ED9t b\u1EA3n \u0111\u1ED3."
    ]
  }
];
var NPC_HOMES = [
  {
    npc: "tra",
    room: "study",
    theme: "studyTheme.mint",
    slots: { wall: "wall.clock", lamp: "lamp.paper", desk: "desk.sage", plant: "plant.bonsai", seat: "seat.armchair" },
    garden: [{ crop: "pumpkin", stage: 2 }, { crop: "corn", stage: 1 }, { crop: "carrot", stage: 3 }],
    note: "Nh\xE0 m\u1EABu c\u1EE7a \xD4ng Tr\xE0: g\u1ECDn g\xE0ng, nhi\u1EC1u c\xE2y, l\xFAc n\xE0o c\u0169ng c\xF3 tr\xE0."
  },
  {
    npc: "la",
    room: "garden",
    theme: "gardenTheme.day",
    slots: { tree: "tree.apple", flowerBed: "flowerBed.tulip", gardenSeat: "gardenSeat.bench", pond: "pond.lily", gardenDeco: "gardenDeco.birdhouse" },
    garden: [{ crop: "strawberry", stage: 2 }, { crop: "radish", stage: 1 }, { crop: "sunflower", stage: 2 }, { crop: "carrot", stage: 1 }],
    note: "Nh\xE0 m\u1EABu c\u1EE7a C\xF4 L\xE1: khu v\u01B0\u1EDDn l\xE0 ph\xF2ng kh\xE1ch."
  },
  {
    npc: "moc",
    room: "bedroom",
    theme: "bedroomTheme.candy",
    slots: { bed: "bed.wood", nightstand: "nightstand.lamp", bedroomWall: "bedroomWall.garland", closet: "closet.wardrobe", bedroomRug: "bedroomRug.heart", plush: "plush.teddy" },
    garden: [{ crop: "pumpkin", stage: 1 }, { crop: "strawberry", stage: 3 }],
    note: "Nh\xE0 m\u1EABu c\u1EE7a B\xE0 M\u1ED9c: m\xF3n n\xE0o c\u0169ng do b\xE0 t\u1EF1 \u0111\xF3ng."
  }
];
var CHAPTERS = [
  {
    id: 1,
    name: "D\u1ECDn v\xE0o nh\xE0",
    intro: "M\u1ED9t c\u0103n nh\xE0 nh\u1ECF, m\u1ED9t ng\u01B0\u1EDDi b\u1EA1n nh\u1ECF, v\xE0 v\xE0i vi\u1EC7c \u0111\u1EA7u ti\xEAn.",
    tasks: [
      { id: "c1.name", text: "\u0110\u1EB7t t\xEAn cho b\u1EA1n nh\u1ECF", key: "named", target: 1 },
      { id: "c1.place", text: "\u0110\u1EB7t m\xF3n qu\xE0 \u0111\u1EA7u ti\xEAn v\xE0o ph\xF2ng", key: "place_item", target: 1, hint: "Nh\xE0 m\xECnh \u2192 Trang tr\xED" },
      { id: "c1.feed", text: "Cho b\u1EA1n nh\u1ECF \u0103n", key: "feed", target: 1, hint: "Nh\xE0 m\xECnh \u2192 Cho \u0103n" },
      { id: "c1.plant", text: "Gieo m\u1ED9t h\u1EA1t gi\u1ED1ng", key: "plant", target: 1, hint: "V\u01B0\u1EDDn rau \u2192 ch\u1EA1m \xF4 \u0111\u1EA5t" },
      { id: "c1.game", text: "Ch\u01A1i h\u1EBFt m\u1ED9t l\u01B0\u1EE3t minigame", key: "game_finished", target: 1, hint: "Th\u1ECB tr\u1EA5n \u2192 S\xE2n ch\u01A1i" },
      { id: "c1.harvest", text: "Thu ho\u1EA1ch l\u1EA7n \u0111\u1EA7u", key: "harvest", target: 1 },
      { id: "c1.visit", text: "Gh\xE9 th\u0103m nh\xE0 m\u1ED9t NPC", key: "visit_npc", target: 1, hint: "B\u1EA1n b\xE8 \u2192 Nh\xE0 m\u1EABu NPC" }
    ],
    reward: { coins: 100, tickets: 2 },
    outro: "\u0110\xE2y l\xE0 h\u1ED9 chi\u1EBFu th\u1ECB tr\u1EA5n c\u1EE7a ch\xE1u. M\u1ED7i con d\u1EA5u l\xE0 m\u1ED9t k\u1EF7 ni\u1EC7m. Ph\xF2ng ng\u1EE7 \u0111\xE3 s\u1EEDa xong r\u1ED3i \u0111\u1EA5y."
  },
  {
    id: 2,
    name: "M\xF9a gieo h\u1EA1t \u0111\u1EA7u ti\xEAn",
    intro: "V\u01B0\u1EDDn rau b\u1EAFt \u0111\u1EA7u xanh. B\xE9 B\u01A1 c\xF3 v\xE0i \u0111\u01A1n h\xE0ng nho nh\u1ECF.",
    tasks: [
      { id: "c2.harvest", text: "Thu ho\u1EA1ch 15 l\u1EA7n", key: "harvest", target: 15 },
      { id: "c2.kinds", text: "Thu ho\u1EA1ch 3 lo\u1EA1i c\xE2y kh\xE1c nhau", key: "derived:harvest_kinds", target: 3 },
      { id: "c2.orders", text: "Ho\xE0n th\xE0nh 2 \u0111\u01A1n h\xE0ng", key: "order", target: 2, hint: "Th\u1ECB tr\u1EA5n \u2192 B\u1EA3ng \u0111\u01A1n h\xE0ng" },
      { id: "c2.plot", text: "M\u1EDF th\xEAm m\u1ED9t \xF4 \u0111\u1EA5t", key: "plot_bought", target: 1 },
      { id: "c2.cook", text: "N\u1EA5u m\u1ED9t m\xF3n \u1EDF Ti\u1EC7m B\xE1nh", key: "cook", target: 1 },
      { id: "c2.water", text: "T\u01B0\u1EDBi c\xE2y 3 l\u1EA7n", key: "water", target: 3 }
    ],
    reward: { coins: 150, tickets: 2 },
    outro: "V\u01B0\u1EDDn c\u1EE7a ch\xE1u l\xE0m c\u1EA3 con \u0111\u01B0\u1EDDng th\u01A1m m\xF9i d\xE2u. B\u1EBFp nh\u1ECF m\u1EDF c\u1EEDa r\u1ED3i."
  },
  {
    id: 3,
    name: "Ng\u01B0\u1EDDi b\u1EA1n h\xE0ng x\xF3m",
    intro: "\u1EDE Cozii, gh\xE9 nh\xE0 nhau l\xE0 chuy\u1EC7n th\u01B0\u1EDDng ng\xE0y.",
    tasks: [
      { id: "c3.visits", text: "Gh\xE9 th\u0103m 3 ng\xF4i nh\xE0 kh\xE1c nhau", key: "derived:homes_visited", target: 3, hint: "Nh\xE0 NPC c\u0169ng \u0111\u01B0\u1EE3c t\xEDnh" },
      { id: "c3.compliment", text: "G\u1EEDi 3 l\u1EDDi khen", key: "compliment", target: 3 },
      { id: "c3.help", text: "T\u01B0\u1EDBi gi\xFAp c\xE2y nh\xE0 h\xE0ng x\xF3m 2 l\u1EA7n", key: "help_water", target: 2 },
      { id: "c3.preview", text: "Xem tr\u01B0\u1EDBc ng\xF4i nh\xE0 m\xECnh s\u1EBD chia s\u1EBB", key: "share_preview", target: 1, hint: "B\u1EA1n b\xE8 \u2192 Quy\u1EC1n ri\xEAng t\u01B0" },
      { id: "c3.clean", text: "D\u1ECDn nh\xE0 2 l\u1EA7n", key: "clean", target: 2 }
    ],
    reward: { coins: 200, tickets: 2 },
    outro: "H\xE0ng x\xF3m ai c\u0169ng nh\u1EAFc t\u1EDBi nh\xE0 ch\xE1u. Ph\xF2ng t\u1EAFm c\xF3 n\u01B0\u1EDBc n\xF3ng r\u1ED3i."
  },
  {
    id: 4,
    name: "G\xF3c nh\xE0 c\xF3 gu",
    intro: "Nh\xE0 l\xE0 n\u01A1i th\u1EC3 hi\u1EC7n m\xECnh. Trang tr\xED theo \xFD th\xEDch nh\xE9.",
    tasks: [
      { id: "c4.furniture", text: "S\u1EDF h\u1EEFu 8 m\xF3n n\u1ED9i th\u1EA5t mua th\xEAm", key: "derived:furniture_bought", target: 8 },
      { id: "c4.theme", text: "\u0110\u1ED5i t\u01B0\u1EDDng & s\xE0n m\u1ED9t ph\xF2ng", key: "theme_changed", target: 1 },
      { id: "c4.layout", text: "L\u01B0u m\u1ED9t b\u1ED1 c\u1EE5c ph\xF2ng y\xEAu th\xEDch", key: "layout_saved", target: 1 },
      { id: "c4.outfit", text: "Cho b\u1EA1n nh\u1ECF m\u1EB7c 3 m\xF3n c\xF9ng l\xFAc", key: "derived:wearing", target: 3 },
      { id: "c4.photo", text: "Ch\u1EE5p m\u1ED9t t\u1EA5m \u1EA3nh", key: "photo", target: 1, hint: "Nh\xE0 m\xECnh \u2192 Ch\u1EE5p \u1EA3nh" },
      { id: "c4.affection", text: "\u0110\u1EA1t th\xE2n thi\u1EBFt b\u1EADc 3", key: "derived:affection_level", target: 3 }
    ],
    reward: { coins: 250, tickets: 3 },
    outro: "B\xE0 M\u1ED9c n\xF3i nh\xE0 ch\xE1u l\xE0 ng\xF4i nh\xE0 c\xF3 gu nh\u1EA5t ph\u1ED1. S\xE2n tr\u01B0\u1EDBc \u0111\xE3 d\u1ECDn xong."
  },
  {
    id: 5,
    name: "Ng\xE0y h\u1ED9i th\u1ECB tr\u1EA5n",
    intro: "\u0110\xE8n l\u1ED3ng \u0111\u01B0\u1EE3c treo kh\u1EAFp qu\u1EA3ng tr\u01B0\u1EDDng. C\u1EA3 th\u1ECB tr\u1EA5n chu\u1EA9n b\u1ECB cho ng\xE0y h\u1ED9i.",
    tasks: [
      { id: "c5.games", text: "Ch\u01A1i 4 minigame kh\xE1c nhau", key: "derived:games_distinct", target: 4 },
      { id: "c5.jump", text: "\u0110\u1EA1t 40 \u0111i\u1EC3m \u1EDF Nh\u1EA3y M\xE2y", key: "best:cloudJump", target: 40 },
      { id: "c5.orders", text: "Ho\xE0n th\xE0nh t\u1ED5ng c\u1ED9ng 10 \u0111\u01A1n h\xE0ng", key: "order", target: 10 },
      { id: "c5.capsule", text: "M\u1EDF 3 capsule", key: "capsule_pull", target: 3 },
      { id: "c5.harvest", text: "Thu ho\u1EA1ch 60 l\u1EA7n", key: "harvest", target: 60 }
    ],
    reward: { coins: 300, tickets: 3, title: "C\u01B0 d\xE2n Cozii" },
    outro: "C\u1EA3m \u01A1n ch\xE1u \u0111\xE3 \u1EDF l\u1EA1i v\u1EDBi th\u1ECB tr\u1EA5n. T\u1EEB gi\u1EDD, Cozii c\u0169ng l\xE0 nh\xE0 c\u1EE7a ch\xE1u."
  }
];
var DAILY_POOL = [
  { id: "d.harvest", text: "Thu ho\u1EA1ch 5 l\u1EA7n", key: "harvest", target: 5 },
  { id: "d.game", text: "Ch\u01A1i h\u1EBFt m\u1ED9t l\u01B0\u1EE3t minigame", key: "game_finished", target: 1 },
  { id: "d.feed", text: "Cho b\u1EA1n nh\u1ECF \u0103n", key: "feed", target: 1 },
  { id: "d.cuddle", text: "N\u1EF1ng b\u1EA1n nh\u1ECF", key: "cuddle", target: 1 },
  { id: "d.order", text: "Giao m\u1ED9t \u0111\u01A1n h\xE0ng", key: "order", target: 1 },
  { id: "d.visit", text: "Gh\xE9 th\u0103m m\u1ED9t ng\xF4i nh\xE0", key: "visit", target: 1 },
  { id: "d.water", text: "T\u01B0\u1EDBi c\xE2y 2 l\u1EA7n", key: "water", target: 2 },
  { id: "d.clean", text: "D\u1ECDn nh\xE0", key: "clean", target: 1 },
  { id: "d.plant", text: "Gieo 4 h\u1EA1t gi\u1ED1ng", key: "plant", target: 4 }
];
function fnv1a(s) {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 16777619) >>> 0;
  }
  return h >>> 0;
}
function dailyTasksFor(uid, day) {
  const pool2 = [...DAILY_POOL];
  const picked = [];
  let h = fnv1a(uid + ":" + day);
  for (let i = 0; i < 3; i++) {
    const idx = h % pool2.length;
    picked.push(pool2.splice(idx, 1)[0]);
    h = fnv1a(String(h) + ":" + i);
  }
  return picked;
}
var STICKERS = [
  { id: "warm", text: "\u1EA4m \xE1p qu\xE1", emoji: "\u2615" },
  { id: "cute", text: "Pet d\u1EC5 th\u01B0\u01A1ng", emoji: "\u{1F497}" },
  { id: "stay", text: "Mu\u1ED1n \u1EDF \u0111\xE2y lu\xF4n", emoji: "\u{1F3E1}" },
  { id: "garden", text: "V\u01B0\u1EDDn \u0111\u1EB9p gh\xEA", emoji: "\u{1F33B}" },
  { id: "style", text: "Ph\u1ED1i \u0111\u1ED3 c\xF3 gu", emoji: "\u{1F380}" },
  { id: "cozy", text: "Nh\xECn l\xE0 th\u1EA5y th\u01B0 gi\xE3n", emoji: "\u{1F319}" }
];

// src/content/pet.ts
var SPECIES = [
  "cat",
  "bunny",
  "hamster",
  "bear",
  "fox",
  "puppy",
  "duck",
  "frog",
  "capybara",
  "panda",
  "penguin"
];
var FURS = ["cream", "snow", "ginger", "smoke", "cocoa", "peach", "midnight", "lilac", "honey", "mint", "sky"];
var NATURAL_FUR = {
  cat: "cream",
  hamster: "cream",
  bunny: "snow",
  panda: "snow",
  bear: "cocoa",
  capybara: "cocoa",
  fox: "ginger",
  puppy: "honey",
  duck: "honey",
  frog: "mint",
  penguin: "midnight"
};

// src/core/time.ts
var OFFSET_MS = 7 * 3600 * 1e3;
function dayKey(ms) {
  return new Date(ms + OFFSET_MS).toISOString().slice(0, 10);
}
function weekKey(ms) {
  const d = new Date(ms + OFFSET_MS);
  const date = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  const dow = date.getUTCDay() || 7;
  date.setUTCDate(date.getUTCDate() + 4 - dow);
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
  const week = Math.ceil(((date.getTime() - yearStart.getTime()) / 864e5 + 1) / 7);
  return `${date.getUTCFullYear()}-W${String(week).padStart(2, "0")}`;
}

// src/core/state.ts
var GAME_IDS = ["cloudJump", "giftBasket", "memory", "rhythm", "runner", "picnic"];
function rankOf(s) {
  return Math.min(ECONOMY.maxRank, 1 + s.passport.claimed.length);
}
function affectionLevel(affection) {
  let lvl = 1;
  ECONOMY.affectionLevels.forEach((t, i) => {
    if (affection >= t) lvl = i + 1;
  });
  return lvl;
}
function petStage(affection) {
  const l = affectionLevel(affection);
  return l >= 6 ? "grown" : l >= 3 ? "growing" : "little";
}
function readyAt(p) {
  return p.plantedAt + Math.round(p.growSec * 1e3 * (1 - Math.min(ECONOMY.farm.maxCutPct, p.cutPct) / 100));
}

// src/core/games.ts
var GAME_RULES = {
  cloudJump: { maxMetersPerSec: 8, minMeters: 15, pointsPerCoin: 10, pointsPerStar: 3 },
  giftBasket: { duration: 60, maxPointsPerSec: 40, minScore: 20, pointsPerCoin: 15 },
  memory: { easy: { pairs: 6, base: 3, fast: 40 }, medium: { pairs: 8, base: 5, fast: 65 }, minSecPerPair: 1.2 },
  rhythm: { minAccuracy: 40, accuracyPerCoin: 10 },
  runner: { maxMetersPerSec: 14, minMeters: 50, metersPerCoin: 25 },
  picnic: { minSeconds: 8, coins: 4, noHintBonus: 2 }
};
function memoryScore(level, moves, seconds) {
  const pairs = GAME_RULES.memory[level].pairs;
  return Math.max(pairs * 10, pairs * 100 - Math.max(0, moves - pairs) * 15 - Math.round(seconds));
}
function picnicScore(moves, hints, seconds) {
  return Math.max(20, 300 - Math.round(seconds) - hints * 40 - Math.max(0, moves - 6) * 4);
}
function scoreOf(r) {
  switch (r.game) {
    case "cloudJump":
      return Math.floor(r.meters) + r.stars * GAME_RULES.cloudJump.pointsPerStar;
    case "giftBasket":
      return r.score;
    case "memory":
      return memoryScore(r.level, r.moves, r.seconds);
    case "rhythm":
      return Math.round(r.accuracy * 10);
    case "runner":
      return Math.floor(r.meters) + r.berries * 2;
    case "picnic":
      return picnicScore(r.moves, r.hints, r.seconds);
  }
}
var isInt = (v, lo, hi) => typeof v === "number" && Number.isFinite(v) && v >= lo && v <= hi;
function checkRun(t, r, now) {
  const elapsed = Math.max(0, (now - t.startedAt) / 1e3);
  const no = (note) => ({ finished: note !== "implausible", valid: note !== "implausible", score: note === "implausible" ? 0 : safeScore(r), coins: 0, note });
  if (!r || r.game !== t.game) return { finished: false, valid: false, score: 0, coins: 0, note: "implausible" };
  if (!r.completed) return { finished: false, valid: true, score: 0, coins: 0, note: "notCompleted" };
  switch (r.game) {
    case "cloudJump": {
      const g = GAME_RULES.cloudJump;
      if (!isInt(r.meters, 0, 1e5) || !isInt(r.stars, 0, 1e4)) return no("implausible");
      if (r.meters > g.maxMetersPerSec * elapsed + 5 || r.stars > r.meters / 2 + 5) return no("implausible");
      const score = scoreOf(r);
      if (r.meters < g.minMeters) return { finished: true, valid: true, score, coins: 0, note: "belowThreshold" };
      return { finished: true, valid: true, score, coins: Math.max(1, Math.floor(score / g.pointsPerCoin)), note: "rewarded" };
    }
    case "giftBasket": {
      const g = GAME_RULES.giftBasket;
      if (!isInt(r.score, 0, 1e5)) return no("implausible");
      if (elapsed < g.duration - 2 || r.score > g.maxPointsPerSec * Math.min(elapsed, g.duration + 1) + 5) return no("implausible");
      if (r.score < g.minScore) return { finished: true, valid: true, score: r.score, coins: 0, note: "belowThreshold" };
      return { finished: true, valid: true, score: r.score, coins: Math.max(1, Math.floor(r.score / g.pointsPerCoin)), note: "rewarded" };
    }
    case "memory": {
      const g = GAME_RULES.memory;
      const lv = g[r.level];
      if (!lv) return no("implausible");
      if (r.pairs !== lv.pairs || !isInt(r.moves, lv.pairs, 1e3) || !isInt(r.seconds, 0, 36e3)) return no("implausible");
      if (elapsed < lv.pairs * g.minSecPerPair || r.seconds > elapsed + 5) return no("implausible");
      let coins = lv.base;
      if (r.moves <= lv.pairs * 2) coins += 1;
      if (r.moves <= lv.pairs + 3) coins += 1;
      if (r.seconds <= lv.fast) coins += 1;
      return { finished: true, valid: true, score: scoreOf(r), coins, note: "rewarded" };
    }
    case "rhythm": {
      const g = GAME_RULES.rhythm;
      if (!isInt(r.accuracy, 0, 100) || !isInt(r.hits, 0, r.total) || !isInt(r.total, 1, 2e3) || !isInt(r.duration, 5, 600)) return no("implausible");
      if (elapsed < r.duration - 2) return no("implausible");
      if (r.accuracy < g.minAccuracy) return { finished: true, valid: true, score: scoreOf(r), coins: 0, note: "belowThreshold" };
      return { finished: true, valid: true, score: scoreOf(r), coins: Math.max(1, Math.floor(r.accuracy / g.accuracyPerCoin)), note: "rewarded" };
    }
    case "runner": {
      const g = GAME_RULES.runner;
      if (!isInt(r.meters, 0, 1e5) || !isInt(r.berries, 0, 1e4)) return no("implausible");
      if (r.meters > g.maxMetersPerSec * elapsed + 5 || r.berries > r.meters / 3 + 5) return no("implausible");
      const score = scoreOf(r);
      if (r.meters < g.minMeters) return { finished: true, valid: true, score, coins: 0, note: "belowThreshold" };
      return { finished: true, valid: true, score, coins: Math.max(1, Math.floor(score / g.metersPerCoin)), note: "rewarded" };
    }
    case "picnic": {
      const g = GAME_RULES.picnic;
      if (!isInt(r.moves, 1, 1e3) || !isInt(r.hints, 0, 50) || !isInt(r.seconds, 0, 36e3)) return no("implausible");
      if (elapsed < g.minSeconds || r.seconds > elapsed + 5) return no("implausible");
      return { finished: true, valid: true, score: scoreOf(r), coins: g.coins + (r.hints === 0 ? g.noHintBonus : 0), note: "rewarded" };
    }
  }
}
function safeScore(r) {
  try {
    const v = scoreOf(r);
    return Number.isFinite(v) ? Math.max(0, Math.floor(v)) : 0;
  } catch {
    return 0;
  }
}

// src/core/engine.ts
var GameError = class extends Error {
  code;
  constructor(code, message) {
    super(message);
    this.code = code;
  }
};
var fail = (code, msg) => {
  throw new GameError(code, msg);
};
function newState(id, now, env2, mode = "local") {
  const day = dayKey(now);
  const s = {
    mode,
    version: 1,
    serverNow: now,
    profile: { id, name: "", friendCode: "", title: null, frame: null, createdAt: now, isAnonymous: true, onboarded: false },
    pet: {
      name: "",
      species: "cat",
      fur: "cream",
      wear: {},
      needs: { ...ECONOMY.care.initial, asOf: now },
      affection: 0
    },
    wallet: { coins: ECONOMY.start.coins, tickets: ECONOMY.start.tickets, shards: 0 },
    owned: defaultOwned(),
    stock: { "seed.radish": 4, "seed.carrot": 2, "food.apple": 3, "seed.sprout": 1 },
    home: { rooms: {} },
    farm: { plots: [], unlocked: ECONOMY.farm.startPlots, freeSeedDay: null, tutorialSeedUsed: false },
    orders: { list: [], rerollDay: day, rerollsUsed: 0, doneDay: day, doneToday: 0 },
    counters: {},
    daily: { day, claimed: [], bonusClaimed: false },
    caps: {},
    passport: { claimed: [] },
    capsule: { pity: {}, last: [], ticketDay: day, ticketsBought: 0 },
    titles: [],
    poses: [],
    badges: [],
    presets: { outfits: Array(ECONOMY.presets.outfits).fill(null), layouts: {} },
    records: {},
    social: { visibility: "private", shareGarden: true, showSources: true, publishedAt: null },
    onboarding: { storySeen: false, tutorial: {}, tutorialHidden: false },
    runs: []
  };
  for (const r of ROOMS) s.home.rooms[r.id] = { theme: r.defaultTheme, slots: {} };
  s.home.rooms.study.slots.seat = { item: "seat.rug", flip: false, dx: 0 };
  for (let i = 0; i < ECONOMY.farm.maxPlots; i++) s.farm.plots.push(emptyPlot(i));
  while (s.orders.list.length < ECONOMY.orders.active) s.orders.list.push(makeOrder(s, env2));
  return s;
}
function emptyPlot(idx) {
  return { idx, crop: null, plantedAt: 0, growSec: 0, cutPct: 0, selfWatered: false, helps: 0 };
}
function owns(s, id) {
  return s.owned.includes(id);
}
function grant(s, id) {
  if (!owns(s, id)) s.owned.push(id);
}
function addStock(s, id, n) {
  const v = (s.stock[id] ?? 0) + n;
  if (v < 0) fail("stock", "Kh\xF4ng \u0111\u1EE7 trong kho.");
  if (v > ECONOMY.farm.maxStack) fail("stock_full", "Kho \u0111\xE3 \u0111\u1EA7y lo\u1EA1i n\xE0y.");
  if (v === 0) delete s.stock[id];
  else s.stock[id] = v;
}
function spend(s, coins) {
  if (s.wallet.coins < coins) fail("coins", `C\u1EA7n ${coins} xu, b\u1EA1n \u0111ang c\xF3 ${s.wallet.coins} xu.`);
  s.wallet.coins -= coins;
}
function bump(s, key, n, env2) {
  s.counters[key] = (s.counters[key] ?? 0) + n;
  const dk = `d:${dayKey(env2.now)}:${key}`;
  s.counters[dk] = (s.counters[dk] ?? 0) + n;
}
function capKey(env2, kind) {
  return `${dayKey(env2.now)}|${kind}`;
}
function unitCost(c) {
  return Math.ceil(c.seedPrice / c.yield);
}
function sellQuote(s, now, c, n) {
  let left = marketProfitLeft(s, now);
  const cost = unitCost(c);
  const margin = Math.max(0, c.sellPrice - cost);
  let coins = 0, profit = 0, atCost = 0;
  for (let i = 0; i < n; i++) {
    if (left > 0 || margin === 0) {
      coins += c.sellPrice;
      profit += margin;
      left -= margin;
    } else {
      coins += Math.min(cost, c.sellPrice);
      atCost += 1;
    }
  }
  return { coins, profit, atCost };
}
function marketProfitLeft(s, now) {
  return Math.max(0, ECONOMY.farm.marketProfitPerDay - (s.caps[`${dayKey(now)}|market:profit`] ?? 0));
}
function capUsed(s, env2, kind) {
  return s.caps[capKey(env2, kind)] ?? 0;
}
function capAdd(s, env2, kind, n) {
  const k = capKey(env2, kind);
  s.caps[k] = (s.caps[k] ?? 0) + n;
}
function prune(s, env2) {
  const keep = new Set([0, 1, 2].map((d) => dayKey(env2.now - d * 864e5)));
  for (const k of Object.keys(s.caps)) if (!keep.has(k.split("|")[0])) delete s.caps[k];
  for (const k of Object.keys(s.counters)) if (k.startsWith("d:") && !keep.has(k.slice(2, 12))) delete s.counters[k];
  s.runs = s.runs.filter((r) => r.expiresAt > env2.now);
}
function needsAt(n, now) {
  const c = ECONOMY.care;
  const hours = Math.min(Math.max(0, (now - n.asOf) / 36e5), c.maxDecayHours);
  const decay = (v, perHour) => v > c.floor ? Math.max(c.floor, v - perHour * hours) : v;
  return {
    fullness: decay(n.fullness, c.perHour.fullness),
    cleanliness: decay(n.cleanliness, c.perHour.cleanliness),
    happiness: decay(n.happiness, c.perHour.happiness),
    asOf: Math.max(n.asOf, now)
  };
}
function clamp100(v) {
  return Math.max(0, Math.min(100, v));
}
function addAffection(s, env2, n) {
  const left = ECONOMY.care.dailyAffectionCap - capUsed(s, env2, "affection");
  const got = Math.max(0, Math.min(left, n));
  if (got > 0) {
    s.pet.affection += got;
    capAdd(s, env2, "affection", got);
  }
  return got;
}
function careReward(s, env2, kind, before) {
  const c = ECONOMY.care;
  const affection = before < c.affectionBelow ? addAffection(s, env2, c.affectionPerCare) : 0;
  if (before >= c.needsCareBelow) return { coins: 0, affection, note: "notNeeded" };
  if (capUsed(s, env2, "care:" + kind) >= c.rewardedPerKindPerDay) return { coins: 0, affection, note: "kindLimit" };
  const left = c.dailyCoinCap - capUsed(s, env2, "care:coins");
  if (left <= 0) return { coins: 0, affection, note: "dailyLimit" };
  const coins = Math.min(left, c.coins[kind]);
  s.wallet.coins += coins;
  capAdd(s, env2, "care:" + kind, 1);
  capAdd(s, env2, "care:coins", coins);
  return { coins, affection, note: "rewarded" };
}
var ORDER_NPCS = ["bo", "la", "moc", "tra", "may", "pip"];
function makeOrder(s, env2) {
  const rank = rankOf(s);
  const pool2 = CROPS.filter((c) => c.rank <= rank);
  const kinds = 1 + Math.floor(env2.rand() * Math.min(3, pool2.length));
  const picked = [...pool2];
  const needs = {};
  for (let i = 0; i < kinds && picked.length; i++) {
    const c = picked.splice(Math.floor(env2.rand() * picked.length), 1)[0];
    const max = c.growSec <= 300 ? 4 : c.growSec <= 2400 ? 3 : 2;
    needs[c.produceId] = 1 + Math.floor(env2.rand() * max);
  }
  return {
    id: env2.uuid(),
    npc: ORDER_NPCS[Math.floor(env2.rand() * ORDER_NPCS.length)],
    needs,
    coins: orderCoins(needs),
    createdAt: env2.now
  };
}
function orderCoins(needs) {
  let sum = 0;
  for (const [pid, n] of Object.entries(needs)) sum += (CROPS.find((c) => c.produceId === pid)?.sellPrice ?? 0) * n;
  return Math.max(5, Math.round(sum * ECONOMY.orders.rewardMultiplier / 5) * 5);
}
function derived(s, key) {
  if (key.startsWith("derived:")) {
    const k = key.slice(8);
    switch (k) {
      case "harvest_kinds":
        return Object.keys(s.counters).filter((x) => x.startsWith("harvest_kind:")).length;
      case "homes_visited":
        return Object.keys(s.counters).filter((x) => x.startsWith("home_visited:")).length;
      case "furniture_bought":
        return s.owned.filter((id) => {
          const it = item(id);
          return it && !isPetSlot(it.slot) && it.source !== "starter";
        }).length;
      case "wearing":
        return Object.values(s.pet.wear).filter(Boolean).length;
      case "affection_level":
        return affectionLevel(s.pet.affection);
      case "games_distinct":
        return GAME_IDS.filter((g) => (s.counters["game:" + g] ?? 0) > 0).length;
    }
    return 0;
  }
  if (key.startsWith("best:")) return s.records[key.slice(5)]?.best ?? 0;
  return s.counters[key] ?? 0;
}
function taskDone(s, t) {
  return derived(s, t.key) >= t.target;
}
var RULES_VERSION = 1;
function apply(s, a, env2) {
  prune(s, env2);
  s.serverNow = env2.now;
  if (!s.profile.onboarded && a.type !== "onboard" && a.type !== "storySeen" && a.type !== "tutorial" && a.type !== "tutorialHidden") {
    fail("not_onboarded", "H\xE3y ch\u1ECDn b\u1EA1n nh\u1ECF tr\u01B0\u1EDBc \u0111\xE3.");
  }
  const r = run(s, a, env2);
  s.version += 1;
  return r;
}
function cleanName(raw, max, what) {
  const v = raw.replace(/[\u0000-\u001f\u007f<>]/g, "").replace(/\s+/g, " ").trim();
  if (v.length < 1) fail("name", `H\xE3y \u0111\u1EB7t ${what}.`);
  if ([...v].length > max) fail("name", `${what[0].toUpperCase() + what.slice(1)} t\u1ED1i \u0111a ${max} k\xFD t\u1EF1.`);
  return v;
}
function run(s, a, env2) {
  const now = env2.now;
  const rank = rankOf(s);
  switch (a.type) {
    case "onboard": {
      if (s.profile.onboarded) fail("done", "B\u1EA1n \u0111\xE3 c\xF3 b\u1EA1n nh\u1ECF r\u1ED3i.");
      if (!SPECIES.includes(a.species)) fail("species", "Lo\xE0i kh\xF4ng h\u1EE3p l\u1EC7.");
      if (!FURS.includes(a.fur)) fail("fur", "M\xE0u l\xF4ng kh\xF4ng h\u1EE3p l\u1EC7.");
      s.profile.name = cleanName(a.playerName, 20, "t\xEAn c\u1EE7a b\u1EA1n");
      s.pet.name = cleanName(a.petName, 16, "t\xEAn cho b\u1EA1n nh\u1ECF");
      s.pet.species = a.species;
      s.pet.fur = a.fur;
      grant(s, "species." + a.species);
      grant(s, "fur." + a.fur);
      grant(s, "fur." + NATURAL_FUR[a.species]);
      grant(s, "lamp.candle");
      s.pet.needs = { ...ECONOMY.care.initial, asOf: now };
      s.profile.onboarded = true;
      bump(s, "named", 1, env2);
      return { gift: "lamp.candle" };
    }
    case "setNames": {
      if (a.playerName != null) s.profile.name = cleanName(a.playerName, 20, "t\xEAn c\u1EE7a b\u1EA1n");
      if (a.petName != null) s.pet.name = cleanName(a.petName, 16, "t\xEAn cho b\u1EA1n nh\u1ECF");
      return;
    }
    case "storySeen":
      s.onboarding.storySeen = true;
      return;
    case "tutorial":
      if (a.status === "reset") delete s.onboarding.tutorial[a.step];
      else s.onboarding.tutorial[a.step] = a.status;
      return;
    case "tutorialHidden":
      s.onboarding.tutorialHidden = a.hidden;
      return;
    // ---- Nhà ----
    case "place": {
      const r = room(a.room);
      if (!r) fail("room", "Ph\xF2ng kh\xF4ng t\u1ED3n t\u1EA1i.");
      if (rank < r.rank) fail("locked", `${r.name} m\u1EDF \u1EDF h\u1EA1ng th\u1ECB tr\u1EA5n ${r.rank}.`);
      if (!r.slots.includes(a.slot)) fail("slot", "V\u1ECB tr\xED n\xE0y kh\xF4ng thu\u1ED9c ph\xF2ng.");
      const rs = s.home.rooms[a.room];
      if (a.item == null) {
        delete rs.slots[a.slot];
        return;
      }
      const it = item(a.item);
      if (!it || it.slot !== a.slot) fail("item", "M\xF3n n\xE0y kh\xF4ng \u0111\u1EB7t \u0111\u01B0\u1EE3c \u1EDF \u0111\xE2y.");
      if (!owns(s, a.item)) fail("not_owned", "B\u1EA1n ch\u01B0a c\xF3 m\xF3n n\xE0y.");
      const dx = Math.max(-MAX_NUDGE, Math.min(MAX_NUDGE, Math.round((a.dx ?? 0) * 2) / 2));
      const prev = rs.slots[a.slot];
      rs.slots[a.slot] = { item: a.item, flip: !!a.flip, dx };
      if (!prev || prev.item !== a.item) bump(s, "place_item", 1, env2);
      return;
    }
    case "theme": {
      const r = room(a.room);
      if (rank < r.rank) fail("locked", `${r.name} m\u1EDF \u1EDF h\u1EA1ng th\u1ECB tr\u1EA5n ${r.rank}.`);
      const it = item(a.item);
      if (!it || it.slot !== r.themeSlot) fail("item", "\u0110\xE2y kh\xF4ng ph\u1EA3i t\u01B0\u1EDDng & s\xE0n c\u1EE7a ph\xF2ng n\xE0y.");
      if (!owns(s, a.item)) fail("not_owned", "B\u1EA1n ch\u01B0a c\xF3 m\u1EABu t\u01B0\u1EDDng n\xE0y.");
      const rs = s.home.rooms[a.room];
      if (rs.theme !== a.item) bump(s, "theme_changed", 1, env2);
      rs.theme = a.item;
      return;
    }
    case "saveLayout": {
      const r = room(a.room);
      if (rank < r.rank) fail("locked", "Ph\xF2ng ch\u01B0a m\u1EDF.");
      if (a.index < 0 || a.index >= ECONOMY.presets.layoutsPerRoom) fail("index", "\xD4 l\u01B0u kh\xF4ng h\u1EE3p l\u1EC7.");
      const rs = s.home.rooms[a.room];
      const list = s.presets.layouts[a.room] ?? Array(ECONOMY.presets.layoutsPerRoom).fill(null);
      list[a.index] = { name: cleanName(a.name || `B\u1ED1 c\u1EE5c ${a.index + 1}`, 24, "t\xEAn b\u1ED1 c\u1EE5c"), theme: rs.theme, slots: JSON.parse(JSON.stringify(rs.slots)) };
      s.presets.layouts[a.room] = list;
      bump(s, "layout_saved", 1, env2);
      return;
    }
    case "applyLayout": {
      const p = s.presets.layouts[a.room]?.[a.index];
      if (!p) fail("empty", "\xD4 l\u01B0u n\xE0y c\xF2n tr\u1ED1ng.");
      const missing = [p.theme, ...Object.values(p.slots).map((x) => x.item)].filter((id) => !owns(s, id));
      if (missing.length) fail("not_owned", "B\u1ED1 c\u1EE5c c\xF3 m\xF3n b\u1EA1n kh\xF4ng c\xF2n s\u1EDF h\u1EEFu.");
      s.home.rooms[a.room] = { theme: p.theme, slots: JSON.parse(JSON.stringify(p.slots)) };
      return;
    }
    // ---- Pet ----
    case "equip": {
      if (a.slot === "species" || a.slot === "fur") {
        if (!a.item) fail("item", "Ph\u1EA3i ch\u1ECDn m\u1ED9t l\u1EF1a ch\u1ECDn.");
        const it2 = item(a.item);
        if (!it2 || it2.slot !== a.slot) fail("item", "M\xF3n kh\xF4ng h\u1EE3p l\u1EC7.");
        if (!owns(s, a.item)) fail("not_owned", "B\u1EA1n ch\u01B0a c\xF3 l\u1EF1a ch\u1ECDn n\xE0y.");
        const v = a.item.split(".")[1];
        if (a.slot === "species") s.pet.species = v;
        else s.pet.fur = v;
        return;
      }
      if (a.item == null) {
        delete s.pet.wear[a.slot];
        return;
      }
      const it = item(a.item);
      if (!it || it.slot !== a.slot) fail("item", "M\xF3n kh\xF4ng h\u1EE3p l\u1EC7.");
      if (!owns(s, a.item)) fail("not_owned", "B\u1EA1n ch\u01B0a c\xF3 m\xF3n n\xE0y.");
      s.pet.wear[a.slot] = a.item;
      return;
    }
    case "saveOutfit": {
      if (a.index < 0 || a.index >= ECONOMY.presets.outfits) fail("index", "\xD4 l\u01B0u kh\xF4ng h\u1EE3p l\u1EC7.");
      s.presets.outfits[a.index] = {
        name: cleanName(a.name || `B\u1ED9 ${a.index + 1}`, 24, "t\xEAn b\u1ED9 \u0111\u1ED3"),
        species: s.pet.species,
        fur: s.pet.fur,
        wear: { ...s.pet.wear }
      };
      return;
    }
    case "applyOutfit": {
      const p = s.presets.outfits[a.index];
      if (!p) fail("empty", "\xD4 l\u01B0u n\xE0y c\xF2n tr\u1ED1ng.");
      const ids = ["species." + p.species, "fur." + p.fur, ...Object.values(p.wear).filter(Boolean)];
      if (ids.some((id) => !owns(s, id))) fail("not_owned", "B\u1ED9 \u0111\u1ED3 c\xF3 m\xF3n b\u1EA1n ch\u01B0a c\xF3.");
      s.pet.species = p.species;
      s.pet.fur = p.fur;
      s.pet.wear = { ...p.wear };
      return;
    }
    // ---- Mua bán ----
    case "buyItem": {
      const it = item(a.item);
      if (!it || it.source !== "shop") fail("item", "M\xF3n n\xE0y kh\xF4ng b\xE1n \u1EDF c\u1EEDa h\xE0ng.");
      if (owns(s, a.item)) fail("owned", "B\u1EA1n \u0111\xE3 c\xF3 m\xF3n n\xE0y r\u1ED3i.");
      if (rank < it.rank) fail("rank", `M\u1EDF b\xE1n \u1EDF h\u1EA1ng th\u1ECB tr\u1EA5n ${it.rank}.`);
      spend(s, it.price);
      grant(s, a.item);
      bump(s, "buy", 1, env2);
      return { item: a.item };
    }
    case "buyStock": {
      const n = Math.floor(a.count);
      if (!(n >= 1 && n <= 10)) fail("count", "M\u1ED7i l\u1EA7n mua 1\u201310.");
      let price = 0;
      if (a.id.startsWith("seed.")) {
        const c = cropBySeed(a.id);
        if (!c || c.id === TUTORIAL_CROP.id) fail("item", "Kh\xF4ng c\xF3 h\u1EA1t n\xE0y.");
        if (rank < c.rank) fail("rank", `H\u1EA1t n\xE0y m\u1EDF \u1EDF h\u1EA1ng ${c.rank}.`);
        price = c.seedPrice;
      } else {
        const f = food(a.id);
        if (!f || f.price <= 0) fail("item", "M\xF3n n\xE0y kh\xF4ng b\xE1n s\u1EB5n.");
        price = f.price;
      }
      spend(s, price * n);
      addStock(s, a.id, n);
      return;
    }
    case "sell": {
      const c = CROPS.find((x) => x.produceId === a.id);
      const n = Math.floor(a.count);
      if (!c) fail("item", "Ch\u1EC9 b\xE1n \u0111\u01B0\u1EE3c n\xF4ng s\u1EA3n.");
      if (!(n >= 1 && n <= 99)) fail("count", "S\u1ED1 l\u01B0\u1EE3ng kh\xF4ng h\u1EE3p l\u1EC7.");
      const quote = sellQuote(s, now, c, n);
      addStock(s, a.id, -n);
      s.wallet.coins += quote.coins;
      capAdd(s, env2, "market:profit", quote.profit);
      bump(s, "sell", n, env2);
      return { coins: quote.coins, atCost: quote.atCost };
    }
    case "cook": {
      const r = recipe(a.recipe);
      const n = Math.floor(a.count);
      if (!r) fail("recipe", "Kh\xF4ng c\xF3 c\xF4ng th\u1EE9c n\xE0y.");
      if (rank < r.rank) fail("rank", `C\xF4ng th\u1EE9c m\u1EDF \u1EDF h\u1EA1ng ${r.rank}.`);
      if (!(n >= 1 && n <= 10)) fail("count", "M\u1ED7i l\u1EA7n n\u1EA5u 1\u201310 ph\u1EA7n.");
      for (const [id, k] of Object.entries(r.needs)) if ((s.stock[id] ?? 0) < k * n) fail("stock", "Ch\u01B0a \u0111\u1EE7 nguy\xEAn li\u1EC7u.");
      for (const [id, k] of Object.entries(r.needs)) addStock(s, id, -k * n);
      addStock(s, r.output, r.count * n);
      bump(s, "cook", n, env2);
      return;
    }
    // ---- Chăm sóc ----
    case "feed": {
      const f = food(a.food);
      if (!f) fail("food", "Kh\xF4ng c\xF3 m\xF3n n\xE0y.");
      const n = needsAt(s.pet.needs, now);
      if (n.fullness >= ECONOMY.care.fullEnough) fail("full", `${s.pet.name} no r\u1ED3i, \u0111\u1EC3 l\xE1t n\u1EEFa nh\xE9.`);
      addStock(s, a.food, -1);
      const before = n.fullness;
      n.fullness = clamp100(n.fullness + f.fullness);
      n.happiness = clamp100(n.happiness + f.happiness);
      s.pet.needs = n;
      bump(s, "feed", 1, env2);
      return { reward: careReward(s, env2, "feed", before) };
    }
    case "freeMeal": {
      const n = needsAt(s.pet.needs, now);
      if (n.fullness >= ECONOMY.care.needsCareBelow) fail("not_hungry", "B\u1EEFa c\u01A1 b\u1EA3n ch\u1EC9 c\xF3 khi b\u1EA1n nh\u1ECF \u0111\xF3i.");
      n.fullness = Math.max(n.fullness, ECONOMY.care.freeMealTo);
      s.pet.needs = n;
      bump(s, "feed", 1, env2);
      return { reward: { coins: 0, affection: 0, note: "free" } };
    }
    case "clean": {
      const n = needsAt(s.pet.needs, now);
      if (n.cleanliness >= ECONOMY.care.cleanEnough) fail("clean", "Nh\xE0 \u0111ang s\u1EA1ch bong r\u1ED3i.");
      const before = n.cleanliness;
      n.cleanliness = ECONOMY.care.cleanTo;
      s.pet.needs = n;
      bump(s, "clean", 1, env2);
      return { reward: careReward(s, env2, "clean", before) };
    }
    case "cuddle": {
      const n = needsAt(s.pet.needs, now);
      const before = n.happiness;
      n.happiness = clamp100(n.happiness + ECONOMY.care.cuddleGain);
      s.pet.needs = n;
      bump(s, "cuddle", 1, env2);
      return { reward: careReward(s, env2, "cuddle", before) };
    }
    // ---- Vườn ----
    case "plant": {
      const p = plotAt(s, a.plot);
      if (p.crop) fail("busy", "\xD4 n\xE0y \u0111ang c\xF3 c\xE2y.");
      const c = cropBySeed(a.seed);
      if (!c) fail("seed", "Kh\xF4ng c\xF3 h\u1EA1t n\xE0y.");
      if (c.id === TUTORIAL_CROP.id) {
        if (s.farm.tutorialSeedUsed) fail("seed", "H\u1EA1t h\u01B0\u1EDBng d\u1EABn ch\u1EC9 gieo \u0111\u01B0\u1EE3c m\u1ED9t l\u1EA7n.");
        s.farm.tutorialSeedUsed = true;
      }
      addStock(s, a.seed, -1);
      Object.assign(p, { crop: c.id, plantedAt: now, growSec: c.growSec, cutPct: 0, selfWatered: false, helps: 0 });
      bump(s, "plant", 1, env2);
      return;
    }
    case "water": {
      const p = plotAt(s, a.plot);
      if (!p.crop) fail("empty", "\xD4 n\xE0y ch\u01B0a gieo g\xEC.");
      if (now >= readyAt(p)) fail("ready", "C\xE2y \u0111\xE3 ch\xEDn, thu ho\u1EA1ch th\xF4i.");
      if (p.selfWatered) fail("watered", "V\u1EE5 n\xE0y \u0111\xE3 t\u01B0\u1EDBi r\u1ED3i. C\xE2y v\u1EABn \u0111ang l\u1EDBn \u0111\u1EC1u.");
      p.selfWatered = true;
      p.cutPct = Math.min(ECONOMY.farm.maxCutPct, p.cutPct + ECONOMY.farm.selfWaterCutPct);
      bump(s, "water", 1, env2);
      return;
    }
    case "harvest": {
      const p = plotAt(s, a.plot);
      if (!p.crop) fail("empty", "\xD4 n\xE0y ch\u01B0a gieo g\xEC.");
      if (now < readyAt(p)) fail("not_ready", "C\xE2y ch\u01B0a ch\xEDn. M\xE1y ch\u1EE7 ch\u01B0a x\xE1c nh\u1EADn thu ho\u1EA1ch.");
      const c = crop(p.crop);
      addStock(s, c.produceId, c.yield);
      bump(s, "harvest", 1, env2);
      bump(s, "harvest_kind:" + (c.id === TUTORIAL_CROP.id ? "radish" : c.id), 1, env2);
      Object.assign(p, emptyPlot(p.idx));
      return { produce: c.produceId, count: c.yield };
    }
    case "buyPlot": {
      if (s.farm.unlocked >= ECONOMY.farm.maxPlots) fail("max", "V\u01B0\u1EDDn \u0111\xE3 \u0111\u1EE7 12 \xF4.");
      const next = s.farm.unlocked + 1;
      const def = ECONOMY.farm.plotPrices.find((x) => x.plot === next);
      if (rank < def.rank) fail("rank", `\xD4 \u0111\u1EA5t n\xE0y m\u1EDF \u1EDF h\u1EA1ng ${def.rank}.`);
      spend(s, def.price);
      s.farm.unlocked = next;
      bump(s, "plot_bought", 1, env2);
      return;
    }
    case "freeSeeds": {
      const today = dayKey(now);
      if (s.farm.freeSeedDay === today) fail("used", "H\xF4m nay b\u1EA1n \u0111\xE3 nh\u1EADn g\xF3i h\u1EA1t mi\u1EC5n ph\xED r\u1ED3i.");
      const hasSeeds = Object.keys(s.stock).some((k) => k.startsWith("seed.") && k !== "seed.sprout");
      const planted = s.farm.plots.some((p) => p.crop);
      if (s.wallet.coins >= 10 || hasSeeds || planted) fail("not_needed", "G\xF3i h\u1EA1t mi\u1EC5n ph\xED d\xE0nh cho l\xFAc h\u1EBFt xu v\xE0 v\u01B0\u1EDDn tr\u1ED1ng.");
      s.farm.freeSeedDay = today;
      addStock(s, ECONOMY.farm.freeSeedPack.seed, ECONOMY.farm.freeSeedPack.count);
      return;
    }
    // ---- Đơn hàng ----
    case "completeOrder": {
      const o = s.orders.list.find((x) => x.id === a.order);
      if (!o) fail("order", "\u0110\u01A1n n\xE0y kh\xF4ng c\xF2n n\u1EEFa.");
      const today = dayKey(now);
      if (s.orders.doneDay !== today) {
        s.orders.doneDay = today;
        s.orders.doneToday = 0;
      }
      if (s.orders.doneToday >= ECONOMY.orders.maxCompletedPerDay) fail("cap", "H\xF4m nay B\xE9 B\u01A1 nh\u1EADn \u0111\u1EE7 \u0111\u01A1n r\u1ED3i. Mai quay l\u1EA1i nh\xE9.");
      for (const [id, n] of Object.entries(o.needs)) if ((s.stock[id] ?? 0) < n) fail("stock", "Ch\u01B0a \u0111\u1EE7 n\xF4ng s\u1EA3n cho \u0111\u01A1n n\xE0y.");
      for (const [id, n] of Object.entries(o.needs)) addStock(s, id, -n);
      s.wallet.coins += o.coins;
      s.orders.doneToday += 1;
      bump(s, "order", 1, env2);
      s.orders.list = s.orders.list.filter((x) => x.id !== o.id);
      s.orders.list.push(makeOrder(s, env2));
      return { coins: o.coins };
    }
    case "rerollOrder": {
      const i = s.orders.list.findIndex((x) => x.id === a.order);
      if (i < 0) fail("order", "\u0110\u01A1n n\xE0y kh\xF4ng c\xF2n n\u1EEFa.");
      const today = dayKey(now);
      if (s.orders.rerollDay !== today) {
        s.orders.rerollDay = today;
        s.orders.rerollsUsed = 0;
      }
      if (s.orders.rerollsUsed >= ECONOMY.orders.freeRerollsPerDay) fail("cap", "H\xF4m nay \u0111\xE3 \u0111\u1ED5i \u0111\u1EE7 3 \u0111\u01A1n.");
      s.orders.rerollsUsed += 1;
      s.orders.list[i] = makeOrder(s, env2);
      return;
    }
    // ---- Hộ chiếu & nhiệm vụ ngày ----
    case "claimChapter": {
      const ch = CHAPTERS.find((c) => c.id === a.chapter);
      if (!ch) fail("chapter", "Kh\xF4ng c\xF3 ch\u01B0\u01A1ng n\xE0y.");
      if (s.passport.claimed.includes(ch.id)) fail("claimed", "Ch\u01B0\u01A1ng n\xE0y \u0111\xE3 \u0111\xF3ng d\u1EA5u.");
      if (ch.id > 1 && !s.passport.claimed.includes(ch.id - 1)) fail("order", "H\xE3y ho\xE0n th\xE0nh ch\u01B0\u01A1ng tr\u01B0\u1EDBc.");
      if (!ch.tasks.every((t) => taskDone(s, t))) fail("incomplete", "C\xF2n nhi\u1EC7m v\u1EE5 ch\u01B0a xong.");
      s.passport.claimed.push(ch.id);
      s.wallet.coins += ch.reward.coins;
      s.wallet.tickets += ch.reward.tickets;
      if (ch.reward.title && !s.titles.includes(ch.reward.title)) s.titles.push(ch.reward.title);
      return { coins: ch.reward.coins, tickets: ch.reward.tickets, rank: rankOf(s) };
    }
    case "claimDaily": {
      const today = dayKey(now);
      if (s.daily.day !== today) s.daily = { day: today, claimed: [], bonusClaimed: false };
      const tasks = dailyTasksFor(s.profile.id, today);
      const t = tasks.find((x) => x.id === a.task);
      if (!t) fail("task", "Nhi\u1EC7m v\u1EE5 n\xE0y kh\xF4ng c\xF3 trong h\xF4m nay.");
      if (s.daily.claimed.includes(t.id)) fail("claimed", "\u0110\xE3 nh\u1EADn r\u1ED3i.");
      if ((s.counters[`d:${today}:${t.key}`] ?? 0) < t.target) fail("incomplete", "Ch\u01B0a xong nhi\u1EC7m v\u1EE5.");
      s.daily.claimed.push(t.id);
      s.wallet.coins += ECONOMY.daily.coinsPerTask;
      let tickets = 0;
      if (!s.daily.bonusClaimed && tasks.every((x) => s.daily.claimed.includes(x.id))) {
        s.daily.bonusClaimed = true;
        s.wallet.tickets += ECONOMY.daily.allDoneTickets;
        tickets = ECONOMY.daily.allDoneTickets;
      }
      return { coins: ECONOMY.daily.coinsPerTask, tickets };
    }
    // ---- Sân chơi ----
    case "startRun": {
      if (!GAME_IDS.includes(a.game)) fail("game", "Kh\xF4ng c\xF3 tr\xF2 n\xE0y.");
      const open = s.runs.filter((r) => r.expiresAt > now);
      if (open.length >= 5) s.runs = open.slice(-4);
      const t = {
        id: env2.uuid(),
        game: a.game,
        seed: Math.floor(env2.rand() * 2147483646) + 1,
        rulesVersion: RULES_VERSION,
        startedAt: now,
        expiresAt: now + ECONOMY.games.runTtlSec * 1e3,
        weekly: !!a.weekly,
        ranked: false
      };
      s.runs.push(t);
      return { run: t };
    }
    case "finishRun": {
      const t = s.runs.find((r) => r.id === a.run);
      if (!t) fail("run", "L\u01B0\u1EE3t ch\u01A1i \u0111\xE3 h\u1EBFt h\u1EA1n ho\u1EB7c \u0111\xE3 n\u1ED9p.");
      s.runs = s.runs.filter((r) => r.id !== a.run);
      const verdict = checkRun(t, a.result, now);
      return finishReward(s, env2, t, verdict);
    }
    // ---- Capsule ----
    case "buyTicket": {
      const today = dayKey(now);
      if (s.capsule.ticketDay !== today) {
        s.capsule.ticketDay = today;
        s.capsule.ticketsBought = 0;
      }
      if (s.capsule.ticketsBought >= ECONOMY.capsule.maxTicketBuysPerDay) fail("cap", "H\xF4m nay \u0111\xE3 \u0111\u1ED5i \u0111\u1EE7 v\xE9.");
      spend(s, ECONOMY.capsule.ticketPriceCoins);
      s.capsule.ticketsBought += 1;
      s.wallet.tickets += 1;
      return;
    }
    case "openCapsule": {
      const se = series(a.series);
      if (!se) fail("series", "Kh\xF4ng c\xF3 b\u1ED9 n\xE0y.");
      if (s.wallet.tickets < 1) fail("tickets", "B\u1EA1n c\u1EA7n m\u1ED9t v\xE9 capsule.");
      s.wallet.tickets -= 1;
      const pull = pullCapsule(s, se.id, env2);
      bump(s, "capsule_pull", 1, env2);
      return { pull };
    }
    case "exchangeShards": {
      const hit = SERIES.flatMap((x) => x.items.map((i) => ({ s: x, i }))).find((x) => x.i.id === a.item);
      if (!hit) fail("item", "M\xF3n n\xE0y kh\xF4ng \u0111\u1ED5i b\u1EB1ng m\u1EA3nh \u0111\u01B0\u1EE3c.");
      if (owns(s, a.item)) fail("owned", "B\u1EA1n \u0111\xE3 c\xF3 m\xF3n n\xE0y.");
      const cost = ECONOMY.capsule.shardCost[hit.i.rarity];
      if (s.wallet.shards < cost) fail("shards", `C\u1EA7n ${cost} m\u1EA3nh.`);
      s.wallet.shards -= cost;
      grant(s, a.item);
      return;
    }
    case "claimSeries": {
      const se = series(a.series);
      if (!se) fail("series", "Kh\xF4ng c\xF3 b\u1ED9 n\xE0y.");
      if (!se.items.every((i) => owns(s, i.id))) fail("incomplete", "Ch\u01B0a \u0111\u1EE7 8 m\xF3n c\u1EE7a b\u1ED9.");
      if (owns(s, se.reward.item)) fail("claimed", "\u0110\xE3 nh\u1EADn qu\xE0 ho\xE0n th\xE0nh b\u1ED9.");
      grant(s, se.reward.item);
      if (!s.titles.includes(se.reward.title)) s.titles.push(se.reward.title);
      if (!s.poses.includes(se.reward.pose)) s.poses.push(se.reward.pose);
      return { item: se.reward.item };
    }
    case "setTitle": {
      if (a.title != null && !s.titles.includes(a.title)) fail("title", "B\u1EA1n ch\u01B0a c\xF3 danh hi\u1EC7u n\xE0y.");
      s.profile.title = a.title;
      return;
    }
    case "photo":
      bump(s, "photo", 1, env2);
      return;
    case "sharePreview":
      bump(s, "share_preview", 1, env2);
      return;
    case "setPrivacy": {
      if (a.visibility) s.social.visibility = a.visibility;
      if (a.shareGarden != null) s.social.shareGarden = a.shareGarden;
      if (a.showSources != null) s.social.showSources = a.showSources;
      return;
    }
    // ---- Nhà NPC (thay thế khi chưa có bạn thật; không có xu) ----
    case "visitNpc": {
      if (!NPC_HOMES.some((h) => h.npc === a.npc)) fail("npc", "Kh\xF4ng c\xF3 nh\xE0 n\xE0y.");
      if (capUsed(s, env2, "visit:npc:" + a.npc) === 0) {
        capAdd(s, env2, "visit:npc:" + a.npc, 1);
        bump(s, "visit", 1, env2);
        bump(s, "visit_npc", 1, env2);
      }
      if (!s.counters["home_visited:npc:" + a.npc]) s.counters["home_visited:npc:" + a.npc] = 1;
      return;
    }
    case "npcCompliment": {
      if (!NPCS.some((n) => n.id === a.npc)) fail("npc", "Kh\xF4ng c\xF3 NPC n\xE0y.");
      if (!STICKERS.some((x) => x.id === a.sticker)) fail("sticker", "L\u1EDDi khen kh\xF4ng h\u1EE3p l\u1EC7.");
      if (capUsed(s, env2, "compliment:npc:" + a.npc) > 0) fail("cap", "H\xF4m nay b\u1EA1n \u0111\xE3 khen nh\xE0 n\xE0y r\u1ED3i.");
      capAdd(s, env2, "compliment:npc:" + a.npc, 1);
      bump(s, "compliment", 1, env2);
      return;
    }
    case "npcHelpWater": {
      if (!NPC_HOMES.some((h) => h.npc === a.npc)) fail("npc", "Kh\xF4ng c\xF3 nh\xE0 n\xE0y.");
      if (capUsed(s, env2, "help:npc:" + a.npc) > 0) fail("cap", "H\xF4m nay b\u1EA1n \u0111\xE3 t\u01B0\u1EDBi gi\xFAp v\u01B0\u1EDDn n\xE0y r\u1ED3i.");
      capAdd(s, env2, "help:npc:" + a.npc, 1);
      bump(s, "help_water", 1, env2);
      return;
    }
  }
}
function plotAt(s, idx) {
  if (!Number.isInteger(idx) || idx < 0 || idx >= s.farm.unlocked) fail("plot", "\xD4 \u0111\u1EA5t n\xE0y ch\u01B0a m\u1EDF.");
  return s.farm.plots[idx];
}
function pullCapsule(s, seriesId, env2) {
  const se = series(seriesId);
  const cfg = ECONOMY.capsule;
  const pity = s.capsule.pity[seriesId] ?? { sinceRare: 0, sinceSpecial: 0 };
  pity.sinceRare += 1;
  pity.sinceSpecial += 1;
  let rarity;
  if (pity.sinceSpecial >= cfg.specialPity) rarity = "special";
  else if (pity.sinceRare >= cfg.rarePity) rarity = env2.rand() * (cfg.rates.rare + cfg.rates.special) < cfg.rates.special ? "special" : "rare";
  else {
    const roll = env2.rand() * 100;
    rarity = roll < cfg.rates.special ? "special" : roll < cfg.rates.special + cfg.rates.rare ? "rare" : "common";
  }
  const tier = se.items.filter((i) => i.rarity === rarity);
  const pick = tier[Math.floor(env2.rand() * tier.length)];
  if (rarity === "special") {
    pity.sinceSpecial = 0;
    pity.sinceRare = 0;
  } else if (rarity === "rare") pity.sinceRare = 0;
  s.capsule.pity[seriesId] = pity;
  const duplicate = owns(s, pick.id);
  let shards = 0;
  if (duplicate) {
    shards = cfg.shardsForDuplicate[rarity];
    s.wallet.shards += shards;
  } else grant(s, pick.id);
  const res = { requestId: env2.uuid(), series: seriesId, item: pick.id, rarity, duplicate, shards, at: env2.now };
  s.capsule.last = [res, ...s.capsule.last].slice(0, 10);
  return res;
}
function finishReward(s, env2, t, v) {
  const g = t.game;
  const rec = s.records[g] ?? { best: 0, runs: 0 };
  if (v.finished) {
    rec.runs += 1;
    bump(s, "game_finished", 1, env2);
    bump(s, "game:" + g, 1, env2);
  }
  let newBest = false;
  if (v.valid && v.score > rec.best) {
    rec.best = v.score;
    newBest = true;
  }
  s.records[g] = rec;
  let coins = 0;
  let note = v.note;
  let affection = 0;
  if (v.finished && v.valid) {
    const n = needsAt(s.pet.needs, env2.now);
    n.happiness = clamp100(n.happiness + ECONOMY.care.playGain);
    s.pet.needs = n;
    affection = addAffection(s, env2, ECONOMY.care.affectionPerGame);
    if (v.coins > 0) {
      const left = ECONOMY.games.dailyCoinCap - capUsed(s, env2, "games:coins");
      coins = Math.max(0, Math.min(left, v.coins, ECONOMY.games.maxCoinsPerRun));
      if (coins < v.coins) note = coins === 0 ? "dailyCap" : "partialCap";
      if (coins > 0) {
        s.wallet.coins += coins;
        capAdd(s, env2, "games:coins", coins);
      }
    }
  }
  return { score: v.score, valid: v.valid, finished: v.finished, coins, earned: v.coins, note, newBest, best: rec.best, affection };
}

// src/core/snapshot.ts
function buildSnapshot(s, now) {
  const rank = rankOf(s);
  return {
    v: 1,
    name: s.profile.name,
    title: s.profile.title,
    badges: s.badges.slice(0, 6),
    pet: { name: s.pet.name, species: s.pet.species, fur: s.pet.fur, wear: { ...s.pet.wear }, stage: petStage(s.pet.affection) },
    rooms: ROOMS.filter((r) => r.rank <= rank).map((r) => ({
      id: r.id,
      theme: s.home.rooms[r.id].theme,
      slots: JSON.parse(JSON.stringify(s.home.rooms[r.id].slots))
    })),
    garden: s.social.shareGarden ? s.farm.plots.filter((p) => p.crop && p.idx < s.farm.unlocked).map((p) => ({
      idx: p.idx,
      crop: p.crop,
      progress: Math.min(1, Math.max(0, (now - p.plantedAt) / Math.max(1, readyAt(p) - p.plantedAt))),
      helps: p.helps
    })) : null,
    showSources: s.social.showSources,
    publishedAt: now
  };
}

// src/games/rng.ts
var RNG_MOD = 2147483647;
var Lcg = class {
  state;
  constructor(seed) {
    let s = Math.floor(Math.abs(seed)) % RNG_MOD;
    if (s <= 0) s = 1;
    this.state = s;
  }
  next() {
    this.state = this.state * 48271 % RNG_MOD;
    return this.state;
  }
  /** Số nguyên trong [lo, hi] (hai đầu đều lấy). */
  int(lo, hi) {
    if (hi <= lo) {
      this.next();
      return lo;
    }
    return lo + this.next() % (hi - lo + 1);
  }
  /** Xác suất theo phần nghìn: true với xác suất p/1000. */
  chance(permille) {
    return this.next() % 1e3 < permille;
  }
  /** Số thực [0,1) — chỉ dùng cho phần không cần tái tạo trên máy chủ (hiệu ứng, xếp thẻ). */
  float() {
    return (this.next() - 1) / (RNG_MOD - 1);
  }
};
function tri(k, p) {
  const m = (k % p + p) % p;
  const u = Math.trunc(m * 4096 / p);
  return u < 1024 ? u : u < 3072 ? 2048 - u : u - 4096;
}
function isqrt(n) {
  return n <= 0 ? 0 : Math.floor(Math.sqrt(n));
}
function idiv(a, b) {
  return Math.trunc(a / b);
}

// src/games/cloudJump.ts
var CJ = {
  W: 1e5,
  G: 64,
  JUMP: 2500,
  MAXX: 1500,
  FOOT: 4e3,
  BODY: 12e3,
  PER_METER: 1e4,
  VIEW: 17e4,
  MAX_PLATFORMS: 40,
  MAX_STARS: 10,
  MAX_HAZARDS: 8,
  MAX_GAP: 38e3,
  REACTION: 12,
  REACH_SAFETY: 600,
  KNOCK: -333,
  WARMUP: 12e4,
  STAR_POINTS: 3,
  /** Lượt xếp hạng dài tối đa (tick) để máy chủ chạy lại có giới hạn. */
  MAX_TICKS: 60 * 60 * 15,
  STORM_R: 7e3,
  BIRD_R: 5e3
};
function lerp(a, b, d) {
  return a + idiv((b - a) * d, 1e3);
}
function difficulty(y) {
  return Math.min(1e3, Math.max(0, idiv(y * 1e3, 16e5)));
}
function reach(dy) {
  const disc = CJ.JUMP * CJ.JUMP - 2 * CJ.G * dy;
  if (disc < 0) return 0;
  const t = idiv(CJ.JUMP + isqrt(disc), CJ.G);
  return CJ.MAXX * Math.max(0, t - CJ.REACTION);
}
function platformX(p, time) {
  return p.amp > 0 ? p.x + idiv(p.amp * tri(p.phase + time, p.period), 1024) : p.x;
}
function hazardX(h, time) {
  return h.amp > 0 ? h.x + idiv(h.amp * tri(h.phase + time, h.period), 1024) : h.x;
}
function freeIntervals(blocked, lo, hi) {
  const out = [];
  let cursor = lo;
  const sorted = [...blocked].sort((a, b) => a[0] - b[0] || a[1] - b[1]);
  for (const b of sorted) {
    if (b[0] > cursor) out.push([cursor, Math.min(hi, b[0])]);
    cursor = Math.max(cursor, b[1]);
    if (cursor >= hi) break;
  }
  if (cursor < hi) out.push([cursor, hi]);
  return out.filter((i) => i[1] > i[0]);
}
var CloudJump = class {
  time = 0;
  petX = 5e4;
  petY = 0;
  velY = CJ.JUMP;
  targetX = 5e4;
  facingLeft = false;
  cameraY = 0;
  bestY = 0;
  stars = 0;
  hits = 0;
  landings = 0;
  over = false;
  platforms = [{ id: 0, x: 5e4, y: 0, w: 1e5, amp: 0, period: 0, phase: 0, fragile: false }];
  starList = [];
  hazards = [];
  /** Nhật ký điều khiển: [tick, x, tick, x, ...] — nộp lên máy chủ để chạy lại. */
  inputs = [];
  rng;
  nextId = 1;
  topY = 0;
  lastX = 5e4;
  lastW = 1e5;
  lastAmp = 0;
  lastFragile = false;
  prevX = 5e4;
  prevHalf = 5e4;
  constructor(seed) {
    this.rng = new Lcg(seed);
    this.generate();
  }
  get meters() {
    return idiv(this.bestY, CJ.PER_METER);
  }
  get score() {
    return this.meters + this.stars * CJ.STAR_POINTS;
  }
  /** Đặt điểm đến theo phần trăm bề ngang (0…1). Ghi vào nhật ký khi đổi. */
  setTarget(frac) {
    const x = Math.max(CJ.FOOT, Math.min(CJ.W - CJ.FOOT, Math.round(frac * CJ.W)));
    if (x === this.targetX) return;
    this.targetX = x;
    const n = this.inputs.length;
    if (n >= 2 && this.inputs[n - 2] === this.time) this.inputs[n - 1] = x;
    else this.inputs.push(this.time, x);
  }
  /** Áp dụng điều khiển đã ghi (chạy lại). */
  applyInput(x) {
    this.targetX = Math.max(CJ.FOOT, Math.min(CJ.W - CJ.FOOT, x));
  }
  tick() {
    if (this.over) return [];
    const ev = [];
    this.time += 1;
    const dx = this.targetX - this.petX;
    const move = Math.max(-CJ.MAXX, Math.min(CJ.MAXX, dx));
    this.petX = Math.max(CJ.FOOT, Math.min(CJ.W - CJ.FOOT, this.petX + move));
    if (Math.abs(move) > 50) this.facingLeft = move < 0;
    const prev = this.petY;
    this.velY -= CJ.G;
    this.petY += this.velY;
    if (this.velY < 0) {
      for (let i = 0; i < this.platforms.length; i++) {
        const p = this.platforms[i];
        if (prev >= p.y && this.petY <= p.y && Math.abs(this.petX - platformX(p, this.time)) <= idiv(p.w, 2) + CJ.FOOT) {
          this.petY = p.y;
          this.velY = CJ.JUMP;
          this.landings += 1;
          if (p.y > this.bestY) this.bestY = p.y;
          ev.push("bounce");
          if (p.fragile) {
            this.platforms.splice(i, 1);
            ev.push("broke");
          }
          break;
        }
      }
    }
    const bodyY = this.petY + idiv(CJ.BODY, 2);
    for (let i = 0; i < this.hazards.length; i++) {
      const h = this.hazards[i];
      const hx = this.petX - hazardX(h, this.time);
      const hy = bodyY - h.y;
      const r = (h.bird ? CJ.BIRD_R : CJ.STORM_R) + CJ.FOOT;
      if (hx * hx + hy * hy < r * r) {
        this.hazards.splice(i, 1);
        this.velY = Math.min(this.velY, CJ.KNOCK);
        this.hits += 1;
        ev.push("hit");
        break;
      }
    }
    for (let i = this.starList.length - 1; i >= 0; i--) {
      const s = this.starList[i];
      if (Math.abs(s.x - this.petX) <= 7e3 && s.y >= this.petY - 3e3 && s.y <= this.petY + CJ.BODY + 2e3) {
        this.starList.splice(i, 1);
        this.stars += 1;
        ev.push("star");
      }
    }
    this.cameraY = Math.max(this.cameraY, this.petY - idiv(CJ.VIEW * 4, 10));
    if (this.petY < this.cameraY - 14e3 || this.time >= CJ.MAX_TICKS) {
      this.over = true;
      ev.push("fell");
      return ev;
    }
    const floor = this.cameraY - 3e4;
    this.platforms = this.platforms.filter((p) => p.y >= floor);
    this.starList = this.starList.filter((s) => s.y >= floor);
    this.hazards = this.hazards.filter((h) => h.y >= floor);
    this.generate();
    return ev;
  }
  generate() {
    while (this.topY < this.cameraY + CJ.VIEW + 6e4 && this.platforms.length < CJ.MAX_PLATFORMS) this.addPlatform();
  }
  addPlatform() {
    const r = this.rng;
    const d = difficulty(this.topY);
    const early = this.topY < CJ.WARMUP;
    const dy = r.int(early ? 18e3 : lerp(2e4, 28e3, d), early ? 24e3 : lerp(28e3, CJ.MAX_GAP, d));
    const w = (early ? 32e3 : lerp(26e3, 14e3, d)) + r.int(-2e3, 2e3);
    const moving = !early && r.chance(lerp(200, 500, d));
    const amp = moving ? lerp(8e3, 18e3, d) : 0;
    const period = moving ? lerp(377, 222, d) : 0;
    const maxDX = Math.max(4e3, idiv(reach(dy) * CJ.REACH_SAFETY, 1e3) - amp);
    const edge = idiv(w, 2) + amp + 2e3;
    const lo = Math.max(edge, this.lastX - maxDX);
    const hi = Math.min(CJ.W - edge, this.lastX + maxDX);
    const x = lo < hi ? r.int(lo, hi) : Math.min(Math.max(this.lastX, edge), CJ.W - edge);
    const y = this.topY + dy;
    const phase = moving ? r.int(0, period - 1) : 0;
    const fragile = !early && !this.lastFragile && r.chance(lerp(80, 280, d));
    if (!early && this.hazards.length < CJ.MAX_HAZARDS && r.chance(lerp(180, 500, d))) {
      this.addHazard(this.prevX, this.prevHalf, this.lastX, this.topY, idiv(this.lastW, 2) + this.lastAmp, this.lastFragile, x, y, idiv(w, 2) + amp, d);
    }
    this.platforms.push({ id: this.nextId, x, y, w, amp, period, phase, fragile });
    this.nextId += 1;
    this.topY = y;
    this.prevX = this.lastX;
    this.prevHalf = idiv(this.lastW, 2) + this.lastAmp;
    this.lastX = x;
    this.lastW = w;
    this.lastAmp = amp;
    this.lastFragile = fragile;
    if (this.starList.length < CJ.MAX_STARS && r.chance(300)) {
      const sx = Math.min(Math.max(x + r.int(-1e4, 1e4), 8e3), CJ.W - 8e3);
      this.starList.push({ id: this.nextId, x: sx, y: y + r.int(18e3, 32e3) });
      this.nextId += 1;
    }
  }
  addHazard(zx, zHalf, ax, ay, aHalf, aFragile, bx, by, bHalf, d) {
    const r = this.rng;
    const midY = ay + idiv((by - ay) * r.int(450, 700), 1e3);
    const wantsBird = d > 150 && !aFragile && r.chance(500);
    const bm = 12e3;
    const sm = 14e3;
    if (wantsBird) {
      const lanes2 = freeIntervals([[ax - aHalf - bm, ax + aHalf + bm], [zx - zHalf - bm, zx + zHalf + bm]], 6e3, CJ.W - 6e3).filter((l) => l[1] - l[0] >= 24e3);
      if (lanes2.length) {
        let best = lanes2[0];
        for (const l of lanes2) if (l[1] - l[0] > best[1] - best[0]) best = l;
        const half = idiv(best[1] - best[0], 2);
        const v = lerp(450, 800, d);
        const period = Math.max(60, idiv(4 * half, v));
        this.hazards.push({ id: this.nextId, bird: true, x: best[0] + half, y: midY, amp: half, period, phase: r.int(0, period - 1) });
        this.nextId += 1;
        return;
      }
    }
    const lo = Math.min(ax - aHalf, bx - bHalf) - sm;
    const hi = Math.max(ax + aHalf, bx + bHalf) + sm;
    const lanes = freeIntervals([[lo, hi], [zx - zHalf - sm, zx + zHalf + sm]], 8e3, CJ.W - 8e3);
    if (!lanes.length) return;
    const lane = lanes[r.int(0, lanes.length - 1)];
    const x = r.int(lane[0], lane[1]);
    this.hazards.push({ id: this.nextId, bird: false, x, y: midY, amp: 0, period: 0, phase: 0 });
    this.nextId += 1;
  }
};
function replayCloudJump(seed, inputs, maxTicks = CJ.MAX_TICKS) {
  const e = new CloudJump(seed);
  let i = 0;
  while (!e.over && e.time < maxTicks) {
    while (i + 1 < inputs.length && inputs[i] <= e.time) {
      e.applyInput(inputs[i + 1]);
      i += 2;
    }
    e.tick();
  }
  return { meters: e.meters, stars: e.stars, ticks: e.time, over: e.over };
}
function validInputs(inputs) {
  if (!Array.isArray(inputs) || inputs.length % 2 !== 0 || inputs.length > 4e4) return false;
  let last = -1;
  for (let i = 0; i < inputs.length; i += 2) {
    const t = inputs[i], x = inputs[i + 1];
    if (!Number.isInteger(t) || !Number.isInteger(x) || t <= last || t < 0 || t > CJ.MAX_TICKS || x < 0 || x > CJ.W) return false;
    last = t;
  }
  return true;
}

// server/db.ts
import pg from "pg";
var pool = null;
function getPool() {
  if (pool) return pool;
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error("Thi\u1EBFu bi\u1EBFn m\xF4i tr\u01B0\u1EDDng DATABASE_URL tr\xEAn m\xE1y ch\u1EE7.");
  const local = /@(localhost|127\.0\.0\.1)[:/]/.test(url);
  pool = new pg.Pool({
    connectionString: url,
    max: Number(process.env.DATABASE_POOL_MAX ?? 3),
    idleTimeoutMillis: 1e4,
    connectionTimeoutMillis: 8e3,
    // Supabase yêu cầu SSL. Nếu có DATABASE_CA (chứng chỉ của Supabase) thì xác minh đầy đủ.
    ssl: local ? void 0 : process.env.DATABASE_CA ? { ca: process.env.DATABASE_CA } : { rejectUnauthorized: false }
  });
  return pool;
}
async function tx(fn) {
  const c = await getPool().connect();
  try {
    await c.query("begin");
    const r = await fn(c);
    await c.query("commit");
    return r;
  } catch (e) {
    try {
      await c.query("rollback");
    } catch {
    }
    throw e;
  } finally {
    c.release();
  }
}
async function q(c, sql, params = []) {
  const r = await c.query(sql, params);
  return r.rows;
}

// server/ops.ts
var ALLOWED = [
  "onboard",
  "setNames",
  "storySeen",
  "tutorial",
  "tutorialHidden",
  "place",
  "theme",
  "saveLayout",
  "applyLayout",
  "equip",
  "saveOutfit",
  "applyOutfit",
  "buyItem",
  "buyStock",
  "sell",
  "cook",
  "feed",
  "freeMeal",
  "clean",
  "cuddle",
  "plant",
  "water",
  "harvest",
  "buyPlot",
  "freeSeeds",
  "completeOrder",
  "rerollOrder",
  "claimChapter",
  "claimDaily",
  "startRun",
  "finishRun",
  "buyTicket",
  "openCapsule",
  "exchangeShards",
  "claimSeries",
  "setTitle",
  "photo",
  "sharePreview",
  "setPrivacy",
  "visitNpc",
  "npcCompliment",
  "npcHelpWater"
];
var UUID2 = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
var CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
function env(now = Date.now()) {
  return { now, rand: () => randomInt(0, 2 ** 31) / 2 ** 31, uuid: randomUUID };
}
var BANNED = ["dit", "\u0111\u1ECBt", "l\u1ED3n", "bu\u1ED3i", "c\u1EB7c", "\u0111\u1EE5", "fuck", "shit", "bitch", "nigger", "\u0111\u0129"];
function badName(name) {
  const n = name.toLowerCase().normalize("NFC").replace(/\s+/g, "");
  return BANNED.some((w) => n.includes(w));
}
function newCode() {
  let s = "";
  for (let i = 0; i < 8; i++) s += CODE_CHARS[randomInt(0, CODE_CHARS.length)];
  return s;
}
function uniqueItems(s) {
  return s.owned.filter((id) => {
    const it = item(id);
    return it && it.source !== "starter";
  }).length;
}
async function loadAccount(c, user, lock) {
  const rows = await q(c, `select user_id, state, friend_code, is_anonymous from cozii.accounts where user_id = $1 ${lock ? "for update" : ""}`, [user.id]);
  if (rows[0]) {
    if (rows[0].is_anonymous !== user.isAnonymous) {
      await c.query("update cozii.accounts set is_anonymous = $2 where user_id = $1", [user.id, user.isAnonymous]);
      rows[0].is_anonymous = user.isAnonymous;
    }
    return rows[0];
  }
  const now = Date.now();
  const state = newState(user.id, now, env(now), "online");
  for (let attempt = 0; attempt < 6; attempt++) {
    const code = newCode();
    const ins = await q(
      c,
      `insert into cozii.accounts (user_id, state, friend_code, is_anonymous) values ($1, $2, $3, $4)
       on conflict do nothing returning user_id, state, friend_code, is_anonymous`,
      [user.id, state, code, user.isAnonymous]
    );
    if (ins[0]) {
      await c.query("insert into cozii.homes (user_id) values ($1) on conflict do nothing", [user.id]);
      if (lock) await c.query("select 1 from cozii.accounts where user_id = $1 for update", [user.id]);
      return ins[0];
    }
    const again = await q(c, `select user_id, state, friend_code, is_anonymous from cozii.accounts where user_id = $1 ${lock ? "for update" : ""}`, [user.id]);
    if (again[0]) return again[0];
  }
  throw new HttpError(500, "code", "Kh\xF4ng t\u1EA1o \u0111\u01B0\u1EE3c m\xE3 b\u1EA1n b\xE8. Th\u1EED l\u1EA1i nh\xE9.");
}
function present(row, s, now) {
  s.mode = "online";
  s.serverNow = now;
  s.profile.id = row.user_id;
  s.profile.friendCode = row.friend_code;
  s.profile.isAnonymous = row.is_anonymous;
  return s;
}
async function save(c, uid, s) {
  await c.query(
    `update cozii.accounts set state = $2, display_name = $3, pet_name = $4, species = $5, title = $6, unique_items = $7,
       version = version + 1, updated_at = now() where user_id = $1`,
    [uid, s, s.profile.name, s.pet.name, s.pet.species, s.profile.title, uniqueItems(s)]
  );
}
function weeklySeed(week) {
  return fnv1a("cozii-week-" + week) % 2147483646 + 1;
}
async function opState(user) {
  return tx(async (c) => {
    const row = await loadAccount(c, user, false);
    return present(row, row.state, Date.now());
  });
}
async function opAct(user, body) {
  const a = body.action;
  const requestId = body.requestId;
  if (!a || typeof a !== "object" || !ALLOWED.includes(a.type)) throw new HttpError(400, "action", "Thao t\xE1c kh\xF4ng h\u1EE3p l\u1EC7.");
  if (!requestId || !UUID2.test(requestId)) throw new HttpError(400, "request", "Thi\u1EBFu m\xE3 y\xEAu c\u1EA7u.");
  if (JSON.stringify(a).length > 2e5) throw new HttpError(413, "size", "D\u1EEF li\u1EC7u qu\xE1 l\u1EDBn.");
  return tx(async (c) => {
    const row = await loadAccount(c, user, true);
    const prior = await q(c, "select response from cozii.tx_log where user_id = $1 and request_id = $2", [user.id, requestId]);
    const now = Date.now();
    if (prior[0]) return { state: present(row, row.state, now), result: prior[0].response.result, replayed: true };
    const recent = await q(c, `select count(*) n from cozii.tx_log where user_id = $1 and created_at > now() - interval '10 seconds'`, [user.id]);
    if (Number(recent[0].n) > 40) throw new HttpError(429, "rate", "B\u1EA1n thao t\xE1c nhanh qu\xE1, ngh\u1EC9 m\u1ED9t ch\xFAt nh\xE9.");
    const s = row.state;
    const e = env(now);
    if (a.type === "onboard" && (badName(a.playerName) || badName(a.petName)) || a.type === "setNames" && (a.playerName && badName(a.playerName) || a.petName && badName(a.petName))) {
      throw new HttpError(400, "name", "T\xEAn n\xE0y kh\xF4ng ph\xF9 h\u1EE3p. Ch\u1ECDn t\xEAn kh\xE1c nh\xE9.");
    }
    let ticket;
    let verified = false;
    let mismatch = false;
    if (a.type === "finishRun") {
      ticket = s.runs.find((r) => r.id === a.run);
      if (ticket?.ranked && a.result?.game === "cloudJump" && a.result.completed) {
        const inputs = a.result.inputs;
        if (!validInputs(inputs)) {
          a.result = { ...a.result, completed: true, meters: 1e6, stars: 0 };
        } else {
          const elapsed = (now - ticket.startedAt) / 1e3;
          const r = replayCloudJump(ticket.seed, inputs, Math.min(CJ.MAX_TICKS, Math.ceil((elapsed + 10) * 60)));
          verified = r.over && r.ticks / 60 <= elapsed + 10;
          mismatch = r.meters !== a.result.meters || r.stars !== a.result.stars;
          a.result = { ...a.result, meters: r.meters, stars: r.stars, completed: r.over };
        }
      }
    }
    let result;
    try {
      result = apply(s, a, e);
    } catch (err) {
      if (err instanceof GameError) throw new HttpError(400, err.code, err.message);
      throw err;
    }
    if (a.type === "startRun") {
      const t = result.run;
      t.ranked = t.game === "cloudJump";
      if (t.weekly && t.game === "cloudJump") t.seed = weeklySeed(weekKey(now));
      const inState = s.runs.find((r) => r.id === t.id);
      if (inState) Object.assign(inState, t);
    }
    if (a.type === "finishRun" && ticket?.ranked && result) {
      const r = result;
      result.verified = verified;
      if (mismatch) result.note = "mismatch";
      if (verified && r.valid && r.finished && a.result.game === "cloudJump") {
        await c.query(
          `insert into cozii.scores (run_id, user_id, game, week, weekly, score, meters, stars, verified)
           values ($1, $2, 'cloudJump', $3, $4, $5, $6, $7, true) on conflict (run_id) do nothing`,
          [ticket.id, user.id, weekKey(ticket.startedAt), ticket.weekly, r.score, a.result.meters, a.result.stars]
        );
      }
    }
    if (a.type === "setPrivacy" && a.visibility) {
      await c.query("insert into cozii.homes (user_id, visibility) values ($1, $2) on conflict (user_id) do update set visibility = excluded.visibility", [user.id, a.visibility]);
    }
    await save(c, user.id, s);
    await c.query("insert into cozii.tx_log (user_id, request_id, op, response) values ($1, $2, $3, $4)", [user.id, requestId, a.type, { result: result ?? null }]);
    if (randomInt(0, 50) === 0) await c.query(`delete from cozii.tx_log where user_id = $1 and created_at < now() - interval '14 days'`, [user.id]);
    return { state: present(row, s, now), result: result ?? null };
  });
}
var person = (r) => ({ id: r.user_id, name: r.display_name || "B\u1EA1n nh\u1ECF", petName: r.pet_name, species: r.species, title: r.title, friendCode: r.friend_code });
var PERSON_COLS = "a.user_id, a.display_name, a.pet_name, a.species, a.title, a.friend_code";
async function blockedEither(c, a, b) {
  const r = await q(c, "select 1 from cozii.blocks where (blocker = $1 and blocked = $2) or (blocker = $2 and blocked = $1)", [a, b]);
  return r.length > 0;
}
async function areFriends(c, a, b) {
  const r = await q(c, "select 1 from cozii.friendships where user_id = $1 and friend_id = $2", [a, b]);
  return r.length > 0;
}
function checkUuid(id) {
  if (typeof id !== "string" || !UUID2.test(id)) throw new HttpError(400, "id", "M\xE3 ng\u01B0\u1EDDi ch\u01A1i kh\xF4ng h\u1EE3p l\u1EC7.");
  return id;
}
async function opFindByCode(user, code) {
  return tx(async (c) => {
    await loadAccount(c, user, false);
    const rows = await q(c, `select ${PERSON_COLS} from cozii.accounts a where a.friend_code = $1 and a.user_id <> $2`, [String(code ?? "").toUpperCase().trim(), user.id]);
    if (!rows[0] || await blockedEither(c, user.id, rows[0].user_id)) return null;
    return person(rows[0]);
  });
}
async function opSendRequest(user, code) {
  return tx(async (c) => {
    await loadAccount(c, user, false);
    const target = (await q(c, `select ${PERSON_COLS} from cozii.accounts a where a.friend_code = $1`, [String(code ?? "").toUpperCase().trim()]))[0];
    if (!target) throw new HttpError(404, "code", "Kh\xF4ng t\xECm th\u1EA5y m\xE3 b\u1EA1n b\xE8 n\xE0y.");
    if (target.user_id === user.id) throw new HttpError(400, "self", "\u0110\xE2y l\xE0 m\xE3 c\u1EE7a ch\xEDnh b\u1EA1n.");
    if (await blockedEither(c, user.id, target.user_id)) throw new HttpError(404, "code", "Kh\xF4ng t\xECm th\u1EA5y m\xE3 b\u1EA1n b\xE8 n\xE0y.");
    if (await areFriends(c, user.id, target.user_id)) throw new HttpError(400, "friends", "Hai b\u1EA1n \u0111\xE3 l\xE0 b\u1EA1n b\xE8.");
    const reverse = await q(c, "select id from cozii.friend_requests where from_id = $1 and to_id = $2", [target.user_id, user.id]);
    if (reverse[0]) {
      await makeFriends(c, user.id, target.user_id);
      return { accepted: true };
    }
    const mine = await q(c, "select count(*) n from cozii.friend_requests where from_id = $1", [user.id]);
    if (Number(mine[0].n) >= ECONOMY.social.maxPendingRequests) throw new HttpError(400, "cap", "B\u1EA1n \u0111ang ch\u1EDD qu\xE1 nhi\u1EC1u l\u1EDDi m\u1EDDi.");
    await c.query("insert into cozii.friend_requests (from_id, to_id) values ($1, $2) on conflict do nothing", [user.id, target.user_id]);
    return { accepted: false };
  });
}
async function makeFriends(c, a, b) {
  const count = await q(c, "select count(*) n from cozii.friendships where user_id = $1 or user_id = $2 group by user_id order by 1 desc limit 1", [a, b]);
  if (count[0] && Number(count[0].n) >= ECONOMY.social.maxFriends) throw new HttpError(400, "cap", `M\u1ED7i ng\u01B0\u1EDDi t\u1ED1i \u0111a ${ECONOMY.social.maxFriends} b\u1EA1n.`);
  await c.query("insert into cozii.friendships (user_id, friend_id) values ($1, $2), ($2, $1) on conflict do nothing", [a, b]);
  await c.query("delete from cozii.friend_requests where (from_id = $1 and to_id = $2) or (from_id = $2 and to_id = $1)", [a, b]);
}
async function opRespondRequest(user, id, accept) {
  return tx(async (c) => {
    const r = (await q(c, "select from_id from cozii.friend_requests where id = $1 and to_id = $2 for update", [checkUuid(id), user.id]))[0];
    if (!r) throw new HttpError(404, "request", "L\u1EDDi m\u1EDDi kh\xF4ng c\xF2n n\u1EEFa.");
    if (accept && !await blockedEither(c, user.id, r.from_id)) await makeFriends(c, user.id, r.from_id);
    else await c.query("delete from cozii.friend_requests where id = $1", [id]);
    return { ok: true };
  });
}
async function opListFriends(user) {
  return tx(async (c) => {
    await loadAccount(c, user, false);
    const rows = await q(c, `select ${PERSON_COLS}, f.created_at from cozii.friendships f join cozii.accounts a on a.user_id = f.friend_id where f.user_id = $1 order by a.display_name`, [user.id]);
    return rows.map((r) => ({ ...person(r), since: r.created_at.toISOString() }));
  });
}
async function opListRequests(user) {
  return tx(async (c) => {
    const inc = await q(c, `select r.id, r.created_at, ${PERSON_COLS} from cozii.friend_requests r join cozii.accounts a on a.user_id = r.from_id where r.to_id = $1 order by r.created_at desc limit 50`, [user.id]);
    const out = await q(c, `select r.id, r.created_at, ${PERSON_COLS} from cozii.friend_requests r join cozii.accounts a on a.user_id = r.to_id where r.from_id = $1 order by r.created_at desc limit 50`, [user.id]);
    const map = (r) => ({ id: r.id, from: person(r), createdAt: r.created_at.toISOString() });
    return { incoming: inc.map(map), outgoing: out.map(map) };
  });
}
async function opRemoveFriend(user, other) {
  return tx(async (c) => {
    await c.query("delete from cozii.friendships where (user_id = $1 and friend_id = $2) or (user_id = $2 and friend_id = $1)", [user.id, checkUuid(other)]);
    return { ok: true };
  });
}
async function opBlock(user, other) {
  return tx(async (c) => {
    checkUuid(other);
    if (other === user.id) throw new HttpError(400, "self", "Kh\xF4ng th\u1EC3 t\u1EF1 ch\u1EB7n m\xECnh.");
    const exists = await q(c, "select 1 from cozii.accounts where user_id = $1", [other]);
    if (!exists.length) throw new HttpError(404, "user", "Kh\xF4ng t\xECm th\u1EA5y ng\u01B0\u1EDDi ch\u01A1i.");
    await c.query("insert into cozii.blocks (blocker, blocked) values ($1, $2) on conflict do nothing", [user.id, other]);
    await c.query("delete from cozii.friendships where (user_id = $1 and friend_id = $2) or (user_id = $2 and friend_id = $1)", [user.id, other]);
    await c.query("delete from cozii.friend_requests where (from_id = $1 and to_id = $2) or (from_id = $2 and to_id = $1)", [user.id, other]);
    return { ok: true };
  });
}
async function opUnblock(user, other) {
  return tx(async (c) => {
    await c.query("delete from cozii.blocks where blocker = $1 and blocked = $2", [user.id, checkUuid(other)]);
    return { ok: true };
  });
}
async function opListBlocked(user) {
  return tx(async (c) => (await q(c, `select ${PERSON_COLS} from cozii.blocks b join cozii.accounts a on a.user_id = b.blocked where b.blocker = $1`, [user.id])).map(person));
}
async function opReport(user, other, reason, details) {
  return tx(async (c) => {
    checkUuid(other);
    if (!["name", "spam", "other"].includes(reason)) throw new HttpError(400, "reason", "L\xFD do kh\xF4ng h\u1EE3p l\u1EC7.");
    const today = await q(c, `select count(*) n from cozii.reports where reporter = $1 and created_at > now() - interval '1 day'`, [user.id]);
    if (Number(today[0].n) >= 10) throw new HttpError(429, "cap", "H\xF4m nay b\u1EA1n \u0111\xE3 g\u1EEDi nhi\u1EC1u b\xE1o c\xE1o r\u1ED3i.");
    await c.query("insert into cozii.reports (reporter, target, reason, details) values ($1, $2, $3, $4)", [user.id, other, reason, String(details ?? "").slice(0, 300)]);
    return { ok: true };
  });
}
async function opPublish(user) {
  return tx(async (c) => {
    const row = await loadAccount(c, user, true);
    const s = row.state;
    if (!s.profile.onboarded) throw new HttpError(400, "onboard", "H\xE3y ch\u1ECDn b\u1EA1n nh\u1ECF tr\u01B0\u1EDBc.");
    const now = Date.now();
    const snap = buildSnapshot(s, now);
    snap.garden = s.social.shareGarden ? [] : null;
    s.social.publishedAt = now;
    await c.query(
      `insert into cozii.homes (user_id, visibility, snapshot, published_at) values ($1, $2, $3, now())
       on conflict (user_id) do update set visibility = excluded.visibility, snapshot = excluded.snapshot, published_at = now()`,
      [user.id, s.social.visibility, snap]
    );
    await save(c, user.id, s);
    return { publishedAt: new Date(now).toISOString() };
  });
}
async function canView(c, viewer, host) {
  const friends = await areFriends(c, viewer, host);
  if (viewer === host) return { ok: true, friends };
  if (await blockedEither(c, viewer, host)) return { ok: false, reason: "Kh\xF4ng xem \u0111\u01B0\u1EE3c ng\xF4i nh\xE0 n\xE0y.", friends };
  const h = (await q(c, "select visibility, snapshot from cozii.homes where user_id = $1", [host]))[0];
  if (!h || !h.snapshot) return { ok: false, reason: "Ng\xF4i nh\xE0 n\xE0y ch\u01B0a \u0111\u01B0\u1EE3c \u0111\u0103ng.", friends };
  if (h.visibility === "private") return { ok: false, reason: "Ch\u1EE7 nh\xE0 \u0111ang \u0111\u1EC3 ch\u1EBF \u0111\u1ED9 ri\xEAng t\u01B0.", friends };
  if (h.visibility === "friends" && !friends) return { ok: false, reason: "Ch\u1EE7 nh\xE0 ch\u1EC9 chia s\u1EBB v\u1EDBi b\u1EA1n b\xE8.", friends };
  return { ok: true, snapshot: h.snapshot, friends };
}
function liveGarden(s, now) {
  if (!s.social.shareGarden) return null;
  return s.farm.plots.filter((p) => p.crop && p.idx < s.farm.unlocked).map((p) => ({
    idx: p.idx,
    crop: p.crop,
    helps: p.helps,
    progress: Math.min(1, Math.max(0, (now - p.plantedAt) / Math.max(1, readyAt(p) - p.plantedAt)))
  }));
}
async function opVisit(user, hostId) {
  checkUuid(hostId);
  return tx(async (c) => {
    const me = await loadAccount(c, user, true);
    const v = await canView(c, user.id, hostId);
    if (!v.ok) throw new HttpError(403, "private", v.reason);
    const host = (await q(c, `select a.user_id, a.state, a.friend_code, a.is_anonymous, a.display_name, a.pet_name, a.species, a.title from cozii.accounts a where a.user_id = $1`, [hostId]))[0];
    if (!host) throw new HttpError(404, "user", "Kh\xF4ng t\xECm th\u1EA5y ng\u01B0\u1EDDi ch\u01A1i.");
    const now = Date.now();
    const day = dayKey(now);
    let snapshot = v.snapshot;
    if (!snapshot && hostId === user.id) snapshot = buildSnapshot(me.state, now);
    snapshot = { ...snapshot, garden: liveGarden(host.state, now) };
    let coins = 0;
    if (hostId !== user.id) {
      const ins = await q(c, "insert into cozii.visits (visitor, host, day) values ($1, $2, $3) on conflict do nothing returning 1", [user.id, hostId, day]);
      const s = me.state;
      if (ins.length) {
        const rewarded = await q(c, "select count(*) n from cozii.visits where visitor = $1 and day = $2 and rewarded", [user.id, day]);
        if (Number(rewarded[0].n) < ECONOMY.social.maxRewardedVisitsPerDay) {
          coins = ECONOMY.social.visitCoins;
          s.wallet.coins += coins;
          await c.query("update cozii.visits set rewarded = true where visitor = $1 and host = $2 and day = $3", [user.id, hostId, day]);
        }
        bump(s, "visit", 1, env(now));
      }
      s.counters["home_visited:" + hostId] = 1;
      await save(c, user.id, s);
    }
    const comp = (await q(c, "select sticker from cozii.compliments where visitor = $1 and host = $2 and day = $3", [user.id, hostId, day]))[0];
    const helped = await q(c, "select plot, planted_at from cozii.help_waters where helper = $1 and host = $2", [user.id, hostId]);
    const helpedPlots = host.state.farm.plots.filter((p) => p.crop && helped.some((h) => h.plot === p.idx && Number(h.planted_at) === p.plantedAt)).map((p) => p.idx);
    const usedToday = await q(c, "select count(*) n from cozii.help_waters where helper = $1 and day = $2", [user.id, day]);
    return {
      snapshot,
      host: person(host),
      isFriend: v.friends,
      coins,
      complimentedToday: comp?.sticker ?? null,
      helpedPlots,
      helpsLeftToday: Math.max(0, ECONOMY.social.maxHelpWaterPerDay - Number(usedToday[0].n))
    };
  });
}
async function opCompliment(user, hostId, sticker) {
  checkUuid(hostId);
  if (!STICKERS.some((s) => s.id === sticker)) throw new HttpError(400, "sticker", "L\u1EDDi khen kh\xF4ng h\u1EE3p l\u1EC7.");
  if (hostId === user.id) throw new HttpError(400, "self", "Kh\xF4ng t\u1EF1 khen nh\xE0 m\xECnh \u0111\u01B0\u1EE3c.");
  return tx(async (c) => {
    const me = await loadAccount(c, user, true);
    const v = await canView(c, user.id, hostId);
    if (!v.ok) throw new HttpError(403, "private", v.reason);
    const now = Date.now();
    const day = dayKey(now);
    const sent = await q(c, "select count(*) n from cozii.compliments where visitor = $1 and day = $2", [user.id, day]);
    if (Number(sent[0].n) >= ECONOMY.social.maxComplimentsPerDay) throw new HttpError(429, "cap", "H\xF4m nay b\u1EA1n \u0111\xE3 g\u1EEDi \u0111\u1EE7 l\u1EDDi khen r\u1ED3i.");
    const ins = await q(c, "insert into cozii.compliments (visitor, host, day, sticker) values ($1, $2, $3, $4) on conflict do nothing returning 1", [user.id, hostId, day, sticker]);
    if (!ins.length) throw new HttpError(400, "done", "H\xF4m nay b\u1EA1n \u0111\xE3 khen nh\xE0 n\xE0y r\u1ED3i.");
    bump(me.state, "compliment", 1, env(now));
    await save(c, user.id, me.state);
    return { ok: true };
  });
}
async function opHelpWater(user, hostId, plot, requestId) {
  checkUuid(hostId);
  if (!UUID2.test(requestId ?? "")) throw new HttpError(400, "request", "Thi\u1EBFu m\xE3 y\xEAu c\u1EA7u.");
  if (!Number.isInteger(plot) || plot < 0 || plot > 11) throw new HttpError(400, "plot", "\xD4 \u0111\u1EA5t kh\xF4ng h\u1EE3p l\u1EC7.");
  if (hostId === user.id) throw new HttpError(400, "self", "\u0110\xE2y l\xE0 v\u01B0\u1EDDn c\u1EE7a b\u1EA1n, h\xE3y t\u01B0\u1EDBi \u1EDF V\u01B0\u1EDDn rau.");
  return tx(async (c) => {
    const [first, second] = [user.id, hostId].sort();
    await q(c, "select 1 from cozii.accounts where user_id = $1 for update", [first]);
    await q(c, "select 1 from cozii.accounts where user_id = $1 for update", [second]);
    const me = await loadAccount(c, user, true);
    const prior = await q(c, "select response from cozii.tx_log where user_id = $1 and request_id = $2", [user.id, requestId]);
    if (prior[0]) return prior[0].response.result;
    if (await blockedEither(c, user.id, hostId)) throw new HttpError(403, "blocked", "Kh\xF4ng t\u01B0\u1EDBi gi\xFAp \u0111\u01B0\u1EE3c v\u01B0\u1EDDn n\xE0y.");
    if (!await areFriends(c, user.id, hostId)) throw new HttpError(403, "friends", "Ch\u1EC9 b\u1EA1n b\xE8 m\u1EDBi t\u01B0\u1EDBi gi\xFAp \u0111\u01B0\u1EE3c.");
    const host = (await q(c, "select user_id, state, friend_code, is_anonymous from cozii.accounts where user_id = $1", [hostId]))[0];
    if (!host) throw new HttpError(404, "user", "Kh\xF4ng t\xECm th\u1EA5y ng\u01B0\u1EDDi ch\u01A1i.");
    const hs = host.state;
    if (!hs.social.shareGarden) throw new HttpError(403, "garden", "Ch\u1EE7 nh\xE0 kh\xF4ng chia s\u1EBB v\u01B0\u1EDDn.");
    const now = Date.now();
    const day = dayKey(now);
    const p = hs.farm.plots[plot];
    if (!p || plot >= hs.farm.unlocked || !p.crop) throw new HttpError(400, "empty", "\xD4 n\xE0y kh\xF4ng c\xF3 c\xE2y.");
    if (now >= readyAt(p)) throw new HttpError(400, "ready", "C\xE2y \u0111\xE3 ch\xEDn r\u1ED3i, kh\xF4ng c\u1EA7n t\u01B0\u1EDBi.");
    if (p.helps >= ECONOMY.farm.maxHelpsPerCrop) throw new HttpError(400, "cap", "C\xE2y n\xE0y \u0111\xE3 \u0111\u01B0\u1EE3c b\u1EA1n b\xE8 t\u01B0\u1EDBi \u0111\u1EE7 l\u01B0\u1EE3t.");
    const used = await q(c, "select count(*) n from cozii.help_waters where helper = $1 and day = $2", [user.id, day]);
    if (Number(used[0].n) >= ECONOMY.social.maxHelpWaterPerDay) throw new HttpError(429, "cap", "H\xF4m nay b\u1EA1n \u0111\xE3 t\u01B0\u1EDBi gi\xFAp \u0111\u1EE7 l\u01B0\u1EE3t.");
    const ins = await q(c, "insert into cozii.help_waters (helper, host, plot, planted_at, day) values ($1, $2, $3, $4, $5) on conflict do nothing returning 1", [user.id, hostId, plot, p.plantedAt, day]);
    if (!ins.length) throw new HttpError(400, "done", "B\u1EA1n \u0111\xE3 t\u01B0\u1EDBi c\xE2y n\xE0y r\u1ED3i.");
    p.helps += 1;
    p.cutPct = Math.min(ECONOMY.farm.maxCutPct, p.cutPct + ECONOMY.farm.helpWaterCutPct);
    await save(c, hostId, hs);
    const s = me.state;
    s.wallet.coins += ECONOMY.social.helpWaterCoins;
    bump(s, "help_water", 1, env(now));
    await save(c, user.id, s);
    const result = { coins: ECONOMY.social.helpWaterCoins };
    await c.query("insert into cozii.tx_log (user_id, request_id, op, response) values ($1, $2, $3, $4)", [user.id, requestId, "helpWater", { result }]);
    return result;
  });
}
async function opDiscover(user, cursor) {
  return tx(async (c) => {
    const before = cursor && !Number.isNaN(Date.parse(cursor)) ? new Date(cursor) : new Date(Date.now() + 6e4);
    const rows = await q(
      c,
      `select ${PERSON_COLS}, h.published_at from cozii.homes h join cozii.accounts a on a.user_id = h.user_id
       where h.visibility = 'public' and h.snapshot is not null and h.published_at < $2 and h.user_id <> $1
         and not exists (select 1 from cozii.blocks b where (b.blocker = $1 and b.blocked = h.user_id) or (b.blocker = h.user_id and b.blocked = $1))
       order by h.published_at desc limit 21`,
      [user.id, before]
    );
    const page = rows.slice(0, 20);
    return { homes: page.map(person), next: rows.length > 20 ? page[page.length - 1].published_at.toISOString() : null };
  });
}
async function opInbox(user) {
  return tx(async (c) => {
    const comps = await q(
      c,
      `select a.user_id, a.display_name, x.sticker, x.created_at from cozii.compliments x join cozii.accounts a on a.user_id = x.visitor
       where x.host = $1 and not exists (select 1 from cozii.blocks b where b.blocker = $1 and b.blocked = x.visitor)
       order by x.created_at desc limit 40`,
      [user.id]
    );
    const helps = await q(
      c,
      `select a.user_id, a.display_name, x.created_at from cozii.help_waters x join cozii.accounts a on a.user_id = x.helper
       where x.host = $1 and not exists (select 1 from cozii.blocks b where b.blocker = $1 and b.blocked = x.helper)
       order by x.created_at desc limit 20`,
      [user.id]
    );
    return [
      ...comps.map((r) => ({ kind: "compliment", from: { id: r.user_id, name: r.display_name }, sticker: r.sticker, at: r.created_at.toISOString() })),
      ...helps.map((r) => ({ kind: "help_water", from: { id: r.user_id, name: r.display_name }, at: r.created_at.toISOString() }))
    ].sort((a, b) => b.at.localeCompare(a.at));
  });
}
async function opLeaderboard(user, game, scope, weekArg) {
  if (!GAME_IDS.includes(game) || game !== "cloudJump") throw new HttpError(400, "game", "Tr\xF2 n\xE0y ch\u01B0a c\xF3 b\u1EA3ng x\u1EBFp h\u1EA1ng.");
  if (!["all", "weekly", "friends"].includes(scope)) throw new HttpError(400, "scope", "Ph\u1EA1m vi kh\xF4ng h\u1EE3p l\u1EC7.");
  const week = weekArg && /^\d{4}-W\d{2}$/.test(weekArg) ? weekArg : weekKey(Date.now());
  return tx(async (c) => {
    const where = scope === "weekly" ? `s.weekly and s.week = $2` : `true`;
    const who = scope === "friends" ? `and (s.user_id = $1 or s.user_id in (select friend_id from cozii.friendships where user_id = $1))` : `and not a.is_anonymous`;
    const sql = `
      with best as (
        select s.user_id, max(s.score) score from cozii.scores s join cozii.accounts a on a.user_id = s.user_id
        where s.game = 'cloudJump' and s.verified and ${where} ${who}
          and not exists (select 1 from cozii.blocks b where (b.blocker = $1 and b.blocked = s.user_id) or (b.blocker = s.user_id and b.blocked = $1))
        group by s.user_id
      ), ranked as (
        select b.user_id, b.score, a.display_name, a.pet_name, a.species, rank() over (order by b.score desc) as rank
        from best b join cozii.accounts a on a.user_id = b.user_id
      )
      select * from ranked order by rank, display_name limit 50`;
    const rows = await q(c, sql, [user.id, week]);
    const map = (r) => ({ rank: Number(r.rank), userId: r.user_id, name: r.display_name || "B\u1EA1n nh\u1ECF", petName: r.pet_name, species: r.species, score: r.score, me: r.user_id === user.id });
    let me = rows.find((r) => r.user_id === user.id);
    if (!me) {
      const all = await q(c, sql.replace("limit 50", ""), [user.id, week]);
      me = all.find((r) => r.user_id === user.id);
    }
    return { rows: rows.map(map), me: me ? map(me) : null, week };
  });
}
async function opCollectors(user) {
  return tx(async (c) => {
    const sql = `select a.user_id, a.display_name, a.pet_name, a.species, a.unique_items score, rank() over (order by a.unique_items desc) rank
      from cozii.accounts a where not a.is_anonymous and a.unique_items > 0
        and not exists (select 1 from cozii.blocks b where (b.blocker = $1 and b.blocked = a.user_id) or (b.blocker = a.user_id and b.blocked = $1))`;
    const rows = await q(c, sql + " order by rank, a.display_name limit 50", [user.id]);
    const map = (r) => ({ rank: Number(r.rank), userId: r.user_id, name: r.display_name || "B\u1EA1n nh\u1ECF", petName: r.pet_name, species: r.species, score: Number(r.score), me: r.user_id === user.id });
    const mine = (await q(c, `select * from (${sql}) x where x.user_id = $1`, [user.id]))[0];
    return { rows: rows.map(map), me: mine ? map(mine) : null };
  });
}
async function opClaimBadges(user) {
  return tx(async (c) => {
    const me = await loadAccount(c, user, true);
    if (me.is_anonymous) throw new HttpError(403, "anon", "G\u1EAFn email cho t\xE0i kho\u1EA3n \u0111\u1EC3 nh\u1EADn huy hi\u1EC7u x\u1EBFp h\u1EA1ng.");
    const current = weekKey(Date.now());
    const weeks = await q(c, `select distinct week from cozii.scores where user_id = $1 and weekly and verified and week < $2 order by week desc limit 8`, [user.id, current]);
    const got = [];
    for (const { week } of weeks) {
      const r = (await q(
        c,
        `select rank from (select s.user_id, rank() over (order by max(s.score) desc) rank from cozii.scores s join cozii.accounts a on a.user_id = s.user_id
          where s.game = 'cloudJump' and s.weekly and s.verified and s.week = $2 and not a.is_anonymous group by s.user_id) x where x.user_id = $1`,
        [user.id, week]
      ))[0];
      if (!r) continue;
      const rank = Number(r.rank);
      const badge = rank === 1 ? `C\xFAp v\xE0ng ${week}` : rank <= 3 ? `Top 3 ${week}` : rank <= 10 ? `Top 10 ${week}` : null;
      if (badge && !me.state.badges.includes(badge)) {
        me.state.badges.push(badge);
        got.push(badge);
      }
    }
    if (got.length) await save(c, user.id, me.state);
    return { badges: got };
  });
}

// server/api.ts
async function dispatch(user, b) {
  const s = (k) => typeof b[k] === "string" ? b[k] : "";
  switch (b.op) {
    case "state":
      return opState(user);
    case "act":
      return opAct(user, b);
    case "publish":
      return opPublish(user);
    case "findByCode":
      return opFindByCode(user, s("code"));
    case "sendRequest":
      return opSendRequest(user, s("code"));
    case "respondRequest":
      return opRespondRequest(user, s("id"), b.accept === true);
    case "listFriends":
      return opListFriends(user);
    case "listRequests":
      return opListRequests(user);
    case "removeFriend":
      return opRemoveFriend(user, s("other"));
    case "block":
      return opBlock(user, s("other"));
    case "unblock":
      return opUnblock(user, s("other"));
    case "listBlocked":
      return opListBlocked(user);
    case "report":
      return opReport(user, s("other"), s("reason"), s("details"));
    case "discover":
      return opDiscover(user, typeof b.cursor === "string" ? b.cursor : null);
    case "visit":
      return opVisit(user, s("host"));
    case "compliment":
      return opCompliment(user, s("host"), s("sticker"));
    case "helpWater":
      return opHelpWater(user, s("host"), Number(b.plot), s("requestId"));
    case "inbox":
      return opInbox(user);
    case "leaderboard":
      return opLeaderboard(user, s("game"), s("scope"), typeof b.week === "string" ? b.week : null);
    case "collectors":
      return opCollectors(user);
    case "claimBadges":
      return opClaimBadges(user);
    default:
      throw new HttpError(400, "op", "Thao t\xE1c kh\xF4ng t\u1ED3n t\u1EA1i.");
  }
}
async function readBody(req) {
  if (req.body && typeof req.body === "object") return req.body;
  if (typeof req.body === "string") return JSON.parse(req.body);
  const chunks = [];
  let size = 0;
  for await (const ch of req) {
    size += ch.length;
    if (size > 512e3) throw new HttpError(413, "size", "D\u1EEF li\u1EC7u qu\xE1 l\u1EDBn.");
    chunks.push(ch);
  }
  const text = Buffer.concat(chunks).toString("utf8");
  return text ? JSON.parse(text) : {};
}
function send(res, status, data) {
  res.statusCode = status;
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.setHeader("Cache-Control", "no-store");
  res.end(JSON.stringify(data));
}
async function handler(req, res) {
  if (req.method !== "POST") return send(res, 405, { error: { code: "method", message: "Ch\u1EC9 nh\u1EADn POST." } });
  try {
    const user = await authenticate(req.headers.authorization);
    const body = await readBody(req);
    const data = await dispatch(user, body);
    send(res, 200, { data });
  } catch (e) {
    if (e instanceof HttpError) return send(res, e.status, { error: { code: e.code, message: e.message } });
    if (e instanceof SyntaxError) return send(res, 400, { error: { code: "json", message: "D\u1EEF li\u1EC7u g\u1EEDi l\xEAn kh\xF4ng h\u1EE3p l\u1EC7." } });
    const pgCode = e.code;
    if (pgCode === "23514") return send(res, 400, { error: { code: "constraint", message: "Thao t\xE1c b\u1ECB t\u1EEB ch\u1ED1i (s\u1ED1 d\u01B0 kh\xF4ng \u0111\u1EE7)." } });
    if (pgCode === "40P01" || pgCode === "40001") return send(res, 409, { error: { code: "retry", message: "M\xE1y ch\u1EE7 \u0111ang b\u1EADn, th\u1EED l\u1EA1i nh\xE9." } });
    console.error("cozii api error", e);
    send(res, 500, { error: { code: "server", message: "M\xE1y ch\u1EE7 g\u1EB7p l\u1ED7i. Th\u1EED l\u1EA1i sau nh\xE9." } });
  }
}
export {
  handler as default,
  dispatch
};
