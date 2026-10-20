import Foundation

/// Máy gacha "Mây Mây": quay ra trang phục / hình dạng cho thú cưng. Toàn bộ là luật thuần (không đụng lưu trữ),
/// ngẫu nhiên qua RNG truyền vào để test được. Tỉ lệ và giá hiện công khai trong màn máy gacha.
enum GachaConfig {
    static let singlePrice = 60
    static let tenPrice = 540
    static let tenCount = 10

    /// Trọng số theo độ hiếm (tổng 100).
    static let weights: [(ItemRarity, Int)] = [(.common, 60), (.rare, 28), (.epic, 10), (.secret, 2)]

    /// Chắc chắn ra món Quý trở lên nếu 9 lượt liền trước đó không có.
    static let epicPity = 10
    /// Chắc chắn ra món Bí mật ở lượt thứ 60 kể từ món Bí mật gần nhất.
    static let secretPity = 60

    /// Món trùng (đã có) đổi lại thành xu.
    static func duplicateRefund(_ r: ItemRarity) -> Int {
        switch r {
        case .common: return 15
        case .rare: return 25
        case .epic: return 50
        case .secret: return 120
        }
    }

    static let pullSlots: Set<ItemSlot> = [.species, .hat, .glasses, .neck, .outfit, .back]

    static let rulesText: [String] = [
        "Một lượt \(singlePrice) xu, 10 lượt \(tenPrice) xu (bớt 60 xu, chắc chắn có ít nhất một món Hiếm).",
        "Tỉ lệ: Thường 60%, Hiếm 28%, Quý 10%, Bí mật 2%.",
        "Cứ \(epicPity) lượt chắc chắn có một món Quý trở lên. Lượt thứ \(secretPity) kể từ món Bí mật gần nhất chắc chắn ra Bí mật.",
        "Máy ưu tiên món bạn chưa có. Nếu cả nhóm đã có đủ, món trùng đổi thành xu: Thường \(duplicateRefund(.common)), Hiếm \(duplicateRefund(.rare)), Quý \(duplicateRefund(.epic)), Bí mật \(duplicateRefund(.secret)) xu.",
        "Món Bí mật chỉ có trong máy và chỉ hiện bóng đen cho tới khi bạn quay được."
    ]
}

extension CatalogItem {
    /// Độ hiếm hiệu lực: món có độ hiếm riêng giữ nguyên, món cửa hàng thường xếp theo giá.
    var tier: ItemRarity {
        if rarity != .common { return rarity }
        if price >= 90 { return .epic }
        if price >= 50 { return .rare }
        return .common
    }
}

struct GachaPull: Equatable {
    var itemID: String
    var tier: ItemRarity
    var isDuplicate: Bool
    var refund: Int
    var entry: LedgerEntry
}

enum GachaError: Error, Equatable, LocalizedError {
    case insufficientCoins(needed: Int, available: Int)
    case emptyPool

    var errorDescription: String? {
        switch self {
        case .insufficientCoins(let needed, let available): return "Cần \(needed) xu, bạn đang có \(available) xu."
        case .emptyPool: return "Máy gacha đang trống."
        }
    }
}

/// Bộ sinh số giả ngẫu nhiên có hạt giống (SplitMix64), dùng chung cho test và app.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

enum GachaPolicy {
    /// Các món có thể ra, theo độ hiếm (bỏ món mặc định).
    static func pool() -> [ItemRarity: [CatalogItem]] {
        let items = Catalog.items.filter { GachaConfig.pullSlots.contains($0.slot) && !$0.isDefault }
        return Dictionary(grouping: items, by: \.tier)
    }

    /// Số lượt kể từ món Quý trở lên / Bí mật gần nhất, đọc từ sổ cái (không cần lưu bộ đếm riêng).
    static func pityCounters(ledger: [LedgerEntry]) -> (sinceEpic: Int, sinceSecret: Int) {
        var sinceEpic = 0, sinceSecret = 0
        var epicSeen = false, secretSeen = false
        for e in ledger.reversed() where e.kind == .gacha {
            let tier = e.refID.flatMap(Catalog.item)?.tier ?? .common
            if !secretSeen {
                if tier == .secret { secretSeen = true } else { sinceSecret += 1 }
            }
            if !epicSeen {
                if tier >= .epic { epicSeen = true } else { sinceEpic += 1 }
            }
            if epicSeen && secretSeen { break }
        }
        return (sinceEpic, sinceSecret)
    }

