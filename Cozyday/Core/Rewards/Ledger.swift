import Foundation

enum LedgerKind: String, Codable, CaseIterable {
    case taskCompleted
    case focusCompleted
    case journalWritten
    case purchase
    case adventure
    case breathing
    /// Thưởng xu từ minigame ở Sân chơi (không có XP).
    case minigame
    /// Thưởng nhỏ khi chăm thú cưng đúng lúc cần.
    case care
    /// Mua đồ ăn (vật phẩm tiêu hao, mua lặp lại được).
    case foodPurchase
    /// Một lượt quay máy gacha (trừ xu; món trùng được hoàn một phần xu).
    case gacha
    /// Xu tặng qua mã quà (Cài đặt).
    case gift
    /// Thưởng bộ nhiệm vụ ngày và rương tuần.
    case quest
    /// Quà mốc cấp (nhận một lần mỗi mốc).
    case levelReward
    /// Thưởng huy hiệu (nhận một lần mỗi huy hiệu).
    case badge
    /// Thưởng nhiệm vụ sự kiện lễ.
    case event
    /// Dòng đánh dấu của hệ thống (đã chạy migration, cấp tối thiểu giữ từ bản cũ…). Luôn 0 xu, 0 XP, 0 vé.
    case system
    /// Dữ liệu thử nghiệm của chủ dự án (mã phuhotdz): xu/vé thử, cờ bật chế độ. Không phải phần thưởng thật.
    case tester

    var label: String {
        switch self {
        case .taskCompleted: return "Hoàn thành việc"
        case .focusCompleted: return "Phiên tập trung"
        case .journalWritten: return "Viết nhật ký"
        case .purchase: return "Mua đồ"
        case .adventure: return "Chuyến phiêu lưu"
        case .breathing: return "Bài thở"
        case .minigame: return "Sân chơi"
        case .care: return "Chăm thú cưng"
        case .foodPurchase: return "Mua đồ ăn"
        case .gacha: return "Máy gacha"
        case .gift: return "Quà tặng"
        case .quest: return "Nhiệm vụ"
        case .levelReward: return "Quà mốc cấp"
        case .badge: return "Huy hiệu"
        case .event: return "Sự kiện"
        case .system: return "Hệ thống"
        case .tester: return "Dữ liệu thử nghiệm"
        }
    }

    /// Dòng không hiện trong lịch sử thưởng (dấu hệ thống).
    var isHidden: Bool { self == .system }

    /// Dòng chi tiêu (xu âm, không có XP).
    var isSpending: Bool {
        switch self {
        case .purchase, .foodPurchase, .gacha: return true
        default: return false
        }
    }
}

/// Một dòng sổ cái thưởng/chi. Số dư xu và XP luôn = tổng các dòng — không lưu số dư riêng,
/// nên không thể lệch giữa "tiền" và "lịch sử".
struct LedgerEntry: Codable, Equatable, Identifiable {
    var id: UUID
    /// Khóa ngữ nghĩa duy nhất, ví dụ "task:<occurrenceID>", "purchase:<itemID>".
    var key: String
    var kind: LedgerKind
    var xp: Int
    var coins: Int
    var createdAt: Date
    var refID: String?
    var memo: String
    /// Vé máy gacha (+ nhận, − dùng). Dữ liệu trước lược đồ V4 / sao lưu bản 2 không có trường này → 0.
    var tickets: Int = 0

    init(id: UUID, key: String, kind: LedgerKind, xp: Int, coins: Int, createdAt: Date, refID: String?, memo: String,
         tickets: Int = 0) {
        self.id = id
        self.key = key
        self.kind = kind
        self.xp = xp
        self.coins = coins
        self.createdAt = createdAt
        self.refID = refID
        self.memo = memo
        self.tickets = tickets
    }

    private enum CodingKeys: String, CodingKey { case id, key, kind, xp, coins, createdAt, refID, memo, tickets }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        key = try c.decode(String.self, forKey: .key)
        kind = try c.decode(LedgerKind.self, forKey: .kind)
        xp = try c.decode(Int.self, forKey: .xp)
        coins = try c.decode(Int.self, forKey: .coins)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        refID = try c.decodeIfPresent(String.self, forKey: .refID)
        memo = try c.decode(String.self, forKey: .memo)
        tickets = try c.decodeIfPresent(Int.self, forKey: .tickets) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(key, forKey: .key)
        try c.encode(kind, forKey: .kind)
        try c.encode(xp, forKey: .xp)
        try c.encode(coins, forKey: .coins)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(refID, forKey: .refID)
        try c.encode(memo, forKey: .memo)
        if tickets != 0 { try c.encode(tickets, forKey: .tickets) }
    }
}

