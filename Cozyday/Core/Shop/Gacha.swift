import Foundation

/// Máy gacha "Mây Mây": quay ra đồ CHỈ có trong máy (không trùng đồ bán ở cửa hàng — so bằng ID).
/// Toàn bộ là luật thuần (không đụng lưu trữ), ngẫu nhiên qua RNG truyền vào để test được.
/// Tỉ lệ, bảo đảm và giá hiện công khai trong màn máy gacha.
enum GachaConfig {
    static let singlePrice = 60
    static let tenPrice = 540
    static let tenCount = 10

    /// Trọng số ở một lượt thường (tổng 100): Thường 57, Hiếm 30, Quý 10, Bí mật 3.
    static let weights: [(ItemRarity, Int)] = [(.common, 57), (.rare, 30), (.epic, 10), (.secret, 3)]

    /// Chắc chắn ra món Quý trở lên nếu 9 lượt liền trước đó không có.
    static let epicPity = 10
    /// 39 lượt liền không có Bí mật → lượt thứ 40 chắc chắn ra Bí mật. Ra Bí mật thì đếm lại từ đầu.
    static let secretPity = 40

    /// Món trùng (đã có hết cả nhóm) đổi lại thành xu.
    static func duplicateRefund(_ r: ItemRarity) -> Int {
        switch r {
        case .common: return 20
        case .rare: return 30
        case .epic: return 60
        case .secret: return 150
        }
    }

    static var rulesText: [String] {
        [
            "Một lượt \(singlePrice) xu hoặc 1 vé. 10 lượt \(tenPrice) xu (bớt 60 xu, chắc chắn có ít nhất một món Hiếm).",
            "Tỉ lệ mỗi lượt thường: Thường 57%, Hiếm 30%, Quý 10%, Bí mật 3%.",
            "Bảo đảm: cứ \(epicPity) lượt chắc chắn có một món Quý trở lên; 39 lượt liền không có Bí mật thì lượt thứ \(secretPity) chắc chắn ra Bí mật. Vì có bảo đảm, tỉ lệ thực tế nhận Bí mật sau nhiều lượt cao hơn mức 3% của một lượt (trung bình khoảng 1 món mỗi 23 lượt).",
            "Máy chỉ có đồ riêng của máy, không có đồ bán ở cửa hàng. Máy ưu tiên món bạn chưa có trong nhóm.",
            "Đã có đủ cả nhóm thì món trùng đổi thành xu: Thường \(duplicateRefund(.common)), Hiếm \(duplicateRefund(.rare)), Quý \(duplicateRefund(.epic)), Bí mật \(duplicateRefund(.secret)) xu.",
            "Món Bí mật chỉ hiện bóng cho tới khi bạn quay được."
        ]
    }
}

enum GachaPayment: Equatable {
    case coins
    case tickets
}

