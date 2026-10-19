import Foundation

/// Mọi con số của vòng chăm thú cưng tập trung ở đây (giải thích trong docs/DATA_AND_RULES_VI.md).
///
/// Nhu cầu thay đổi rất chậm và chỉ được tính từ mốc thời gian đã lưu (không có timer chạy nền).
/// Thú cưng không bao giờ ốm, bỏ đi, mất cấp hay mất đồ — chỉ số thấp nhất là `floor`.
enum CareConfig {
    static let maxValue = 100.0
    /// Mức sàn: vắng mặt bao lâu cũng không thấp hơn.
    static let floor = 20.0
    /// Dưới mức này là "cần chăm" (và chỉ khi đó chăm mới có thưởng).
    static let needsCareBelow = 35.0
    /// Từ mức này trở lên là "ổn".
    static let goodFrom = 70.0

    /// Điểm giảm mỗi giờ: từ 100 xuống dưới 35 mất khoảng 22 giờ (no bụng), 26 giờ (vui vẻ), 33 giờ (nhà sạch).
    static let fullnessPerHour = 3.0
    static let cleanlinessPerHour = 2.0
    static let happinessPerHour = 2.5
    /// Vắng mặt lâu hơn chỉ tính như 24 giờ.
    static let maxDecayHours = 24.0

    /// Chỉ số ban đầu (thú cưng mới hoặc bản cũ vừa nâng cấp): dễ chịu, không đói, nhà không bẩn.
    static let initialFullness = 80.0
    static let initialCleanliness = 85.0
    static let initialHappiness = 80.0

    /// Gói đồ ăn chào mừng: tặng đúng một lần khi tạo hồ sơ chăm sóc.
    static let welcomePack: [(foodID: String, count: Int)] = [("food.apple", 3), ("food.riceball", 1)]

    // Tác dụng của từng hành động
    static let cleanTo = 100.0
    static let cuddleGain = 35.0
    /// Bữa cơ bản miễn phí: chỉ khi đang đói, đưa no bụng lên mức này (không tạo vật phẩm).
    static let freeMealTo = 55.0
    /// No từ mức này trở lên thì không cho ăn thêm (không tốn đồ ăn).
    static let fullEnough = 95.0
    /// Nhà sạch từ mức này trở lên thì không cần dọn.
    static let cleanEnough = 95.0
    /// Thời gian vuốt ve thật sự (giây) để hoàn thành một lượt nựng.
    static let cuddleSeconds = 3.5
    /// Khoảng nghỉ tối đa giữa hai lần vuốt vẫn được tính là đang nựng.
    static let cuddleMaxGap = 0.25

    // Thưởng (chỉ khi chỉ số TRƯỚC khi chăm dưới `needsCareBelow`)
    static let feedXP = 2, feedCoins = 1
    static let cleanXP = 3, cleanCoins = 2
    static let cuddleXP = 2, cuddleCoins = 1
    /// Mỗi loại chăm sóc tối đa 2 lượt có thưởng mỗi ngày.
    static let rewardedPerKindPerDay = 2
    /// Tổng thưởng chăm sóc mỗi ngày (tách riêng khỏi hạn mức xu Sân chơi).
    static let dailyXPCap = 12
    static let dailyCoinCap = 6

    /// Lịch sử hành động chăm sóc giữ lại (ngày) — đủ để tính hạn mức và chống làm lại.
    static let historyDays = 30

    static let rulesText: [String] = [
        "No bụng, Nhà sạch và Vui vẻ giảm rất chậm theo thời gian (vắng mặt lâu chỉ tính như 24 giờ) và không bao giờ thấp hơn \(Int(floor)).",
        "Chăm đúng lúc thú cưng cần (chỉ số dưới \(Int(needsCareBelow))): cho ăn +\(feedXP) XP +\(feedCoins) xu, dọn nhà +\(cleanXP) XP +\(cleanCoins) xu, nựng +\(cuddleXP) XP +\(cuddleCoins) xu.",
        "Mỗi loại chăm sóc có thưởng tối đa \(rewardedPerKindPerDay) lần/ngày, tổng tối đa \(dailyXPCap) XP và \(dailyCoinCap) xu/ngày. Hết hạn mức vẫn chăm bình thường.",
        "Bữa cơ bản miễn phí luôn có khi thú cưng đói, kể cả khi bạn hết xu (không tính thưởng).",
        "Thú cưng không ốm, không bỏ đi, không mất cấp hay mất đồ khi bạn bận."
    ]
}