    static func rollTier<R: RandomNumberGenerator>(sinceEpic: Int, sinceSecret: Int, minimum: ItemRarity, rng: inout R) -> ItemRarity {
        if sinceSecret + 1 >= GachaConfig.secretPity { return .secret }
        let total = GachaConfig.weights.reduce(0) { $0 + $1.1 }
        var roll = Int.random(in: 0..<total, using: &rng)
        var tier = ItemRarity.common
        for (r, w) in GachaConfig.weights {
            if roll < w { tier = r; break }
            roll -= w
        }
        if sinceEpic + 1 >= GachaConfig.epicPity && tier < .epic { tier = .epic }
        return max(tier, minimum)
    }

    /// Quay `count` lượt (1 hoặc 10). Trả về từng lượt với dòng sổ cái đã tính sẵn (giá trừ đi, cộng hoàn xu nếu trùng).
    static func pull<R: RandomNumberGenerator>(count: Int, ledger: [LedgerEntry], owned: Set<String>, now: Date,
                                               rng: inout R) throws -> [GachaPull] {
        let price = count >= GachaConfig.tenCount ? GachaConfig.tenPrice : GachaConfig.singlePrice * count
        let wallet = Wallet(entries: ledger)
        guard wallet.coins >= price else { throw GachaError.insufficientCoins(needed: price, available: wallet.coins) }
        let pool = pool()
        guard !pool.isEmpty else { throw GachaError.emptyPool }

        var (sinceEpic, sinceSecret) = pityCounters(ledger: ledger)
        var have = owned
        var results: [GachaPull] = []
        // Chia giá cho từng lượt (lượt cuối nhận phần dư) để mỗi dòng sổ cái tự đủ nghĩa.
        let each = price / count
        for i in 0..<count {
            let guaranteeRare = count >= GachaConfig.tenCount && i == count - 1 && !results.contains { $0.tier >= .rare }
            var tier = rollTier(sinceEpic: sinceEpic, sinceSecret: sinceSecret, minimum: guaranteeRare ? .rare : .common, rng: &rng)
            // Nhóm trống (ví dụ chưa có món Bí mật nào): hạ dần xuống nhóm có món.
            while (pool[tier] ?? []).isEmpty, tier != .common {
                tier = ItemRarity.allCases[max(0, ItemRarity.allCases.firstIndex(of: tier)! - 1)]
            }
            let group = pool[tier] ?? []
            guard !group.isEmpty else { throw GachaError.emptyPool }
            let fresh = group.filter { !Catalog.isOwned($0.id, owned: have) }
            let pickFrom = fresh.isEmpty ? group : fresh
            let item = pickFrom[Int.random(in: 0..<pickFrom.count, using: &rng)]
            let duplicate = fresh.isEmpty
            let refund = duplicate ? GachaConfig.duplicateRefund(tier) : 0
            let cost = i == count - 1 ? price - each * (count - 1) : each
            let id = UUID()
            let entry = LedgerEntry(id: id, key: LedgerKeys.gacha(id), kind: .gacha, xp: 0, coins: refund - cost,
                                    createdAt: now.addingTimeInterval(Double(i) * 0.001), refID: item.id,
                                    memo: "\(tier.label): \(item.name)\(duplicate ? " (trùng, +\(refund) xu)" : "")")
            results.append(GachaPull(itemID: item.id, tier: tier, isDuplicate: duplicate, refund: refund, entry: entry))
            have.insert(item.id)
            sinceEpic = tier >= .epic ? 0 : sinceEpic + 1
            sinceSecret = tier == .secret ? 0 : sinceSecret + 1
        }
        return results
    }
}
