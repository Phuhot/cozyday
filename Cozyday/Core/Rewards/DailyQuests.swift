import Foundation

// Nhiệm vụ ngày + rương tuần. Thuần logic: hoạt động trong ngày do AppStore tổng hợp từ dữ liệu sẵn có
// (việc xong, phiên tập trung, chăm sóc, Sân chơi, nhật ký, bài thở). Không có bảng dữ liệu riêng:
// phần thưởng là dòng sổ cái có khóa cố định (`quest:<ngày>`, `chest:<thứ Hai của tuần>`) nên không nhận được hai lần.

enum QuestKind: String, Codable, CaseIterable {
    case tasks, focus, care, minigame, journal, breathing
}

struct DailyQuest: Equatable, Identifiable {
    let kind: QuestKind
    let target: Int
    var id: String { kind.rawValue }

    var title: String {
        switch kind {
        case .tasks: return "Hoàn thành \(target) việc"
        case .focus: return "Tập trung \(target) phút"
        case .care: return "Chăm thú cưng \(target) lần"
        case .minigame: return "Chơi trọn \(target) lượt ở Sân chơi"
        case .journal: return "Viết vài dòng nhật ký"
        case .breathing: return "Làm một bài thở"
        }
    }

    var hint: String {
        switch kind {
        case .tasks: return "Việc nào cũng tính, kể cả việc nhỏ."
        case .focus: return "Một phiên chạy hết giờ (từ 10 phút) là được tính."
        case .care: return "Cho ăn, dọn nhà hoặc nựng."
        case .minigame: return "Lượt chơi xong (không thoát giữa chừng)."
        case .journal: return "Chọn tâm trạng là đủ."
        case .breathing: return "Chạy hết bài thở."
        }
    }

    var symbol: String {
        switch kind {
        case .tasks: return "checklist"
        case .focus: return "timer"
        case .care: return "heart.fill"
        case .minigame: return "gamecontroller.fill"
        case .journal: return "book.fill"
        case .breathing: return "wind"
        }
    }
}

/// Hoạt động của một ngày (đếm từ dữ liệu đã lưu).
struct DayActivity: Equatable {
    var tasksDone = 0
    var focusMinutes = 0
    var careActions = 0
    var minigameRuns = 0
    var journalWritten = false
    var breathingDone = false

    func progress(_ q: DailyQuest) -> Int {
        let value: Int
        switch q.kind {
        case .tasks: value = tasksDone
        case .focus: value = focusMinutes
        case .care: value = careActions
        case .minigame: value = minigameRuns
        case .journal: value = journalWritten ? 1 : 0
        case .breathing: value = breathingDone ? 1 : 0
        }
        return min(q.target, value)
    }

    func isDone(_ q: DailyQuest) -> Bool { progress(q) >= q.target }
}

enum DailyQuests {
    /// Thưởng khi xong CẢ BA mục tiêu (tổng, không phải mỗi mục).
    static let setRewardCoins = 15

    /// Ba mục tiêu của ngày: một mục kế hoạch (việc hoặc tập trung), một mục chăm thú cưng,
    /// một mục thư giãn (Sân chơi, nhật ký hoặc bài thở). Cố định theo ngày: mở lại app không đổi đề.
    /// Ba mục thuộc ba nhóm khác nhau, nên lặp một thao tác không thể xong cả bộ.
    static func quests(for day: DayKey) -> [DailyQuest] {
        let seed = stableHash(day.string)
        let planner: DailyQuest = seed % 3 == 0 ? DailyQuest(kind: .focus, target: 25) : DailyQuest(kind: .tasks, target: 2)
        let pet = DailyQuest(kind: .care, target: 2)
        let relax: [DailyQuest] = [DailyQuest(kind: .minigame, target: 1), DailyQuest(kind: .journal, target: 1),
                                   DailyQuest(kind: .breathing, target: 1)]
        return [planner, pet, relax[(seed / 3) % relax.count]]
    }

    static func allDone(_ quests: [DailyQuest], _ a: DayActivity) -> Bool { quests.allSatisfy(a.isDone) }