/// Ba nhu cầu của thú cưng (thang 0–100, cao là tốt).
enum NeedKind: String, Codable, CaseIterable, Identifiable {
    case fullness, cleanliness, happiness

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fullness: return "No bụng"
        case .cleanliness: return "Nhà sạch"
        case .happiness: return "Vui vẻ"
        }
    }

    var symbol: String {
        switch self {
        case .fullness: return "fork.knife"
        case .cleanliness: return "sparkles"
        case .happiness: return "heart.fill"
        }
    }

    var perHour: Double {
        switch self {
        case .fullness: return CareConfig.fullnessPerHour
        case .cleanliness: return CareConfig.cleanlinessPerHour
        case .happiness: return CareConfig.happinessPerHour
        }
    }
}

enum NeedLevel: Equatable {
    case needsCare, normal, good

    init(_ value: Double) {
        if value < CareConfig.needsCareBelow { self = .needsCare }
        else if value < CareConfig.goodFrom { self = .normal }
        else { self = .good }
    }

    var label: String {
        switch self {
        case .needsCare: return "Cần chăm"
        case .normal: return "Bình thường"
        case .good: return "Ổn"
        }
    }
}

/// Chỉ số nhu cầu đã chốt tại thời điểm `asOf`. Đọc nhiều lần không làm giảm thêm:
/// giá trị hiện tại luôn được tính lại từ bản đã lưu (`at(_:)`), chỉ ghi lại khi có hành động chăm sóc.
struct PetNeeds: Codable, Equatable {
    var fullness: Double
    var cleanliness: Double
    var happiness: Double
    var asOf: Date

    static func initial(at date: Date) -> PetNeeds {
        PetNeeds(fullness: CareConfig.initialFullness, cleanliness: CareConfig.initialCleanliness,
                 happiness: CareConfig.initialHappiness, asOf: date)
    }

    subscript(kind: NeedKind) -> Double {
        get {
            switch kind {
            case .fullness: return fullness
            case .cleanliness: return cleanliness
            case .happiness: return happiness
            }
        }
        set {
            let v = min(CareConfig.maxValue, max(0, newValue))
            switch kind {
            case .fullness: fullness = v
            case .cleanliness: cleanliness = v
            case .happiness: happiness = v
            }
        }
    }

    func level(_ kind: NeedKind) -> NeedLevel { NeedLevel(self[kind]) }

    /// Chỉ số tại `now`. Đồng hồ quay ngược (now < asOf): giữ nguyên, không tăng.
    /// Mốc `asOf` không bao giờ lùi lại, nên đổi giờ qua lại không tạo thêm suy giảm hay hồi phục.
    func at(_ now: Date) -> PetNeeds {
        let hours = min(max(0, now.timeIntervalSince(asOf) / 3600), CareConfig.maxDecayHours)
        var next = self
        for kind in NeedKind.allCases {
            let value = self[kind]
            if value > CareConfig.floor {
                next[kind] = max(CareConfig.floor, value - kind.perHour * hours)
            }
        }
        next.asOf = max(asOf, now)
        return next
    }

    /// Nhu cầu nổi bật nhất cần chăm (thấp nhất, dưới ngưỡng), nil nếu mọi thứ ổn.
    var mostUrgent: NeedKind? {
        let order: [NeedKind] = [.fullness, .happiness, .cleanliness]
        return order.filter { self[$0] < CareConfig.needsCareBelow }.min { self[$0] < self[$1] }
    }

