import Foundation
import XCTest
#if canImport(CozyCore)
@testable import CozyCore
#else
@testable import Cozyday
#endif

final class PomodoroTests: XCTestCase {
    func testSettingsNormalizeAndOldDataStillDecodes() {
        var s = PomodoroSettings()
        s.focusMinutes = 3
        s.longBreakMinutes = 47
        s.roundsBeforeLongBreak = 99
        s.ambientVolume = .nan
        let n = s.normalized()
        XCTAssertEqual(n.focusMinutes, 5)
        XCTAssertEqual(n.longBreakMinutes, 30)
        XCTAssertEqual(n.roundsBeforeLongBreak, 6)
        XCTAssertEqual(n.ambientVolume, 0.5)

        // Bản lưu cũ chỉ có vài trường → các trường còn lại lấy mặc định.
        let old = Data(#"{"focusMinutes": 50, "strictMode": true}"#.utf8)
        let decoded = PomodoroSettings.decode(old)
        XCTAssertEqual(decoded.focusMinutes, 50)
        XCTAssertTrue(decoded.strictMode)
        XCTAssertEqual(decoded.shortBreakMinutes, 5)
        XCTAssertEqual(decoded.ambient, .off)
        XCTAssertEqual(PomodoroSettings.decode(Data("rác".utf8)), PomodoroSettings())
        XCTAssertEqual(PomodoroSettings.decode(n.encoded()), n)
    }

    func testCycleGivesLongBreakEveryNRounds() {
        var s = PomodoroSettings()
        s.roundsBeforeLongBreak = 4
        s.shortBreakMinutes = 5
        s.longBreakMinutes = 20
        let afterThird = PomodoroPlan.next(after: .focus, completedFocusToday: 3, settings: s)
        XCTAssertEqual(afterThird, .init(kind: .rest, minutes: 5, isLongBreak: false))
        let afterFourth = PomodoroPlan.next(after: .focus, completedFocusToday: 4, settings: s)
        XCTAssertEqual(afterFourth, .init(kind: .rest, minutes: 20, isLongBreak: true))
        let afterRest = PomodoroPlan.next(after: .rest, completedFocusToday: 4, settings: s)
        XCTAssertEqual(afterRest, .init(kind: .focus, minutes: s.focusMinutes, isLongBreak: false))
    }

    func testAutoStartOnlyRightAfterTheEndAndPerSetting() {
        var s = PomodoroSettings()
        s.autoStartBreak = true
        s.autoStartFocus = false
        let end = date(2026, 10, 20, 9)
        let rest = PomodoroPlan.Next(kind: .rest, minutes: 5, isLongBreak: false)
        let focus = PomodoroPlan.Next(kind: .focus, minutes: 25, isLongBreak: false)
        XCTAssertTrue(PomodoroPlan.shouldAutoStart(rest, endedAt: end, now: end.addingTimeInterval(2), settings: s))
        XCTAssertFalse(PomodoroPlan.shouldAutoStart(rest, endedAt: end, now: end.addingTimeInterval(40 * 60), settings: s),
                       "mở app sau 40 phút thì không tự bật giờ nghỉ")
        XCTAssertFalse(PomodoroPlan.shouldAutoStart(focus, endedAt: end, now: end, settings: s))
    }

    func testDayCountsOnlyCompletedFocusOfThatDay() {
        let c = cal()
        var s = PomodoroSettings()
        s.roundsBeforeLongBreak = 4
        s.dailyGoal = 2
        func session(_ kind: FocusKind, start: Date, minutes: Int, early: Bool = false) -> FocusSessionRecord {
            var r = FocusSessionRecord.start(kind: kind, minutes: minutes, occurrenceID: nil, now: start)
            if early { r.endEarly(at: start.addingTimeInterval(Double(minutes) * 30)) }
            else { r.reconcile(at: start.addingTimeInterval(Double(minutes) * 60)) }
            return r
        }
        let sessions = [
            session(.focus, start: date(2026, 10, 19, 21), minutes: 25),   // hôm qua
            session(.focus, start: date(2026, 10, 20, 8), minutes: 25),
            session(.rest, start: date(2026, 10, 20, 8, 25), minutes: 5),
            session(.focus, start: date(2026, 10, 20, 9), minutes: 20, early: true),
            session(.focus, start: date(2026, 10, 20, 10), minutes: 50),
            FocusSessionRecord.start(kind: .focus, minutes: 25, occurrenceID: nil, now: date(2026, 10, 20, 11)) // đang chạy
        ]
        let d = PomodoroDay.compute(sessions: sessions, day: day("2026-10-20"), calendar: c, settings: s)
        XCTAssertEqual(d.completedFocus, 2)
        XCTAssertEqual(d.focusedMinutes, 25 + 10 + 50)
        XCTAssertEqual(d.roundInCycle, 2)
        XCTAssertTrue(d.goalReached)
    }

    func testAwayTrackerIgnoresLockAndShortPeeks() {
        let t0 = date(2026, 10, 20, 9)
        var t = FocusAwayTracker()

        t.didLeave(at: t0)
        XCTAssertEqual(t.didReturn(at: t0.addingTimeInterval(5), focusRunning: true, strict: false), .ignored, "liếc 5 giây")

        t.didLeave(at: t0)
        XCTAssertEqual(t.didReturn(at: t0.addingTimeInterval(30), focusRunning: true, strict: false), .counted(seconds: 30))

        // Tín hiệu khóa máy tới ngay trước lúc app vào nền vẫn được tính là khóa máy.
        t.deviceLocked(at: t0.addingTimeInterval(-1))
        t.didLeave(at: t0)
        XCTAssertEqual(t.didReturn(at: t0.addingTimeInterval(600), focusRunning: true, strict: true), .ignored)

        // Lần khóa máy cũ không che lần rời app sau đó.
        t.deviceLocked(at: t0)
        t.didLeave(at: t0.addingTimeInterval(120))
        XCTAssertEqual(t.didReturn(at: t0.addingTimeInterval(300), focusRunning: true, strict: true), .broke(seconds: 180))

        t.didLeave(at: t0)
        XCTAssertEqual(t.didReturn(at: t0.addingTimeInterval(300), focusRunning: false, strict: true), .ignored, "đang nghỉ/tạm dừng")
        XCTAssertNil(t.leftAt)
    }

    func testStrictBreakEndsAtTheLimitWithoutReward() {
        let start = date(2026, 10, 20, 9)
        var s = FocusSessionRecord.start(kind: .focus, minutes: 25, occurrenceID: nil, now: start)
        // Rời app ở phút 10, quá giới hạn ở phút 11; mở lại ở phút 40 (đã quá giờ kết thúc).
        s.endEarly(at: start.addingTimeInterval(11 * 60))
        XCTAssertEqual(s.status, .endedEarly)
        XCTAssertEqual(Int(s.focusedSeconds), 11 * 60)
        XCTAssertFalse(s.isRewardEligible)
    }
}
