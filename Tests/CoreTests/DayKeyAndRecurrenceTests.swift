import XCTest
#if canImport(CozyCore)
@testable import CozyCore
#else
@testable import Cozyday
#endif

final class DayKeyAndRecurrenceTests: XCTestCase {
    func testDayKeyUsesLocalCalendarNotUTC() {
        // 23:30 ngày 18/10 ở TP.HCM = 16:30 UTC cùng ngày; 06:30 ngày 19/10 ở HCM = 23:30 UTC ngày 18.
        let morning = date(2026, 10, 19, 6, 30)
        XCTAssertEqual(DayKey(morning, calendar: cal()), day("2026-10-19"))
        XCTAssertEqual(DayKey(morning, calendar: cal(TimeZone(identifier: "UTC")!)), day("2026-10-18"))
    }

    func testParsingRejectsInvalidDates() {
        XCTAssertNil(DayKey(string: "2026-02-30"))
        XCTAssertNil(DayKey(string: "2026-13-01"))
        XCTAssertNil(DayKey(string: "26-10-18"))
        XCTAssertEqual(DayKey(string: "2028-02-29")?.string, "2028-02-29")
    }

    func testAddingDaysAcrossDSTUsesCalendarDays() {
        // New York đổi giờ ngày 1/11/2026: ngày đó dài 25 giờ.
        let ny = cal(TZ.newYork)
        let d = day("2026-10-31")
        XCTAssertEqual(d.adding(days: 1, calendar: ny), day("2026-11-01"))
        XCTAssertEqual(d.adding(days: 2, calendar: ny), day("2026-11-02"))
        // 08:00 giờ địa phương vẫn là 08:00 sau ngày đổi giờ.
        let eight = day("2026-11-02").date(atMinute: 8 * 60, in: ny)
        XCTAssertEqual(ny.minuteOfDay(eight), 8 * 60)
    }

    func testWeeklyRecurrence() {
        // 2026-10-19 là Thứ hai (weekday 2).
        let rule = RecurrenceRule(frequency: .weekly, weekdays: [2, 4, 6], startDay: day("2026-10-19"))
        let days = rule.days(from: day("2026-10-18"), through: day("2026-10-25"), calendar: cal())
        XCTAssertEqual(days.map(\.string), ["2026-10-19", "2026-10-21", "2026-10-23"])
    }

    func testRecurrenceRespectsEndDay() {
        let rule = RecurrenceRule(frequency: .daily, startDay: day("2026-10-18"), endDay: day("2026-10-20"))
        XCTAssertEqual(rule.days(from: day("2026-10-01"), through: day("2026-10-31"), calendar: cal()).count, 3)
        XCTAssertFalse(rule.occurs(on: day("2026-10-21"), calendar: cal()))
    }

    func testOccurrenceGenerationIsIdempotent() {
        let template = makeTemplate()
        let days = day("2026-10-18").through(day("2026-10-20"), calendar: cal())
        let first = OccurrenceFactory.missing(templates: [template], existingKeys: [], days: days, calendar: cal(), now: Date())
        XCTAssertEqual(first.count, 3)
        // "Mở lại app": khóa đã có → không tạo thêm.
        let keys = Set(first.map(\.occurrenceKey))
        let second = OccurrenceFactory.missing(templates: [template], existingKeys: keys, days: days, calendar: cal(), now: Date())
        XCTAssertTrue(second.isEmpty)
        XCTAssertEqual(Set(first.map(\.occurrenceKey)).count, 3)
    }

    func testTimezoneChangeKeepsWallClockTime() {
        let template = makeTemplate(start: 8 * 60)
        let occ = OccurrenceFactory.make(from: template, day: day("2026-10-20"), now: Date())
        let inHCM = occ.day!.date(atMinute: occ.startMinute!, in: cal(TZ.hcm))
        let inTokyo = occ.day!.date(atMinute: occ.startMinute!, in: cal(TZ.tokyo))
        XCTAssertEqual(cal(TZ.hcm).minuteOfDay(inHCM), 480)
        XCTAssertEqual(cal(TZ.tokyo).minuteOfDay(inTokyo), 480)
        XCTAssertNotEqual(inHCM, inTokyo) // thời điểm tuyệt đối khác nhau, giờ đồng hồ như nhau
    }
}