    /// Kiểm tra và kẹp giá trị (dữ liệu khôi phục từ file).
    var isValid: Bool {
        NeedKind.allCases.allSatisfy { (0...CareConfig.maxValue).contains(self[$0]) && self[$0].isFinite }
    }
}

// MARK: Đồ ăn

/// Đồ ăn hư cấu trong game (không phải hướng dẫn dinh dưỡng cho thú thật). Tiêu hao, mua lặp lại được.
struct FoodItem: Identifiable, Equatable {
    let id: String
    let name: String
    let price: Int
    let fullness: Int
    let happiness: Int
    let blurb: String
}

enum FoodCatalog {
    static let all: [FoodItem] = [
        FoodItem(id: "food.apple", name: "Táo giòn", price: 3, fullness: 18, happiness: 0, blurb: "Đỏ au, cắn nghe rộp rộp."),
        FoodItem(id: "food.carrot", name: "Cà rốt", price: 3, fullness: 15, happiness: 3, blurb: "Ngọt nhẹ, màu cam tươi."),
        FoodItem(id: "food.oatcookie", name: "Bánh yến mạch", price: 6, fullness: 25, happiness: 6, blurb: "Thơm bơ, giòn tan."),
        FoodItem(id: "food.riceball", name: "Cơm nắm", price: 8, fullness: 35, happiness: 4, blurb: "Tròn tròn, có lá rong biển."),
        FoodItem(id: "food.veggiesoup", name: "Súp rau", price: 12, fullness: 45, happiness: 8, blurb: "Ấm bụng ngày mưa."),
        FoodItem(id: "food.picnic", name: "Hộp picnic", price: 25, fullness: 70, happiness: 20, blurb: "Bánh mì, dâu tây và một tấm khăn kẻ ô.")
    ]

    static func item(_ id: String) -> FoodItem? { all.first { $0.id == id } }
    static let maxPerPurchase = 10
    static let maxStock = 99
}

// MARK: Hành động chăm sóc

enum CareActionKind: String, Codable, CaseIterable {
    case feed, freeMeal, clean, cuddle

    var need: NeedKind {
        switch self {
        case .feed, .freeMeal: return .fullness
        case .clean: return .cleanliness
        case .cuddle: return .happiness
        }
    }

    /// Loại tính hạn mức (bữa miễn phí không bao giờ có thưởng).
    var baseReward: (xp: Int, coins: Int) {
        switch self {
        case .feed: return (CareConfig.feedXP, CareConfig.feedCoins)
        case .freeMeal: return (0, 0)
        case .clean: return (CareConfig.cleanXP, CareConfig.cleanCoins)
        case .cuddle: return (CareConfig.cuddleXP, CareConfig.cuddleCoins)
        }
    }

    var label: String {
        switch self {
        case .feed: return "Cho ăn"
        case .freeMeal: return "Bữa cơ bản"
        case .clean: return "Dọn nhà"
        case .cuddle: return "Nựng"
        }
    }
}

/// Lý do có/không có thưởng — hiển thị cho người dùng sau khi lưu thành công.
enum CareRewardNote: String, Codable, Equatable {
    case rewarded
    /// Chỉ số trước khi chăm chưa dưới ngưỡng cần chăm.
    case notNeeded
    /// Bữa cơ bản miễn phí không có thưởng.
    case freeMeal
    /// Đã đủ 2 lượt có thưởng của loại này hôm nay.
    case kindLimit
    /// Đã đủ tổng hạn mức chăm sóc hôm nay.
    case dailyLimit
}

/// Một lần chăm sóc đã lưu. `id` = careActionID (khóa chống làm lại khi thử lại).
struct CareActionRecord: Codable, Equatable, Identifiable {
    var id: UUID
    var kind: CareActionKind
    /// Ngày địa phương lúc hoàn thành — dùng tính hạn mức.
    var day: DayKey
    var performedAt: Date
    var foodID: String?
    var before: Int
    var after: Int
    var xp: Int
    var coins: Int
    var note: CareRewardNote