    /// Nhận thưởng bộ nhiệm vụ của `day`. Cho nhận ngày hôm nay hoặc hôm qua (xong lúc 23:59 bấm sau nửa đêm vẫn được).
    static func claimEntry(day: DayKey, today: DayKey, calendar: Calendar, activity: DayActivity,
                           existingKeys: Set<String>, now: Date) -> LedgerEntry? {
        let back = day.days(to: today, calendar: calendar)
        guard (0...1).contains(back), allDone(quests(for: day), activity) else { return nil }
        let key = LedgerKeys.questDay(day)
        guard !existingKeys.contains(key) else { return nil }
        return LedgerEntry(id: UUID(), key: key, kind: .quest, xp: 0, coins: setRewardCoins, createdAt: now,
                           refID: day.string, memo: "Nhiệm vụ ngày \(day.string)")
    }

    /// Băm ổn định (không dùng Hasher vì Hasher đổi hạt giống mỗi lần chạy app).
    static func stableHash(_ s: String) -> Int {
        var h: UInt64 = 1469598103934665603
        for b in s.utf8 {
            h ^= UInt64(b)
            h = h &* 1099511628211
        }
        return Int(h % 1_000_003)
    }
}

/// Rương tuần: xong bộ nhiệm vụ ngày ở 4 ngày khác nhau trong cùng một tuần (không cần liên tiếp).
/// Tuần tính từ thứ Hai đến Chủ nhật theo NGÀY của bộ nhiệm vụ (ngày lưu trong dòng thưởng), nên đổi múi giờ
/// sau đó không làm một ngày đã xong chuyển sang tuần khác. Nhận tối đa một rương mỗi tuần (khóa `chest:<thứ Hai>`).
enum WeeklyChest {
    static let requiredDays = 4
    static let coins = 40
    static let tickets = 1

    /// Thứ Hai của tuần chứa `day`.
    static func weekStart(of day: DayKey, calendar: Calendar) -> DayKey {
        var c = calendar
        c.firstWeekday = 2
        let date = day.date(atMinute: 12 * 60, in: c)
        let weekday = c.component(.weekday, from: date) // 1 = Chủ nhật … 7 = thứ Bảy
        let offset = (weekday + 5) % 7                     // thứ Hai → 0, Chủ nhật → 6
        return day.adding(days: -offset, calendar: c)
    }

    /// Những ngày trong tuần `weekStart` đã nhận thưởng bộ nhiệm vụ.
    static func completedDays<S: Sequence>(weekStart: DayKey, ledger: S, calendar: Calendar) -> Set<DayKey>
    where S.Element == LedgerEntry {
        var days = Set<DayKey>()
        for e in ledger where e.kind == .quest && e.key.hasPrefix("quest:") {
            guard let raw = e.refID, let d = DayKey(string: raw) else { continue }
            if Self.weekStart(of: d, calendar: calendar) == weekStart { days.insert(d) }
        }
        return days
    }

    /// Nhận rương của tuần `weekStart`: được nhận trong tuần đó hoặc tuần kế (lỡ tay sang thứ Hai vẫn nhận được).
    static func claimEntry<S: Sequence>(weekStart: DayKey, today: DayKey, calendar: Calendar, ledger: S,
                                        existingKeys: Set<String>, now: Date) -> LedgerEntry? where S.Element == LedgerEntry {
        let current = Self.weekStart(of: today, calendar: calendar)
        let gap = weekStart.days(to: current, calendar: calendar)
        guard gap == 0 || gap == 7 else { return nil }
        guard completedDays(weekStart: weekStart, ledger: ledger, calendar: calendar).count >= requiredDays else { return nil }
        let key = LedgerKeys.weeklyChest(weekStart)
        guard !existingKeys.contains(key) else { return nil }
        return LedgerEntry(id: UUID(), key: key, kind: .quest, xp: 0, coins: coins, createdAt: now,
                           refID: weekStart.string, memo: "Rương tuần từ \(weekStart.string)", tickets: tickets)
    }
}
