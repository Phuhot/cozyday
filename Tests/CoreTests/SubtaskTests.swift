import XCTest
#if canImport(CozyCore)
@testable import CozyCore
#else
@testable import Cozyday
#endif

final class SubtaskTests: XCTestCase {
    func testNormalizeTrimsDropsEmptyAndCaps() {
        let raw = [Subtask(title: "  Mua sữa "), Subtask(title: "   "), Subtask(title: String(repeating: "a", count: 300))]
            + (0..<30).map { Subtask(title: "Việc \($0)") }
        let n = Subtasks.normalized(raw)
        XCTAssertEqual(n.first?.title, "Mua sữa")
        XCTAssertEqual(n.count, Subtasks.maxCount)
        XCTAssertEqual(n[1].title.count, Subtasks.maxTitleLength)
    }

    func testValidationRejectsTooMany() {
        var d = TaskDraft()
        d.title = "Dọn nhà"
        d.subtasks = (0..<25).map { Subtask(title: "Phòng \($0)") }
        XCTAssertEqual(TaskValidation.validate(d), .tooManySubtasks(max: Subtasks.maxCount))
        d.subtasks = (0..<5).map { Subtask(title: "Phòng \($0)") } + [Subtask(title: " ")]
        XCTAssertNil(TaskValidation.validate(d))
    }

    func testRecurringOccurrencesGetFreshChecklistAndFutureEditKeepsDoneState() {
        var draft = TaskDraft()
        draft.title = "Tập thể dục"
        draft.day = day("2026-10-12")
        draft.startMinute = 7 * 60
        draft.repeatFrequency = .daily
        draft.subtasks = [Subtask(title: "Khởi động", isDone: true), Subtask(title: "Chạy 2 km")]
        let template = OccurrenceFactory.makeTemplate(from: draft, startDay: day("2026-10-12"), now: Date())!
        XCTAssertEqual(template.checklist.map(\.isDone), [false, false], "mẫu luôn bắt đầu chưa làm")

        var occ = OccurrenceFactory.make(from: template, day: day("2026-10-13"), now: Date())
        XCTAssertEqual(occ.checklist.map(\.title), ["Khởi động", "Chạy 2 km"])
        occ.checklist[0].isDone = true

        // Sửa mẫu: thêm một mục, giữ trạng thái đã làm của mục cũ
        var edited = template
        edited.checklist.append(Subtask(title: "Giãn cơ"))
        occ.apply(template: edited, now: Date())
        XCTAssertEqual(occ.checklist.map(\.isDone), [true, false, false])
        XCTAssertEqual(occ.checklist.count, 3)
    }

    func testJSONRoundTripAndCorruptStringIsEmpty() {
        let list = [Subtask(title: "A"), Subtask(title: "B", isDone: true)]
        XCTAssertEqual(Subtasks.decode(Subtasks.encode(list)), list)
        XCTAssertEqual(Subtasks.encode([]), "")
        XCTAssertEqual(Subtasks.decode("{hỏng"), [])
        XCTAssertEqual(Subtasks.progressLabel(list), "1/2")
        XCTAssertNil(Subtasks.progressLabel([]))
    }

    func testOldBackupWithoutSubtasksStillDecodes() throws {
        var doc = BackupTests.sampleDocument()
        doc.occurrences[0].checklist = [Subtask(title: "Mục 1")]
        let data = try BackupCodec.encode(doc)
        XCTAssertEqual(try BackupCodec.decodeAndValidate(data).occurrences[0].checklist.map(\.title), ["Mục 1"])

        // Bản sao lưu từ phiên bản trước không có khóa "subtasks"
        var json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        var occs = try XCTUnwrap(json["occurrences"] as? [[String: Any]])
        for i in occs.indices { occs[i].removeValue(forKey: "subtasks") }
        json["occurrences"] = occs
        let old = try JSONSerialization.data(withJSONObject: json)
        XCTAssertEqual(try BackupCodec.decodeAndValidate(old).occurrences[0].checklist, [])
    }
}