    var isRewarded: Bool { xp > 0 || coins > 0 }
}

enum CareError: Error, Equatable, LocalizedError {
    case unknownFood
    case noFood
    case alreadyFull
    case notHungry
    case alreadyClean
    case notEnoughCoins(needed: Int, have: Int)
    case invalidQuantity
    case stockFull

    var errorDescription: String? {
        switch self {
        case .unknownFood: return "Không tìm thấy món ăn này."
        case .noFood: return "Khay đã hết món này. Bạn có thể mua thêm hoặc dùng bữa cơ bản khi thú cưng đói."
        case .alreadyFull: return "Bụng no căng rồi, để dành món này cho lần sau nhé."
        case .notHungry: return "Bữa cơ bản chỉ dùng khi thú cưng đang đói."
        case .alreadyClean: return "Nhà đang sạch bong rồi!"
        case .notEnoughCoins(let needed, let have): return "Cần \(needed) xu, bạn đang có \(have) xu."
        case .invalidQuantity: return "Số lượng không hợp lệ."
        case .stockFull: return "Khay đồ ăn đã đầy (tối đa \(FoodCatalog.maxStock) món mỗi loại)."
        }
    }
}

struct CareOutcome: Equatable {
    var needs: PetNeeds
    var record: CareActionRecord
    var ledger: LedgerEntry?
}

/// Quyết định một hành động chăm sóc — thuần, không đụng lưu trữ.
enum CarePolicy {
    /// - Parameters:
    ///   - stored: chỉ số đã lưu (sẽ được tính suy giảm tới `now`).
    ///   - history: các hành động đã lưu (để tính hạn mức trong `day`).
    static func perform(_ kind: CareActionKind, foodID: String? = nil, actionID: UUID, stored: PetNeeds,
                        now: Date, day: DayKey, history: [CareActionRecord], existingKeys: Set<String>) throws -> CareOutcome {
        var needs = stored.at(now)
        let before = needs[kind.need]
        var food: FoodItem?
        switch kind {
        case .feed:
            guard let id = foodID, let item = FoodCatalog.item(id) else { throw CareError.unknownFood }
            guard needs.fullness < CareConfig.fullEnough else { throw CareError.alreadyFull }
            food = item
            needs.fullness += Double(item.fullness)
            needs.happiness += Double(item.happiness)
        case .freeMeal:
            guard needs.fullness < CareConfig.needsCareBelow else { throw CareError.notHungry }
            needs.fullness = max(needs.fullness, CareConfig.freeMealTo)
        case .clean:
            guard needs.cleanliness < CareConfig.cleanEnough else { throw CareError.alreadyClean }
            needs.cleanliness = CareConfig.cleanTo
        case .cuddle:
            needs.happiness += CareConfig.cuddleGain
        }
        // Kẹp lại qua subscript (≤ 100).
        for k in NeedKind.allCases { needs[k] = needs[k] }

        let (xp, coins, note) = reward(kind, before: before, day: day, history: history)
        let record = CareActionRecord(
            id: actionID, kind: kind, day: day, performedAt: now, foodID: food?.id,
            before: Int(before.rounded()), after: Int(needs[kind.need].rounded()), xp: xp, coins: coins, note: note
        )
        var entry: LedgerEntry?
        let key = LedgerKeys.care(actionID)
        if record.isRewarded, !existingKeys.contains(key) {
            entry = LedgerEntry(id: UUID(), key: key, kind: .care, xp: xp, coins: coins, createdAt: now,
                                refID: actionID.uuidString.lowercased(), memo: kind.label)
        }
        return CareOutcome(needs: needs, record: record, ledger: entry)
    }

