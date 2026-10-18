import XCTest
#if canImport(CozyCore)
@testable import CozyCore
#else
@testable import Cozyday
#endif

final class TaskRulesTests: XCTestCase {
    func testValidationRejectsMidnightCrossing() {
        var draft = TaskDraft()
        draft.title = "Thức khuya"
        draft.day = day("2026-10-18")
        draft.startMinute = 23 * 60 + 30
        draft.durationMinutes = 60
        XCTAssertEqual(TaskValidation.validate(draft), .crossesMidnight(endMinute: 30))
        draft.durationMinutes = 30
        XCTAssertNil(TaskValidation.validate(draft))
    }

    func testValidationRules() {
        var draft = TaskDraft()
        XCTAssertEqual(TaskValidation.validate(draft), .emptyTitle)
        draft.title = "  Học  "
        draft.durationMinutes = 0
        XCTAssertEqual(TaskValidation.validate(draft), .invalidDuration(min: 5, max: 720))
        draft.durationMinutes = 30
        draft.repeatFrequency = .weekly
        XCTAssertEqual(TaskValidation.validate(draft), .repeatNeedsDay)
        draft.day = day("2026-10-18")
        XCTAssertEqual(TaskValidation.validate(draft), .weeklyWithoutWeekdays)
        draft.repeatWeekdays = [2]
        draft.repeatEndDay = day("2026-10-01")
        XCTAssertEqual(TaskValidation.validate(draft), .endBeforeStart)
    }

    func testEditThisAndFutureDoesNotTouchPast() {
        let c = cal()
        let template = makeTemplate(startDay: day("2026-10-12"))
        let days = day("2026-10-12").through(day("2026-10-25"), calendar: c)
        var occs = OccurrenceFactory.missing(templates: [template], existingKeys: [], days: days, calendar: c, now: Date())
        // Đã hoàn thành ngày 14 (quá khứ) và ngày 22 (tương lai)
        for i in occs.indices where ["2026-10-14", "2026-10-22"].contains(occs[i].day!.string) {
            occs[i].status = .done
            occs[i].completedAt = Date()
        }
        var draft = TaskDraft(occurrence: occs[0], template: template)
        draft.title = "Đọc sách (mới)"
        draft.startMinute = 20 * 60
        let changes = RecurringEdit.editThisAndFuture(
            template: template, from: day("2026-10-18"), draft: draft,
            occurrences: occs, calendar: c, now: Date()
        )
        XCTAssertEqual(changes.upsertTemplates.count, 2)
        let old = changes.upsertTemplates.first { $0.id == template.id }!
        let fresh = changes.upsertTemplates.first { $0.id != template.id }!
        XCTAssertEqual(old.recurrence.endDay, day("2026-10-17"))
        XCTAssertEqual(old.title, "Đọc sách")
        XCTAssertEqual(fresh.recurrence.startDay, day("2026-10-18"))
        XCTAssertEqual(fresh.title, "Đọc sách (mới)")

        // Không occurrence nào trước ngày 18 bị đổi
        let changedIDs = Set(changes.upsertOccurrences.map(\.id))
        for o in occs where o.day! < day("2026-10-18") {
            XCTAssertFalse(changedIDs.contains(o.id))
        }
        // Lần chưa làm từ 18 trở đi có nội dung mới; lần đã xong ngày 22 giữ nội dung cũ
        for o in changes.upsertOccurrences {
            XCTAssertEqual(o.templateID, fresh.id)
            if o.day == day("2026-10-22") {
                XCTAssertEqual(o.title, "Đọc sách")
                XCTAssertEqual(o.status, .done)
            } else {
                XCTAssertEqual(o.title, "Đọc sách (mới)")
                XCTAssertEqual(o.startMinute, 20 * 60)
            }
        }
        // Khóa mới không trùng và generator không tạo lại
        let afterKeys = Set(occs.filter { $0.day! < day("2026-10-18") }.map(\.occurrenceKey))
            .union(changes.upsertOccurrences.map(\.occurrenceKey))
        let regenerated = OccurrenceFactory.missing(
            templates: changes.upsertTemplates, existingKeys: afterKeys, days: days, calendar: c, now: Date()
        )
        XCTAssertTrue(regenerated.isEmpty)
    }

    func testDeleteThisAndFutureKeepsCompletedHistory() {
        let c = cal()
        let template = makeTemplate(startDay: day("2026-10-12"))
        let days = day("2026-10-12").through(day("2026-10-20"), calendar: c)
        var occs = OccurrenceFactory.missing(templates: [template], existingKeys: [], days: days, calendar: c, now: Date())
        let doneIndex = occs.firstIndex { $0.day == day("2026-10-19") }!
        occs[doneIndex].status = .done
        occs[doneIndex].completedAt = Date()
        let changes = RecurringEdit.deleteThisAndFuture(template: template, from: day("2026-10-18"), occurrences: occs, calendar: c)
        XCTAssertEqual(changes.upsertTemplates.first?.recurrence.endDay, day("2026-10-17"))
        XCTAssertEqual(changes.deleteOccurrenceIDs.count, 2) // 18 và 20; 19 đã xong được giữ
        XCTAssertFalse(changes.deleteOccurrenceIDs.contains(occs[doneIndex].id))
    }

    func testMovedOccurrenceKeepsOriginalKey() {
        let template = makeTemplate()
        var occ = OccurrenceFactory.make(from: template, day: day("2026-10-18"), now: Date())
        occ.day = day("2026-10-19")
        occ.isDetached = true
        XCTAssertEqual(RecurringEdit.originalDay(of: occ), day("2026-10-18"))
        let regenerated = OccurrenceFactory.missing(
            templates: [template], existingKeys: [occ.occurrenceKey], days: [day("2026-10-18")], calendar: cal(), now: Date()
        )
        XCTAssertTrue(regenerated.isEmpty)
    }

    func testTimelineLayoutNeverOverlapsVisually() {
        let a = TimelineLayout.Item(id: UUID(), start: 480, duration: 60)
        let b = TimelineLayout.Item(id: UUID(), start: 500, duration: 30)
        let c = TimelineLayout.Item(id: UUID(), start: 600, duration: 5) // quá ngắn → kéo dài
        let d = TimelineLayout.Item(id: UUID(), start: 610, duration: 30) // không trùng giờ thật với c
        let placements = TimelineLayout.layout([a, b, c, d], minDisplayMinutes: 25)
        let byID = Dictionary(uniqueKeysWithValues: placements.map { ($0.id, $0) })
        XCTAssertNotEqual(byID[a.id]!.lane, byID[b.id]!.lane)
        XCTAssertEqual(byID[a.id]!.laneCount, 2)
        XCTAssertTrue(byID[a.id]!.overlapsRealTime)
        XCTAssertTrue(byID[c.id]!.isStretched)
        XCTAssertFalse(byID[c.id]!.overlapsRealTime)
        XCTAssertFalse(byID[d.id]!.overlapsRealTime)
        // c kéo dài tới 625 nên d (610) phải sang cột khác để không đè chữ
        XCTAssertNotEqual(byID[c.id]!.lane, byID[d.id]!.lane)
        // Không cặp nào cùng cột mà giao nhau về hiển thị
        for p in placements {
            for q in placements where p.id != q.id && p.lane == q.lane {
                XCTAssertFalse(p.displayStart < q.displayEnd && q.displayStart < p.displayEnd)
            }
        }
    }
}
