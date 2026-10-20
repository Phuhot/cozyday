import XCTest
import SwiftData
@testable import Cozyday

/// Test lớp lưu trữ thật (SwiftData trong bộ nhớ) cho các luồng dễ mất dữ liệu / sai tiền.
@MainActor
final class AppStoreTests: XCTestCase {
    private var clock: ManualClock!
    private var calendar: Calendar!

    override func setUp() async throws {
        calendar = Calendar.gregorian(timeZone: TimeZone(identifier: "Asia/Ho_Chi_Minh")!)
        clock = ManualClock(calendar.date(from: DateComponents(year: 2026, month: 10, day: 18, hour: 9))!)
    }

    private func makeStore(_ container: ModelContainer? = nil) throws -> (AppStore, ModelContainer) {
        let c = try container ?? PersistenceController.makeContainer(inMemory: true)
        return (try AppStore(container: c, clock: clock, calendar: calendar), c)
    }

    private func draft(_ title: String, start: Int? = 10 * 60, repeatDaily: Bool = false) -> TaskDraft {
        var d = TaskDraft()
        d.title = title
        d.day = DayKey(clock.now, calendar: calendar)
        d.startMinute = start
        d.durationMinutes = 30
        if repeatDaily { d.repeatFrequency = .daily }
        return d
    }

    func testProfileSeededOnceAndNotResetOnRelaunch() throws {
        let (store, container) = try makeStore()
        try store.updateProfile { $0.petName = "Mochi"; $0.onboardingCompleted = true }
        let (relaunched, _) = try makeStore(container)
        XCTAssertEqual(relaunched.profile.petName, "Mochi")
        XCTAssertTrue(relaunched.profile.onboardingCompleted)
        let profiles = try ModelContext(container).fetch(FetchDescriptor<ProfileModel>())
        XCTAssertEqual(profiles.count, 1)
    }

    func testCompletingTwiceGivesOneReward() throws {
        let (store, container) = try makeStore()
        let id = try XCTUnwrap(store.createTask(draft("Đọc sách")))
        XCTAssertNotNil(try store.setStatus(id: id, to: .done))
        XCTAssertNil(try store.setStatus(id: id, to: .done))
        try store.setStatus(id: id, to: .open)
        XCTAssertNil(try store.setStatus(id: id, to: .done))
        XCTAssertEqual(store.wallet.coins, RewardConfig.taskCoins)

        // Mở lại app: sổ cái vẫn đúng, hoàn thành lại không thưởng thêm
        let (relaunched, _) = try makeStore(container)
        try relaunched.setStatus(id: id, to: .open)
        XCTAssertNil(try relaunched.setStatus(id: id, to: .done))
        XCTAssertEqual(relaunched.wallet.coins, RewardConfig.taskCoins)
        XCTAssertEqual(relaunched.ledger.count, 1)
    }

    func testDeletingTaskKeepsLedgerAndCannotFarm() throws {
        let (store, _) = try makeStore()
        let id = try XCTUnwrap(store.createTask(draft("Việc một lần")))
        try store.setStatus(id: id, to: .done)
        try store.deleteTask(id: id, scope: .thisOnly)
        XCTAssertNil(store.occurrence(id))
        XCTAssertEqual(store.ledger.count, 1)
        XCTAssertEqual(store.wallet.coins, RewardConfig.taskCoins)
    }

    func testPurchaseIsAtomicAndNotDoubleCharged() throws {
        let (store, container) = try makeStore()
        // Kiếm 25 xu
        for i in 0..<5 {
            let id = try XCTUnwrap(store.createTask(draft("Việc \(i)")))
            try store.setStatus(id: id, to: .done)
        }
        XCTAssertEqual(store.wallet.coins, 25)
        XCTAssertThrowsError(try store.buy(itemID: "lamp.desk")) // 45 xu: không đủ
        XCTAssertEqual(store.wallet.coins, 25)

        try store.buy(itemID: "lamp.candle") // 20 xu
        XCTAssertThrowsError(try store.buy(itemID: "lamp.candle")) // bấm lần 2
        XCTAssertEqual(store.wallet.coins, 5)
        XCTAssertEqual(store.ownedIDs, ["lamp.candle"])
        XCTAssertEqual(store.equippedItem(in: .lamp)?.id, "lamp.candle")

        let (relaunched, _) = try makeStore(container)
        XCTAssertEqual(relaunched.wallet.coins, 5)
        XCTAssertEqual(relaunched.ownedIDs, ["lamp.candle"])
    }

