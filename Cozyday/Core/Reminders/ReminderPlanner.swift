import Foundation

/// Một thông báo cục bộ cần có. ID ổn định để sửa/xóa task thay/hủy đúng thông báo.
struct ReminderRequest: Equatable {
    var id: String
    var fireDate: Date
    var title: String
    var body: String
    /// Đích khi bấm thông báo: "task:<uuid>" hoặc "focus".
    var route: String
}

enum ReminderIDs {
    static let taskPrefix = "task."
    static let focusEnd = "focus.end"
    static let focusNudge = "focus.nudge"
    static let journalDaily = "journal.daily"

    static func task(_ occurrenceID: UUID) -> String { taskPrefix + occurrenceID.uuidString.lowercased() }
}

enum ReminderPlanner {
    /// iOS chỉ giữ tối đa 64 thông báo chờ cho mỗi app; chừa chỗ cho focus và nhật ký.
    static let systemPendingLimit = 64
    static let taskLimit = 60
    static let horizonDays = 7

    static let offsetChoices: [Int] = [0, 5, 10, 15, 30, 60]

    static func offsetLabel(_ minutes: Int?) -> String {
        guard let minutes else { return "Không nhắc" }
        return minutes == 0 ? "Đúng giờ bắt đầu" : "Trước \(minutes) phút"
    }

    /// Các nhắc việc cần có trong cửa sổ [now, now + horizonDays], sớm nhất trước, tối đa `taskLimit`.
    static func taskReminders(
        occurrences: [TaskOccurrenceRecord],
        now: Date,
        calendar: Calendar,
        horizonDays: Int = horizonDays,
        limit: Int = taskLimit
    ) -> [ReminderRequest] {
        let today = DayKey(now, calendar: calendar)
        let lastDay = today.adding(days: horizonDays, calendar: calendar)
        var result: [ReminderRequest] = []
        for occ in occurrences {
            guard occ.status == .open, !occ.isRemoved,
                  let day = occ.day, day >= today, day <= lastDay,
                  let start = occ.startMinute, let offset = occ.reminderOffsetMinutes else { continue }
            let startDate = day.date(atMinute: start, in: calendar)
            let fire = startDate.addingTimeInterval(TimeInterval(-offset * 60))
            guard fire > now else { continue }
            let body = offset == 0
                ? "Bắt đầu lúc \(TimeOfDay.label(start)) · \(TimeOfDay.durationLabel(occ.durationMinutes))"
                : "Còn \(offset) phút nữa (\(TimeOfDay.label(start)))"
            result.append(ReminderRequest(
                id: ReminderIDs.task(occ.id), fireDate: fire, title: occ.title, body: body,
                route: "task:\(occ.id.uuidString.lowercased())"
            ))
        }
        result.sort { $0.fireDate < $1.fireDate }
        return Array(result.prefix(limit))
    }

    /// So sánh danh sách đang chờ với danh sách mong muốn.
    static func diff(pendingIDs: Set<String>, desired: [ReminderRequest]) -> (remove: [String], add: [ReminderRequest]) {
        let desiredIDs = Set(desired.map(\.id))
        let remove = pendingIDs.filter { $0.hasPrefix(ReminderIDs.taskPrefix) && !desiredIDs.contains($0) }
        return (remove.sorted(), desired)
    }
}