enum LedgerKeys {
    static func task(_ occurrenceID: UUID) -> String { "task:\(occurrenceID.uuidString.lowercased())" }
    static func focus(_ sessionID: UUID) -> String { "focus:\(sessionID.uuidString.lowercased())" }
    static func journal(_ day: DayKey) -> String { "journal:\(day.string)" }
    static func purchase(_ itemID: String) -> String { "purchase:\(itemID)" }
    static func adventure(_ day: DayKey) -> String { "adventure:\(day.string)" }
    static func breathing(_ day: DayKey) -> String { "breathing:\(day.string)" }
    static func minigame(_ sessionID: UUID) -> String { "minigame:\(sessionID.uuidString.lowercased())" }
    static func care(_ actionID: UUID) -> String { "care:\(actionID.uuidString.lowercased())" }
    /// Mã t3ster dùng MỘT khóa cố định: mỗi bộ dữ liệu chỉ nhận một lần (kể cả bản bù cho người đã đổi bản cũ).
    static let giftT3ster = "gift:t3ster"
    /// Đã chạy migration dữ liệu kinh tế phiên 9 (cấp tối thiểu, bù t3ster).
    static let migrationEcon2 = "system:migration:econ2"
    /// Cấp tối thiểu giữ từ công thức cấp cũ (memo = số cấp).
    static let levelFloor = "system:level-floor"
    /// Cờ "Dữ liệu thử nghiệm" (mã phuhotdz). Xóa dòng này = tắt chế độ.
    static let testerMode = "system:tester-mode"
    static func tester(_ id: UUID) -> String { "tester:\(id.uuidString.lowercased())" }
    static func questDay(_ day: DayKey) -> String { "quest:\(day.string)" }
    static func weeklyChest(_ weekStart: DayKey) -> String { "chest:\(weekStart.string)" }
    static func levelMilestone(_ level: Int) -> String { "level:\(level)" }
    static func badge(_ id: String) -> String { "badge:\(id)" }
    static func event(_ eventID: String, _ part: String) -> String { "event:\(eventID):\(part)" }
    /// Mỗi lần mua đồ ăn có mã giao dịch riêng — khác `purchase:<itemID>` của đồ sở hữu vĩnh viễn.
    static func foodPurchase(_ transactionID: UUID) -> String { "food-purchase:\(transactionID.uuidString.lowercased())" }
    static func gacha(_ pullID: UUID) -> String { "gacha:\(pullID.uuidString.lowercased())" }
    static func gift(_ id: UUID) -> String { "gift:\(id.uuidString.lowercased())" }
}

struct Wallet: Equatable {
    var xp: Int
    var coins: Int
    var tickets: Int
    /// Cấp tối thiểu giữ từ công thức cấp cũ (người đã ở cấp cao trước khi đổi đường XP không bị tụt cấp).
    var levelFloor: Int
    /// Chế độ thử nghiệm (mã phuhotdz): hiển thị và mở khóa như cấp tối đa, không ghi XP thật.
    var testerMode: Bool

    init(xp: Int = 0, coins: Int = 0, tickets: Int = 0, levelFloor: Int = 1, testerMode: Bool = false) {
        self.xp = xp
        self.coins = coins
        self.tickets = tickets
        self.levelFloor = levelFloor
        self.testerMode = testerMode
    }

    init<S: Sequence>(entries: S) where S.Element == LedgerEntry {
        var xp = 0, coins = 0, tickets = 0, floor = 1, tester = false
        for e in entries {
            xp += e.xp
            coins += e.coins
            tickets += e.tickets
            if e.key == LedgerKeys.levelFloor, let n = Int(e.memo) { floor = max(floor, n) }
            if e.key == LedgerKeys.testerMode { tester = true }
        }
        self.init(xp: xp, coins: coins, tickets: tickets, levelFloor: floor, testerMode: tester)
    }

    /// Cấp thật (không tính chế độ thử nghiệm): theo đường XP, không thấp hơn cấp đã giữ từ bản cũ.
    // Old releases had no cap. Honor a saved legacy level above 30; new progression stops at 30.
    var realLevel: Int { max(LevelCurve.level(forXP: xp), levelFloor) }
    /// Cấp dùng để mở khóa và hiển thị.
    var level: Int { testerMode ? LevelCurve.maxLevel : realLevel }
    var isMaxLevel: Bool { level >= LevelCurve.maxLevel }
    /// XP cần để từ cấp hiện tại lên cấp kế (0 khi đã tối đa).
    var xpForNextLevel: Int { isMaxLevel ? 0 : LevelCurve.cost(from: level) }
    /// XP còn thiếu để lên cấp kế.
    var xpToNextLevel: Int { isMaxLevel ? 0 : max(0, LevelCurve.threshold(level + 1) - max(0, xp)) }
    /// XP đã tích trong cấp hiện tại (khi đang giữ cấp cũ cao hơn đường XP: tính từ 0 đến khi bắt kịp).
    var xpIntoLevel: Int { isMaxLevel ? 0 : max(0, xpForNextLevel - xpToNextLevel) }
    var levelProgress: Double { isMaxLevel ? 1 : Double(xpIntoLevel) / Double(max(1, xpForNextLevel)) }
}