extension CatalogItem {
    /// Độ hiếm dùng trong máy gacha và nhãn hiển thị. Đồ của máy dùng đúng độ hiếm đã đặt;
    /// đồ cửa hàng không có độ hiếm riêng thì xếp theo giá (chỉ để hiển thị).
    var tier: ItemRarity {
        if gachaOnly || rarity != .common { return rarity }
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
    case invalidCount
    case insufficientCoins(needed: Int, available: Int)
    case insufficientTickets(needed: Int, available: Int)
    case emptyPool

    var errorDescription: String? {
        switch self {
        case .invalidCount: return "Chỉ có thể quay 1 hoặc 10 lượt."
        case .insufficientCoins(let needed, let available): return "Cần \(needed) xu, bạn đang có \(available) xu."
        case .insufficientTickets(let needed, let available): return "Cần \(needed) vé, bạn đang có \(available) vé."
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
    /// Các món có thể ra, theo độ hiếm: chỉ đồ riêng của máy (`gachaOnly`), không có đồ bán ở cửa hàng.
    static func pool() -> [ItemRarity: [CatalogItem]] {
        let items = Catalog.items.filter { $0.gachaOnly && !$0.isDefault }
        return Dictionary(grouping: items, by: \.tier)
    }

    /// Nhóm gần nhất còn món (ưu tiên hạ xuống, rồi mới nâng lên) — chỉ dùng khi một nhóm trống.
    static func nearestTier(_ tier: ItemRarity, in pool: [ItemRarity: [CatalogItem]]) -> ItemRarity? {
        let all = ItemRarity.allCases
        guard let i = all.firstIndex(of: tier) else { return nil }
        let order = all[...i].reversed() + all[(i + 1)...]
        return order.first { !(pool[$0] ?? []).isEmpty }
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

    /// Quay `count` lượt (1 hoặc 10) bằng xu hoặc vé (mỗi lượt 1 vé). Từng lượt xử lý tuần tự: bộ đếm bảo đảm
    /// cập nhật sau mỗi lượt. Trả về từng lượt với dòng sổ cái đã tính sẵn (giá/vé trừ đi, cộng hoàn xu nếu trùng).
    static func pull<R: RandomNumberGenerator>(count: Int, ledger: [LedgerEntry], owned: Set<String>, now: Date,
                                               payment: GachaPayment = .coins, rng: inout R) throws -> [GachaPull] {
        guard count == 1 || count == GachaConfig.tenCount else { throw GachaError.invalidCount }
        let price = payment == .tickets ? 0 : (count >= GachaConfig.tenCount ? GachaConfig.tenPrice : GachaConfig.singlePrice * count)
        let wallet = Wallet(entries: ledger)
        switch payment {
        case .coins:
            guard wallet.coins >= price else { throw GachaError.insufficientCoins(needed: price, available: wallet.coins) }
        case .tickets:
            guard wallet.tickets >= count else { throw GachaError.insufficientTickets(needed: count, available: wallet.tickets) }
        }
        let pool = pool()
        guard !pool.isEmpty else { throw GachaError.emptyPool }

        var (sinceEpic, sinceSecret) = pityCounters(ledger: ledger)
        var have = owned
        var results: [GachaPull] = []
        // Chia giá cho từng lượt (lượt cuối nhận phần dư) để mỗi dòng sổ cái tự đủ nghĩa.
        let each = price / count
        // Preserve draw order across fast batches and device clock rollback.
        let batchTime = max(now, ledger.filter { $0.kind == .gacha }.map(\.createdAt).max()?.addingTimeInterval(0.001) ?? now)
        for i in 0..<count {
            let guaranteeRare = count >= GachaConfig.tenCount && i == count - 1 && !results.contains { $0.tier >= .rare }
            let rolled = rollTier(sinceEpic: sinceEpic, sinceSecret: sinceSecret, minimum: guaranteeRare ? .rare : .common, rng: &rng)
            guard let tier = nearestTier(rolled, in: pool) else { throw GachaError.emptyPool }
            let group = pool[tier] ?? []
            let fresh = group.filter { !Catalog.isOwned($0.id, owned: have) }
            let pickFrom = fresh.isEmpty ? group : fresh
            let item = pickFrom[Int.random(in: 0..<pickFrom.count, using: &rng)]
            let duplicate = fresh.isEmpty
            let refund = duplicate ? GachaConfig.duplicateRefund(tier) : 0
            let cost = i == count - 1 ? price - each * (count - 1) : each
            let id = UUID()
            let entry = LedgerEntry(id: id, key: LedgerKeys.gacha(id), kind: .gacha, xp: 0, coins: refund - cost,
                                    createdAt: batchTime.addingTimeInterval(Double(i) * 0.001), refID: item.id,
                                    memo: "\(tier.label): \(item.name)\(duplicate ? " (trùng, +\(refund) xu)" : "")",
                                    tickets: payment == .tickets ? -1 : 0)
            results.append(GachaPull(itemID: item.id, tier: tier, isDuplicate: duplicate, refund: refund, entry: entry))
            have.insert(item.id)
            sinceEpic = tier >= .epic ? 0 : sinceEpic + 1
            sinceSecret = tier == .secret ? 0 : sinceSecret + 1
        }
        return results
    }
}