    static func reward(_ kind: CareActionKind, before: Double, day: DayKey, history: [CareActionRecord]) -> (Int, Int, CareRewardNote) {
        if kind == .freeMeal { return (0, 0, .freeMeal) }
        guard before < CareConfig.needsCareBelow else { return (0, 0, .notNeeded) }
        let today = history.filter { $0.day == day && $0.isRewarded }
        if today.filter({ $0.kind == kind }).count >= CareConfig.rewardedPerKindPerDay { return (0, 0, .kindLimit) }
        let xpLeft = max(0, CareConfig.dailyXPCap - today.reduce(0) { $0 + $1.xp })
        let coinsLeft = max(0, CareConfig.dailyCoinCap - today.reduce(0) { $0 + $1.coins })
        let base = kind.baseReward
        let xp = min(base.xp, xpLeft), coins = min(base.coins, coinsLeft)
        if xp == 0 && coins == 0 { return (0, 0, .dailyLimit) }
        return (xp, coins, .rewarded)
    }

    /// Tóm tắt thưởng chăm sóc đã nhận trong ngày.
    static func todayTotals(day: DayKey, history: [CareActionRecord]) -> (xp: Int, coins: Int) {
        let today = history.filter { $0.day == day }
        return (today.reduce(0) { $0 + $1.xp }, today.reduce(0) { $0 + $1.coins })
    }
}

/// Mua đồ ăn: mỗi giao dịch có mã riêng (`food-purchase:<transactionID>`).
enum FoodShopPolicy {
    static func purchase(foodID: String, quantity: Int, transactionID: UUID, coins: Int, stock: Int,
                         existingKeys: Set<String>, now: Date) throws -> LedgerEntry? {
        guard let food = FoodCatalog.item(foodID) else { throw CareError.unknownFood }
        guard (1...FoodCatalog.maxPerPurchase).contains(quantity) else { throw CareError.invalidQuantity }
        let key = LedgerKeys.foodPurchase(transactionID)
        // Giao dịch này đã được ghi (thử lại sau lỗi tạm thời): không trừ xu lần hai.
        if existingKeys.contains(key) { return nil }
        guard stock + quantity <= FoodCatalog.maxStock else { throw CareError.stockFull }
        let cost = food.price * quantity
        guard cost <= coins else { throw CareError.notEnoughCoins(needed: cost, have: coins) }
        return LedgerEntry(id: UUID(), key: key, kind: .foodPurchase, xp: 0, coins: -cost, createdAt: now,
                           refID: foodID, memo: "\(food.name) ×\(quantity)")
    }
}

/// Số lượng một món trong khay.
struct FoodStockRecord: Codable, Equatable {
    var foodID: String
    var count: Int
}

/// Hồ sơ chăm sóc dùng chung cho thú cưng (đổi loài/ngoại hình không ảnh hưởng).
struct PetCareRecord: Codable, Equatable {
    var needs: PetNeeds
    /// Đã tặng gói đồ ăn chào mừng (chỉ một lần).
    var welcomeGranted: Bool
    var createdAt: Date
}

// MARK: Dọn nhà & nựng

enum CleanPlan {
    /// Số đốm bụi vẽ trong phòng theo mức sạch (không che kín đồ đạc).
    static func visibleDust(cleanliness: Double) -> Int {
        if cleanliness >= CareConfig.goodFrom { return 0 }
        if cleanliness >= CareConfig.needsCareBelow { return 2 }
        return cleanliness < 27 ? 6 : 4
    }

    /// Số đốm cần dọn trong chế độ dọn nhà (5–8).
    static func spotCount(cleanliness: Double) -> Int {
        cleanliness < CareConfig.needsCareBelow ? 7 : 5
    }

    /// Vị trí đốm bụi (tỉ lệ 0…1 của căn phòng), cố định theo `seed`, nằm ở vùng sàn và chân tường.
    static func spots(count: Int, seed: UInt64) -> [(x: Double, y: Double, kind: Int)] {
        var rng = SeededRandom(seed: seed)
        var result: [(x: Double, y: Double, kind: Int)] = []
        var attempts = 0
        while result.count < count && attempts < 200 {
            attempts += 1
            let x = Double.random(in: 0.08...0.92, using: &rng)
            let y = Double.random(in: 0.66...0.93, using: &rng)
            // Không chồng lên nhau để dễ chạm.
            if result.contains(where: { abs($0.x - x) < 0.11 && abs($0.y - y) < 0.09 }) { continue }
            result.append((x, y, Int.random(in: 0..<3, using: &rng)))
        }
        return result
    }
}

