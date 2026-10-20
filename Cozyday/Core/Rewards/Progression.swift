import Foundation

/// Đường XP lên cấp (tối đa cấp 30). Cấp 1–10 giữ đúng 100 XP/cấp như bản cũ (người dùng cũ dưới cấp 10
/// không thấy thay đổi), sau đó mỗi 5 cấp cần thêm 50 XP cho một cấp.
///
/// | Cấp | XP mỗi cấp | XP tích lũy để đạt cấp cuối nhóm |
/// |---|---|---|
/// | 1 → 10 | 100 | 900 |
/// | 10 → 15 | 150 | 1.650 |
/// | 15 → 20 | 200 | 2.650 |
/// | 20 → 25 | 250 | 3.900 |
/// | 25 → 30 | 300 | 5.400 |
enum LevelCurve {
    static let maxLevel = 30

    /// XP để đi từ `level` lên `level + 1`.
    static func cost(from level: Int) -> Int {
        switch level {
        case ..<10: return 100
        case 10..<15: return 150
        case 15..<20: return 200
        case 20..<25: return 250
        default: return 300
        }
    }

    /// Tổng XP cần để đạt `level` (cấp 1 = 0 XP).
    static func threshold(_ level: Int) -> Int {
        guard level > 1 else { return 0 }
        return (1..<min(level, maxLevel)).reduce(0) { $0 + cost(from: $1) }
    }

    /// Cấp theo XP (1…30).
    static func level(forXP xp: Int) -> Int {
        var level = 1
        var need = 0
        while level < maxLevel {
            need += cost(from: level)
            guard xp >= need else { break }
            level += 1
        }
        return level
    }

    /// Công thức của bản trước phiên 9 (100 XP mỗi cấp, không giới hạn) — chỉ dùng cho migration.
    static func legacyLevel(forXP xp: Int) -> Int { max(0, xp) / 100 + 1 }
}

/// Quà mốc cấp trong phần cấp mới (11–30). Nhận bằng tay, mỗi mốc một lần (khóa `level:<n>`).
/// Mốc nhỏ cho xu + vé; ba mốc 15, 21, 30 kèm mở khóa đồ cấp cao trong cửa hàng.
struct LevelMilestone: Equatable, Identifiable {
    let level: Int
    let coins: Int
    let tickets: Int
    /// Mô tả phần mở khóa đi kèm (đồ có requiredLevel = level), nil nếu chỉ có xu/vé.
    let unlock: String?
    var id: Int { level }
}

enum LevelMilestones {
    static let all: [LevelMilestone] = [
        LevelMilestone(level: 12, coins: 40, tickets: 1, unlock: nil),
        LevelMilestone(level: 15, coins: 50, tickets: 1, unlock: "Mở bán đồ cấp 15"),
        LevelMilestone(level: 18, coins: 60, tickets: 1, unlock: nil),
        LevelMilestone(level: 21, coins: 70, tickets: 2, unlock: "Mở bán đồ cấp 21"),
        LevelMilestone(level: 24, coins: 80, tickets: 2, unlock: nil),
        LevelMilestone(level: 27, coins: 90, tickets: 2, unlock: nil),
        LevelMilestone(level: 30, coins: 150, tickets: 3, unlock: "Mở bán đồ cấp 30")
    ]

    static func milestone(_ level: Int) -> LevelMilestone? { all.first { $0.level == level } }

    static var maxCoins: Int { all.map(\.coins).max() ?? 0 }
    static var maxTickets: Int { all.map(\.tickets).max() ?? 0 }

    /// Mốc đã đạt (theo cấp thật) mà chưa nhận.
    static func claimable(realLevel: Int, existingKeys: Set<String>) -> [LevelMilestone] {
        all.filter { $0.level <= realLevel && !existingKeys.contains(LedgerKeys.levelMilestone($0.level)) }
    }

    static func entry(_ m: LevelMilestone, realLevel: Int, existingKeys: Set<String>, now: Date) -> LedgerEntry? {
        let key = LedgerKeys.levelMilestone(m.level)
        guard realLevel >= m.level, !existingKeys.contains(key) else { return nil }
        return LedgerEntry(id: UUID(), key: key, kind: .levelReward, xp: 0, coins: m.coins, createdAt: now,
                           refID: String(m.level), memo: "Quà cấp \(m.level)", tickets: m.tickets)
    }
}