/// Quyết định thưởng — thuần, không đụng lưu trữ. Trả về nil nếu khóa đã có (chống nhận 2 lần).
enum RewardPolicy {
    /// `rewardedToday`: số việc đã có thưởng trong ngày hoàn thành. Hết hạn mức → vẫn ghi một dòng 0 XP/0 xu
    /// (giữ khóa, để tick lại hay xóa rồi tạo lại cũng không có thưởng) và đánh dấu `memo` để giao diện báo.
    static func forTaskCompletion(occurrence: TaskOccurrenceRecord, existingKeys: Set<String>, rewardedToday: Int = 0,
                                  now: Date) -> LedgerEntry? {
        let key = LedgerKeys.task(occurrence.id)
        guard !existingKeys.contains(key) else { return nil }
        let capped = rewardedToday >= RewardConfig.taskRewardsPerDay
        return LedgerEntry(
            id: UUID(), key: key, kind: .taskCompleted,
            xp: capped ? 0 : RewardConfig.taskXP, coins: capped ? 0 : RewardConfig.taskCoins,
            createdAt: now, refID: occurrence.id.uuidString.lowercased(), memo: capped ? taskCapMemo + occurrence.title : occurrence.title
        )
    }

    /// Tiền tố ghi chú của dòng việc xong khi đã hết hạn mức thưởng trong ngày.
    static let taskCapMemo = "Hết hạn mức: "

    /// Số việc đã có thưởng trong cùng ngày với `now`.
    static func taskRewardsToday<S: Sequence>(_ ledger: S, now: Date, calendar: Calendar) -> Int where S.Element == LedgerEntry {
        ledger.reduce(0) { n, e in
            e.kind == .taskCompleted && e.xp > 0 && calendar.isDate(e.createdAt, inSameDayAs: now) ? n + 1 : n
        }
    }

    /// Tiền tố ghi chú khi phiên tập trung vượt quá số phút có thưởng trong ngày.
    static let focusCapMemo = "Đã đủ giờ có thưởng: "

    /// Số phút tập trung đã có thưởng trong cùng ngày với `now`.
    static func focusRewardedMinutesToday<S: Sequence>(_ ledger: S, now: Date, calendar: Calendar) -> Int where S.Element == LedgerEntry {
        ledger.reduce(0) { n, e in
            e.kind == .focusCompleted && calendar.isDate(e.createdAt, inSameDayAs: now)
                ? n + e.xp / RewardConfig.focusXPPerFiveMinutes * 5 : n
        }
    }

    /// Thưởng một phiên tập trung chạy hết giờ. Đã đủ giờ có thưởng trong ngày thì chỉ thưởng phần còn lại;
    /// hết hẳn thì vẫn ghi một dòng 0 xu để màn hình báo rõ lý do.
    static func forFocus(sessionID: UUID, plannedMinutes: Int, existingKeys: Set<String>, now: Date,
                         rewardedMinutesToday: Int = 0) -> LedgerEntry? {
        let key = LedgerKeys.focus(sessionID)
        let full = RewardConfig.focusReward(plannedMinutes: plannedMinutes)
        guard !existingKeys.contains(key), full.xp > 0 || full.coins > 0 else { return nil }
        let eligible = min(plannedMinutes, RewardConfig.focusMaxRewardMinutes)
        let left = max(0, RewardConfig.focusDailyRewardMinutes - rewardedMinutesToday)
        let blocks = min(eligible, left) / 5
        let capped = blocks * 5 < eligible
        return LedgerEntry(
            id: UUID(), key: key, kind: .focusCompleted,
            xp: blocks * RewardConfig.focusXPPerFiveMinutes, coins: blocks * RewardConfig.focusCoinsPerFiveMinutes,
            createdAt: now, refID: sessionID.uuidString.lowercased(),
            memo: (capped ? focusCapMemo : "") + "\(plannedMinutes) phút"
        )
    }

    static func forBreathing(day: DayKey, existingKeys: Set<String>, now: Date) -> LedgerEntry? {
        let key = LedgerKeys.breathing(day)
        guard !existingKeys.contains(key) else { return nil }
        return LedgerEntry(
            id: UUID(), key: key, kind: .breathing,
            xp: RewardConfig.breathingXP, coins: RewardConfig.breathingCoins,
            createdAt: now, refID: day.string, memo: day.string
        )
    }

    /// Nhật ký có thưởng khi viết cho hôm nay hoặc hôm qua (`today`). Ngày cũ hơn hay ngày tương lai: không thưởng.
    static func forJournal(day: DayKey, today: DayKey, calendar: Calendar, existingKeys: Set<String>, now: Date) -> LedgerEntry? {
        let back = day.days(to: today, calendar: calendar)
        guard (0...RewardConfig.journalRewardDaysBack).contains(back) else { return nil }
        let key = LedgerKeys.journal(day)
        guard !existingKeys.contains(key) else { return nil }
        return LedgerEntry(
            id: UUID(), key: key, kind: .journalWritten,
            xp: RewardConfig.journalXP, coins: RewardConfig.journalCoins,
            createdAt: now, refID: day.string, memo: day.string
        )
    }
}