    func testRecurringOccurrencesNotDuplicatedAcrossRelaunchAndDayChange() throws {
        let (store, container) = try makeStore()
        try store.createTask(draft("Uống nước", start: 7 * 60, repeatDaily: true))
        try store.ensureUpcomingOccurrences()
        try store.ensureUpcomingOccurrences()
        XCTAssertEqual(store.occurrences.count, 8) // hôm nay + 7 ngày

        clock.advance(seconds: 86_400 * 2) // hai ngày sau (múi giờ HCM không đổi giờ mùa hè)
        let (relaunched, _) = try makeStore(container)
        try relaunched.ensureUpcomingOccurrences()
        XCTAssertEqual(relaunched.occurrences.count, 10)
        XCTAssertEqual(Set(relaunched.occurrences.map(\.occurrenceKey)).count, 10)
    }

    func testEditFutureDoesNotChangeCompletedPast() throws {
        let (store, _) = try makeStore()
        try store.createTask(draft("Chạy bộ", start: 6 * 60, repeatDaily: true))
        let today = store.today
        let first = try XCTUnwrap(store.tasks(on: today).first)
        try store.setStatus(id: first.id, to: .done)

        clock.advance(seconds: 86_400)
        try store.ensureUpcomingOccurrences()
        let tomorrowTask = try XCTUnwrap(store.tasks(on: store.today).first)
        var d = TaskDraft(occurrence: tomorrowTask, template: store.template(tomorrowTask.templateID))
        d.title = "Chạy bộ 20 phút"
        try store.updateTask(id: tomorrowTask.id, draft: d, scope: .thisAndFuture)

        XCTAssertEqual(store.tasks(on: today).first?.title, "Chạy bộ")
        XCTAssertEqual(store.tasks(on: today).first?.status, .done)
        XCTAssertEqual(store.tasks(on: store.today).first?.title, "Chạy bộ 20 phút")
        XCTAssertEqual(store.tasks(on: store.today.adding(days: 3, calendar: calendar)).first?.title, "Chạy bộ 20 phút")
        XCTAssertEqual(store.tasks(on: store.today).count, 1)
    }

    func testFocusRewardOnceAfterRelaunch() throws {
        let (store, container) = try makeStore()
        try store.startFocus(kind: .focus, minutes: 25, occurrenceID: nil)
        clock.advance(seconds: 3 * 3600) // app bị đóng, mở lại sau 3 giờ
        let (relaunched, _) = try makeStore(container)
        XCTAssertNotNil(try relaunched.reconcileFocus())
        XCTAssertNil(try relaunched.reconcileFocus())
        XCTAssertNil(relaunched.activeFocus)
        XCTAssertEqual(relaunched.focusSessions.first?.status, .completed)
        XCTAssertEqual(relaunched.wallet.coins, RewardConfig.focusReward(plannedMinutes: 25).coins)
    }

