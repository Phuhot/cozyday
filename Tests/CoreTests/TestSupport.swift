import Foundation
import XCTest
#if canImport(CozyCore)
@testable import CozyCore
#else
@testable import Cozyday
#endif

enum TZ {
    static let hcm = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
    static let newYork = TimeZone(identifier: "America/New_York")!
    static let tokyo = TimeZone(identifier: "Asia/Tokyo")!
}

func cal(_ tz: TimeZone = TZ.hcm) -> Calendar { Calendar.gregorian(timeZone: tz) }

func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0, _ s: Int = 0, tz: TimeZone = TZ.hcm) -> Date {
    cal(tz).date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min, second: s))!
}

func day(_ s: String) -> DayKey { DayKey(string: s)! }

func makeTemplate(
    title: String = "Đọc sách",
    start: Int? = 8 * 60,
    duration: Int = 30,
    frequency: RecurrenceFrequency = .daily,
    weekdays: [Int] = [],
    startDay: DayKey = day("2026-10-12"),
    endDay: DayKey? = nil
) -> TaskTemplateRecord {
    TaskTemplateRecord(
        id: UUID(), title: title, notes: "", category: .study, priority: .normal,
        startMinute: start, durationMinutes: duration, isFixed: false, reminderOffsetMinutes: 10,
        recurrence: RecurrenceRule(frequency: frequency, weekdays: weekdays, startDay: startDay, endDay: endDay),
        createdAt: date(2026, 10, 1)
    )
}

func makeOneOff(
    title: String = "Việc",
    day d: DayKey? = day("2026-10-18"),
    start: Int? = 9 * 60,
    duration: Int = 30,
    status: TaskStatus = .open,
    fixed: Bool = false,
    priority: TaskPriority = .normal
) -> TaskOccurrenceRecord {
    var draft = TaskDraft()
    draft.title = title
    draft.day = d
    draft.startMinute = start
    draft.durationMinutes = duration
    draft.isFixed = fixed
    draft.priority = priority
    var o = OccurrenceFactory.makeOneOff(from: draft, now: date(2026, 10, 18, 6))
    o.status = status
    if status == .done { o.completedAt = date(2026, 10, 18, 10) }
    return o
}
