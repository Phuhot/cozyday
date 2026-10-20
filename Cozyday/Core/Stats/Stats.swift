import Foundation

struct DayStat: Equatable, Identifiable {
    var day: DayKey
    var completedTasks: Int
    var focusMinutes: Int
    var hasJournal: Bool

    var id: String { day.string }
    var isActive: Bool { completedTasks > 0 || focusMinutes > 0 || hasJournal }
}

struct StatsSummary: Equatable {
    var completedTasks: Int
    var focusMinutes: Int
    var activeDays: Int
    var days: [DayStat]
}

/// Thống kê chỉ từ dữ liệu thật. Việc "đã hoàn thành" phản ánh trạng thái hiện tại của task.
enum StatsCalculator {
    static func summary(
        days: [DayKey],
        occurrences: [TaskOccurrenceRecord],
        focusSessions: [FocusSessionRecord],
        journal: [JournalRecord],
        calendar: Calendar
    ) -> StatsSummary {
        let daySet = Set(days)
        var completed: [DayKey: Int] = [:]
        for o in occurrences where o.status == .done && !o.isRemoved {
            guard let day = o.day ?? o.completedAt.map({ DayKey($0, calendar: calendar) }), daySet.contains(day) else { continue }
            completed[day, default: 0] += 1
        }
        var focusSeconds: [DayKey: Double] = [:]
        for s in focusSessions where s.kind == .focus && s.status != .active {
            let day = DayKey(s.startedAt, calendar: calendar)
            guard daySet.contains(day) else { continue }
            focusSeconds[day, default: 0] += s.focusedSeconds
        }
        let journalDays = Set(journal.map(\.day))

        let stats = days.map { day in
            DayStat(
                day: day,
                completedTasks: completed[day] ?? 0,
                focusMinutes: Int((focusSeconds[day] ?? 0) / 60),
                hasJournal: journalDays.contains(day)
            )
        }
        return StatsSummary(
            completedTasks: stats.reduce(0) { $0 + $1.completedTasks },
            focusMinutes: stats.reduce(0) { $0 + $1.focusMinutes },
            activeDays: stats.filter(\.isActive).count,
            days: stats
        )
    }

    /// Chuỗi ngày có hoạt động liên tiếp tính đến hôm nay (hôm nay chưa có hoạt động thì tính đến hôm qua).
    /// Chỉ để động viên — không có hình phạt khi chuỗi bị ngắt.
    static func currentStreak(activeDays: Set<DayKey>, today: DayKey, calendar: Calendar) -> Int {
        var cursor = activeDays.contains(today) ? today : today.adding(days: -1, calendar: calendar)
        var count = 0
        while activeDays.contains(cursor) {
            count += 1
            cursor = cursor.adding(days: -1, calendar: calendar)
            if count > 3660 { break }
        }
        return count
    }
}