    func testBackupRoundTripAndRestoreReplacesEverything() throws {
        let (store, _) = try makeStore()
        try store.updateProfile { $0.petName = "Mochi"; $0.onboardingCompleted = true }
        let id = try XCTUnwrap(store.createTask(draft("Học")))
        try store.setStatus(id: id, to: .done)
        try store.buy(itemID: "desk.pine")
        try store.saveJournal(day: store.today, mood: .good, note: "ổn")
        let data = try BackupCodec.encode(store.makeBackup())

        let (other, _) = try makeStore()
        try other.createTask(draft("Dữ liệu cũ sẽ bị thay"))
        let doc = try BackupCodec.decodeAndValidate(data)
        try other.restore(doc)

        XCTAssertEqual(other.profile.petName, "Mochi")
        XCTAssertEqual(other.wallet, store.wallet)
        XCTAssertEqual(other.ownedIDs, ["desk.pine"])
        XCTAssertEqual(other.equippedItem(in: .desk)?.id, "desk.pine")
        XCTAssertEqual(other.journal.count, 1)
        XCTAssertEqual(other.occurrences.map(\.title), ["Học"])
        // Không nhận thưởng lại sau khôi phục
        try other.setStatus(id: id, to: .open)
        XCTAssertNil(try other.setStatus(id: id, to: .done))
    }

    func testInvalidBackupDoesNotTouchExistingData() throws {
        let (store, _) = try makeStore()
        try store.createTask(draft("Giữ nguyên"))
        var doc = store.makeBackup()
        doc.schemaVersion = 99
        let data = try BackupCodec.encode(doc)
        XCTAssertThrowsError(try BackupCodec.decodeAndValidate(data))
        var broken = store.makeBackup()
        broken.equipped = [EquippedRecord(slot: .desk, itemID: "desk.sage")] // chưa sở hữu
        XCTAssertThrowsError(try store.restore(broken))
        XCTAssertEqual(store.occurrences.map(\.title), ["Giữ nguyên"])
    }

    func testMidnightCrossingRejected() throws {
        let (store, _) = try makeStore()
        var d = draft("Thức khuya", start: 23 * 60 + 45)
        d.durationMinutes = 30
        XCTAssertThrowsError(try store.createTask(d))
        XCTAssertTrue(store.occurrences.isEmpty)
    }
}

@MainActor
final class AppStoreRecurringConversionTests: XCTestCase {
    func testOneOffBecomesRecurringKeepingReward() throws {
        let calendar = Calendar.gregorian(timeZone: TimeZone(identifier: "Asia/Ho_Chi_Minh")!)
        let clock = ManualClock(calendar.date(from: DateComponents(year: 2026, month: 10, day: 18, hour: 9))!)
        let store = try AppStore(container: PersistenceController.makeContainer(inMemory: true), clock: clock, calendar: calendar)
        var d = TaskDraft()
        d.title = "Thiền"
        d.day = store.today
        d.startMinute = 6 * 60
        let id = try XCTUnwrap(store.createTask(d))
        XCTAssertNotNil(try store.setStatus(id: id, to: .done))

        d.repeatFrequency = .daily
        try store.updateTask(id: id, draft: d, scope: .thisOnly)
        let converted = try XCTUnwrap(store.occurrence(id))
        XCTAssertNotNil(converted.templateID)
        XCTAssertEqual(converted.status, .done)
        XCTAssertEqual(store.tasks(on: store.today).count, 1)
        XCTAssertEqual(store.tasks(on: store.today.adding(days: 1, calendar: calendar)).count, 1)
        // Không nhận lại thưởng
        try store.setStatus(id: id, to: .open)
        XCTAssertNil(try store.setStatus(id: id, to: .done))

        // Tắt lặp từ ngày mai: ngày mai thành việc một lần, các ngày sau biến mất
        let tomorrow = try XCTUnwrap(store.tasks(on: store.today.adding(days: 1, calendar: calendar)).first)
        var stop = TaskDraft(occurrence: tomorrow, template: store.template(tomorrow.templateID))
        stop.repeatFrequency = nil
        try store.updateTask(id: tomorrow.id, draft: stop, scope: .thisAndFuture)
        XCTAssertNil(store.occurrence(tomorrow.id)?.templateID)
        XCTAssertTrue(store.tasks(on: store.today.adding(days: 2, calendar: calendar)).isEmpty)
        XCTAssertEqual(store.tasks(on: store.today).first?.status, .done)
        try store.ensureUpcomingOccurrences()
        XCTAssertTrue(store.tasks(on: store.today.adding(days: 3, calendar: calendar)).isEmpty)
    }
}
