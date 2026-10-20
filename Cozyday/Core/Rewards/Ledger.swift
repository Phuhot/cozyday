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
        }
    }

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
    /// Mỗi lần mua đồ ăn có mã giao dịch riêng — khác `purchase:<itemID>` của đồ sở hữu vĩnh viễn.
    static func foodPurchase(_ transactionID: UUID) -> String { "food-purchase:\(transactionID.uuidString.lowercased())" }
    static func gacha(_ pullID: UUID) -> String { "gacha:\(pullID.uuidString.lowercased())" }
    static func gift(_ id: UUID) -> String { "gift:\(id.uuidString.lowercased())" }
}

struct Wallet: Equatable {
    var xp: Int
    var coins: Int

    init(xp: Int = 0, coins: Int = 0) {
        self.xp = xp
        self.coins = coins
    }

    init<S: Sequence>(entries: S) where S.Element == LedgerEntry {
        var xp = 0, coins = 0
        for e in entries {
            xp += e.xp
            coins += e.coins
        }
        self.init(xp: xp, coins: coins)
    }

    var level: Int { max(0, xp) / RewardConfig.xpPerLevel + 1 }
    var xpIntoLevel: Int { max(0, xp) % RewardConfig.xpPerLevel }
    var levelProgress: Double { Double(xpIntoLevel) / Double(RewardConfig.xpPerLevel) }
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

    static func forFocus(sessionID: UUID, plannedMinutes: Int, existingKeys: Set<String>, now: Date) -> LedgerEntry? {
        let key = LedgerKeys.focus(sessionID)
        let reward = RewardConfig.focusReward(plannedMinutes: plannedMinutes)
        guard !existingKeys.contains(key), reward.xp > 0 || reward.coins > 0 else { return nil }
        return LedgerEntry(
            id: UUID(), key: key, kind: .focusCompleted,
            xp: reward.xp, coins: reward.coins,
            createdAt: now, refID: sessionID.uuidString.lowercased(), memo: "\(plannedMinutes) phút"
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

    static func forJournal(day: DayKey, existingKeys: Set<String>, now: Date) -> LedgerEntry? {
        let key = LedgerKeys.journal(day)
        guard !existingKeys.contains(key) else { return nil }
        return LedgerEntry(
            id: UUID(), key: key, kind: .journalWritten,
            xp: RewardConfig.journalXP, coins: RewardConfig.journalCoins,
            createdAt: now, refID: day.string, memo: day.string
        )
    }
}
