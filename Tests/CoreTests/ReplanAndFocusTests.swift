import XCTest
#if canImport(CozyCore)
@testable import CozyCore
#else
@testable import Cozyday
#endif

final class ReplanTests: XCTestCase {
    private func task(_ start: Int?, _ duration: Int, fixed: Bool = false, done: Bool = false,
                      priority: TaskPriority = .normal, order: Int = 0) -> Replanner.Task {
        Replanner.Task(id: UUID(), start: start, duration: duration, isFixed: fixed, isFinished: done, priority: priority, order: order)
    }

    func testMovesMissedTasksIntoGapsWithoutOverlap() {
        let missed1 = task(8 * 60, 60, order: 0)
        let missed2 = task(9 * 60, 30, priority: .high, order: 1)
        let done = task(8 * 60 + 30, 30, done: true)
        let fixed = task(10 * 60 + 15, 60, fixed: true)
        let future = task(12 * 60, 30)
        let plan = Replanner.plan(
            tasks: [missed1, missed2, done, fixed, future],
            nowMinute: 10 * 60 + 2, activeStart: 7 * 60, activeEnd: 22 * 60, includeUnscheduled: false
        )
        XCTAssertTrue(plan.unplaced.isEmpty)
        let moved = Dictionary(uniqueKeysWithValues: plan.moves.map { ($0.id, $0.to) })
        XCTAssertNil(moved[done.id])
        XCTAssertNil(moved[fixed.id])
        XCTAssertNil(moved[future.id])
        // Ưu tiên cao xếp trước: missed2 vào 11:15 (sau việc cố định), missed1 tiếp sau
        XCTAssertEqual(moved[missed2.id], 11 * 60 + 15)
        XCTAssertEqual(moved[missed1.id], 12 * 60 + 30)
        // Không chồng lịch
        var intervals: [(Int, Int)] = [(fixed.start!, fixed.start! + 60), (future.start!, future.start! + 30)]
        intervals += [(moved[missed2.id]!, moved[missed2.id]! + 30), (moved[missed1.id]!, moved[missed1.id]! + 60)]
        for i in intervals.indices {
            for j in intervals.indices where i < j {
                XCTAssertFalse(intervals[i].0 < intervals[j].1 && intervals[j].0 < intervals[i].1)
            }
        }
    }

    func testReportsTasksThatDoNotFit() {
        let big = task(8 * 60, 120)
        let small = task(9 * 60, 30)
        let plan = Replanner.plan(tasks: [big, small], nowMinute: 21 * 60, activeStart: 7 * 60, activeEnd: 22 * 60, includeUnscheduled: false)
        XCTAssertEqual(plan.unplaced, [big.id])
        XCTAssertEqual(plan.moves.map(\.id), [small.id])
    }

    func testUnscheduledOnlyWhenRequested() {
        let loose = task(nil, 20)
        XCTAssertTrue(Replanner.plan(tasks: [loose], nowMinute: 600, activeStart: 420, activeEnd: 1320, includeUnscheduled: false).isEmpty)
        let plan = Replanner.plan(tasks: [loose], nowMinute: 600, activeStart: 420, activeEnd: 1320, includeUnscheduled: true)
        XCTAssertEqual(plan.moves.first?.to, 600)
    }
}

final class FocusTimerTests: XCTestCase {
    func testPauseIsNotCounted() {
        let t0 = date(2026, 10, 18, 9)
        var s = FocusSessionRecord.start(kind: .focus, minutes: 25, occurrenceID: nil, now: t0)
        s.pause(at: t0.addingTimeInterval(10 * 60))
        XCTAssertEqual(s.elapsed(at: t0.addingTimeInterval(60 * 60)), 600, accuracy: 0.01)
        s.resume(at: t0.addingTimeInterval(60 * 60))
        XCTAssertEqual(s.remaining(at: t0.addingTimeInterval(65 * 60)), 10 * 60, accuracy: 0.01)
        XCTAssertEqual(s.expectedEnd, t0.addingTimeInterval(75 * 60))
    }

    func testReconcileAfterRelaunchFinishesExactlyOnce() {
        let t0 = date(2026, 10, 18, 9)
        var s = FocusSessionRecord.start(kind: .focus, minutes: 25, occurrenceID: nil, now: t0)
        // App bị đóng; mở lại sau 3 giờ
        let later = t0.addingTimeInterval(3 * 3600)
        XCTAssertTrue(s.reconcile(at: later))
        XCTAssertEqual(s.status, .completed)
        XCTAssertEqual(s.endedAt, t0.addingTimeInterval(25 * 60)) // lúc thực sự hết giờ
        XCTAssertEqual(s.focusedSeconds, 1500, accuracy: 0.01)
        XCTAssertFalse(s.reconcile(at: later.addingTimeInterval(60)))
        XCTAssertTrue(s.isRewardEligible)
    }

    func testEndEarlyHasNoRewardButCountsMinutes() {
        let t0 = date(2026, 10, 18, 9)
        var s = FocusSessionRecord.start(kind: .focus, minutes: 50, occurrenceID: nil, now: t0)
        s.endEarly(at: t0.addingTimeInterval(20 * 60))
        XCTAssertEqual(s.status, .endedEarly)
        XCTAssertEqual(s.focusedSeconds, 1200, accuracy: 0.01)
        XCTAssertFalse(s.isRewardEligible)
    }

    func testEndEarlyAfterTimeUpCountsAsCompleted() {
        let t0 = date(2026, 10, 18, 9)
        var s = FocusSessionRecord.start(kind: .focus, minutes: 25, occurrenceID: nil, now: t0)
        s.endEarly(at: t0.addingTimeInterval(30 * 60))
        XCTAssertEqual(s.status, .completed)
    }

    func testPausedSessionNeverAutoCompletes() {
        let t0 = date(2026, 10, 18, 9)
        var s = FocusSessionRecord.start(kind: .focus, minutes: 25, occurrenceID: nil, now: t0)
        s.pause(at: t0.addingTimeInterval(60))
        XCTAssertFalse(s.reconcile(at: t0.addingTimeInterval(10 * 3600)))
        XCTAssertTrue(s.isPaused)
        XCTAssertNil(s.expectedEnd)
    }

    func testRestSessionHasNoFocusMinutes() {
        let t0 = date(2026, 10, 18, 9)
        var s = FocusSessionRecord.start(kind: .rest, minutes: 5, occurrenceID: nil, now: t0)
        s.reconcile(at: t0.addingTimeInterval(600))
        XCTAssertEqual(s.focusedSeconds, 0)
        XCTAssertFalse(s.isRewardEligible)
    }
}