/// Tiến độ một lượt nựng: chỉ cộng thời gian giữa các lần vuốt liên tiếp (tối đa 0,25 giây mỗi lần),
/// nên đặt tay rồi để yên không làm tăng tiến độ.
struct CuddleProgress: Equatable {
    private(set) var seconds: Double = 0
    private var lastEvent: TimeInterval?

    var fraction: Double { min(1, seconds / CareConfig.cuddleSeconds) }
    var isComplete: Bool { seconds >= CareConfig.cuddleSeconds }

    /// Ghi một lần vuốt tại thời điểm `t` (giây, đồng hồ đơn điệu). Trả về true nếu vừa hoàn thành.
    @discardableResult
    mutating func stroke(at t: TimeInterval) -> Bool {
        let wasComplete = isComplete
        if let last = lastEvent, t > last {
            seconds += min(t - last, CareConfig.cuddleMaxGap)
        }
        lastEvent = t
        return !wasComplete && isComplete
    }

    mutating func reset() { self = CuddleProgress() }
}

/// Lời thoại về nhu cầu — nhẹ nhàng, không trách móc vì bạn vắng mặt. Chỉ nói một nhu cầu nổi bật nhất.
enum CareDialogue {
    static func line(for need: NeedKind?, petName: String, seed: Int) -> String {
        let lines: [String]
        switch need {
        case .fullness?:
            lines = ["Bụng mình kêu ọc ọc rồi… mình ăn chút gì nhé?", "Mình hơi đói, có món gì ngon không ta?",
                     "Một quả táo giòn thì tuyệt lắm đó!"]
        case .cleanliness?:
            lines = ["Mình cùng dọn một chút nhé?", "Có vài chiếc lá rơi vào nhà rồi, mình dọn cùng nha!",
                     "Nhà gọn gàng thì ngủ ngon hơn đó."]
        case .happiness?:
            lines = ["Mình hơi buồn chán… nựng mình một chút được không?", "Vuốt nhẹ lưng mình đi, mình thích lắm!",
                     "Chơi với mình một chút nha?"]
        case nil:
            lines = ["\(petName) đang thấy dễ chịu lắm!", "Cảm ơn bạn đã chăm mình!", "Bụng no, nhà sạch, vui ghê!",
                     "Mình ổn cả, bạn cứ làm việc của bạn nha."]
        }
        return lines[abs(seed) % lines.count]
    }

    /// Câu sau khi chăm xong.
    static func done(_ kind: CareActionKind, petName: String, alreadyFine: Bool) -> String {
        switch kind {
        case .feed: return alreadyFine ? "\(petName) ăn thêm cho vui miệng!" : "\(petName) ăn ngon lành!"
        case .freeMeal: return "\(petName) đã no bụng hơn rồi."
        case .clean: return "Nhà sạch bong rồi!"
        case .cuddle: return alreadyFine ? "\(petName) đang vui rồi, nhưng vẫn thích được nựng!" : "\(petName) vui hẳn lên!"
        }
    }

    /// Ghi chú về thưởng (chỉ hiển thị sau khi đã lưu thành công).
    static func rewardNote(_ record: CareActionRecord) -> String {
        switch record.note {
        case .rewarded:
            var parts: [String] = []
            if record.xp > 0 { parts.append("+\(record.xp) XP") }
            if record.coins > 0 { parts.append("+\(record.coins) xu") }
            return parts.joined(separator: " · ")
        case .notNeeded: return "Chăm thêm khi đang ổn thì không có thưởng."
        case .freeMeal: return "Bữa cơ bản miễn phí, không tính thưởng."
        case .kindLimit: return "Hôm nay đã nhận đủ thưởng cho việc này."
        case .dailyLimit: return "Hôm nay đã nhận đủ thưởng chăm sóc."
        }
    }
}
