import XCTest
import SwiftData
@testable import Cozyday

/// Phiên 9 ở tầng lưu trữ: migration V3 → V4, bù t3ster đúng một lần, mã quà bấm hai lần, Dữ liệu thử nghiệm,
/// nhiệm vụ ngày / rương tuần / quà mốc không nhận hai lần, kết quả gacha chưa xem, sao lưu giữ các dấu.
@MainActor
final class ProgressStoreTests: XCTestCase {
    private var clock: ManualClock!
    private var calendar: Calendar!
    private let suite = "ProgressStoreTests"
    private var defaults: UserDefaults!

    override func setUp() async throws {
        calendar = Calendar.gregorian(timeZone: TimeZone(identifier: "Asia/Ho_Chi_Minh")!)
        clock = ManualClock(calendar.date(from: DateComponents(year: 2026, month: 11, day: 3, hour: 9))!)
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suite)
    }

    private func makeStore(_ container: ModelContainer? = nil) throws -> (AppStore, ModelContainer) {
        let c = try container ?? PersistenceController.makeContainer(inMemory: true)
        return (try AppStore(container: c, clock: clock, calendar: calendar, defaults: defaults), c)
    }

    private func legacyGift(_ context: ModelContext) {
        let e = CozySchemaV3.LedgerEntryModel(id: UUID())
        e.key = "gift:\(UUID().uuidString.lowercased())"
        e.kindRaw = "gift"
        e.coins = 1000
        e.memo = "Mã quà"
        context.insert(e)
    }

    // MARK: Migration

    func testV3StoreOpensWithV4KeepsDataKeepsLevelAndTopsUpT3sterOnce() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("cozy-v4-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("Cozyday.store")

        do {
            let v3 = Schema(versionedSchema: CozySchemaV3.self)
            let container = try ModelContainer(for: v3, configurations: [ModelConfiguration(schema: v3, url: url, cloudKitDatabase: .none)])
            let context = ModelContext(container)
            context.insert(CozySchemaV3.ProfileModel(
                userName: "An", petName: "Bông", goalsRaw: "", activeStartMinute: 420, activeEndMinute: 1320,
                hapticsEnabled: true, journalReminderEnabled: false, journalReminderMinute: 1260,
                onboardingCompleted: true, createdAt: Date(), dataVersion: 2
            ))
            let xp = CozySchemaV3.LedgerEntryModel(id: UUID())
            xp.key = "task:old"
            xp.kindRaw = "taskCompleted"
            xp.xp = 1900 // công thức cũ: cấp 20
            xp.coins = 300
            context.insert(xp)
            legacyGift(context) // đã đổi t3ster một lần ở bản cũ (1.000 xu)
            context.insert(CozySchemaV3.OwnedItemModel(itemID: "hat.beanie", acquiredAt: Date(), transactionID: nil))
            context.insert(CozySchemaV3.EquippedSlotModel(slotRaw: "hat", itemID: "hat.beanie"))
            try context.save()
        }

        let container = try PersistenceController.makeContainer(url: url)
        let (store, _) = try makeStore(container)
        XCTAssertEqual(store.profile.petName, "Bông")
        XCTAssertEqual(store.equippedMap[.hat], "hat.beanie")
        XCTAssertEqual(store.wallet.xp, 1900)
        XCTAssertEqual(store.wallet.tickets, 0)
        XCTAssertEqual(store.wallet.level, 20, "không tụt cấp so với bản cũ")
        XCTAssertEqual(store.wallet.coins, 300 + 1000 + 9000, "bù đúng 9.000 xu")
        XCTAssertThrowsError(try store.redeemGiftCode("t3ster"), "đã nhận đủ quyền lợi của mã")

        // Mở lại: không bù lần hai.
        let (again, _) = try makeStore(container)
        XCTAssertEqual(again.wallet.coins, 300 + 1000 + 9000)
        XCTAssertEqual(again.ledger.filter { $0.key == LedgerKeys.giftT3ster }.count, 1)
        XCTAssertEqual(again.ledger.filter { $0.key == LedgerKeys.migrationEcon2 }.count, 1)
    }

    func testNewUserGetsNoFloorAndNoTopUp() throws {
        let (store, _) = try makeStore()
        XCTAssertFalse(store.ledgerKeys.contains(LedgerKeys.levelFloor))
        XCTAssertFalse(store.ledgerKeys.contains(LedgerKeys.giftT3ster))
        XCTAssertTrue(store.ledgerKeys.contains(LedgerKeys.migrationEcon2))
        XCTAssertEqual(store.wallet.coins, 0)
        let marker = store.ledger.first { $0.key == LedgerKeys.migrationEcon2 }
        XCTAssertEqual(marker?.kind.isHidden, true, "dòng đánh dấu là dòng hệ thống, không hiện trong lịch sử")
    }

    // MARK: Mã quà

    func testT3sterDoubleTapAndEraseThenRedeemAgain() throws {
        let (store, _) = try makeStore()
        XCTAssertEqual(try store.redeemGiftCode(" T3STER "), .coins(10_000))
        XCTAssertThrowsError(try store.redeemGiftCode("t3ster"))
        XCTAssertEqual(store.wallet.coins, 10_000)
        try store.eraseAllData()
        XCTAssertEqual(store.wallet.coins, 0)
        XCTAssertEqual(try store.redeemGiftCode("t3ster"), .coins(10_000), "xóa toàn bộ dữ liệu thì nhập lại được")
    }

    // MARK: Dữ liệu thử nghiệm

    func testTesterModeUnlocksVirtuallyWithoutTouchingRealData() throws {
        let (store, container) = try makeStore()
        try store.completeOnboarding(userName: "An", petName: "Bông", goals: [], habits: [])
        var draft = TaskDraft()
        draft.title = "Việc thật"
        draft.day = store.today
        try store.createTask(draft)
        let tasksBefore = store.occurrences.count
        let ownedBefore = store.realOwnedIDs

        XCTAssertEqual(try store.redeemGiftCode("phuhotdz"), .needsTesterConfirmation, "phải hỏi lại trước khi bật")
        XCTAssertFalse(store.isTesterMode)
        try store.enableTesterMode()
        XCTAssertTrue(store.isTesterMode)
        XCTAssertEqual(store.wallet.level, LevelCurve.maxLevel)
        XCTAssertEqual(store.wallet.realLevel, 1)
        XCTAssertTrue(Catalog.items.allSatisfy { store.ownedIDs.contains($0.id) }, "mọi món, kể cả món thêm sau, đều thử được")
        XCTAssertEqual(store.realOwnedIDs, ownedBefore, "không ghi đồ vào kho thật")
        XCTAssertEqual(store.occurrences.count, tasksBefore)
        XCTAssertTrue(store.claimableMilestones.isEmpty, "không mở quà mốc cấp thật")
        XCTAssertEqual(store.wallet.xp, 0, "không ghi XP")

        try store.grantTesterCurrency(coins: 1000, tickets: 10)
        XCTAssertEqual(store.wallet.tickets, 10)
        try store.equip(itemID: "hat.beanie")
        XCTAssertEqual(store.equippedMap[.hat], "hat.beanie")

        // Mở lại vẫn nhớ chế độ; tắt thì tháo món chưa thật sự có.
        let (reopened, _) = try makeStore(container)
        XCTAssertTrue(reopened.isTesterMode)
        try reopened.disableTesterMode()
        XCTAssertFalse(reopened.isTesterMode)
        XCTAssertNil(reopened.equippedMap[.hat])
        XCTAssertEqual(reopened.wallet.level, 1)
        XCTAssertEqual(reopened.occurrences.count, tasksBefore)
    }

    // MARK: Nhiệm vụ ngày & rương tuần

    private func satisfy(_ store: AppStore, _ quests: [DailyQuest]) throws {
        for q in quests {
            switch q.kind {
            case .tasks:
                for i in 0..<q.target {
                    var d = TaskDraft()
                    d.title = "Việc \(i)"
                    d.day = store.today
                    let id = try XCTUnwrap(store.createTask(d))
                    _ = try store.setStatus(id: id, to: .done)
                }
            case .focus:
                try store.startFocus(kind: .focus, minutes: q.target, occurrenceID: nil)
                clock.advance(seconds: Double(q.target * 60 + 5))
                _ = try store.reconcileFocus()
            case .care:
                for _ in 0..<q.target { _ = try store.performCare(.cuddle, actionID: UUID()) }
            case .minigame:
                let end = clock.now
                _ = try store.recordMinigame(MinigameOutcome(sessionID: UUID(), kind: .giftBasket, score: 120, primary: 50, secondary: 10,
                                                             level: nil, activeSeconds: 60, completed: true, species: "cat",
                                                             startedAt: end.addingTimeInterval(-60), finishedAt: end))
            case .journal:
                _ = try store.saveJournal(day: store.today, mood: .good, note: "ổn")
            case .breathing:
                _ = try store.completeBreathing(day: store.today)
            }
        }
    }

    func testDailyQuestsClaimOnceAndOnlyWhenComplete() throws {
        let (store, _) = try makeStore()
        let day = store.today
        XCTAssertThrowsError(try store.claimDailyQuests(day: day), "chưa xong")
        try satisfy(store, store.dailyQuests(on: day))
        let before = store.wallet.coins
        let entry = try store.claimDailyQuests(day: day)
        XCTAssertEqual(entry.coins, 15)
        XCTAssertEqual(store.wallet.coins, before + 15)
        XCTAssertThrowsError(try store.claimDailyQuests(day: day), "nhận hai lần")
        XCTAssertEqual(store.wallet.coins, before + 15)
    }

    func testWeeklyChestAfterFourDaysOnce() throws {
        let (store, _) = try makeStore() // thứ Ba 3/11/2026
        for offset in [0, 1, 3, 4] { // thứ Ba, Tư, Sáu, Bảy (không liên tiếp)
            if offset > 0 {
                clock.now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 3 + offset, hour: 9))!
            }
            try satisfy(store, store.dailyQuests(on: store.today))
            try store.claimDailyQuests(day: store.today)
        }
        XCTAssertEqual(store.claimableChestWeek, store.currentWeekStart)
        let chest = try store.claimWeeklyChest(weekStart: store.currentWeekStart)
        XCTAssertEqual(chest.tickets, 1)
        XCTAssertThrowsError(try store.claimWeeklyChest(weekStart: store.currentWeekStart))
        XCTAssertNil(store.claimableChestWeek)
    }

    // MARK: Gacha

    func testGachaResultsStayUnseenUntilShownAndTicketsPay() throws {
        let (store, container) = try makeStore()
        try store.enableTesterMode()
        try store.grantTesterCurrency(coins: 0, tickets: 2)
        let pulls = try store.pullGacha(count: 1, payment: .tickets)
        XCTAssertEqual(store.wallet.tickets, 1)
        XCTAssertEqual(store.wallet.coins, pulls[0].isDuplicate ? pulls[0].refund : 0)
        // App bị đóng trước khi xem: mở lại thấy đúng kết quả cũ, không quay lại.
        let (reopened, _) = try makeStore(container)
        XCTAssertEqual(reopened.unseenGachaPulls.map(\.itemID), pulls.map(\.itemID))
        XCTAssertEqual(reopened.ledger.filter { $0.kind == .gacha }.count, 1)
        try reopened.markGachaSeen()
        XCTAssertTrue(reopened.unseenGachaPulls.isEmpty)
        // Món mới vào kho thật (không phải kho ảo của chế độ thử nghiệm).
        if !pulls[0].isDuplicate { XCTAssertTrue(reopened.realOwnedIDs.contains(pulls[0].itemID)) }
    }

    // MARK: Sao lưu

    func testBackupKeepsFlagsTicketsAndMarkers() throws {
        let (store, _) = try makeStore()
        try store.redeemGiftCode("t3ster")
        try store.enableTesterMode()
        try store.grantTesterCurrency(coins: 0, tickets: 3)
        try store.equip(itemID: "species.capybara")
        XCTAssertFalse(store.realOwnedIDs.contains("species.capybara"))
        let doc = try BackupCodec.decodeAndValidate(try BackupCodec.encode(store.makeBackup()))
        XCTAssertEqual(doc.schemaVersion, BackupDocument.currentSchemaVersion)
        let (other, _) = try makeStore()
        try other.restore(doc)
        XCTAssertTrue(other.isTesterMode)
        XCTAssertEqual(other.petAppearance.species, .capybara)
        XCTAssertFalse(other.realOwnedIDs.contains("species.capybara"))
        XCTAssertEqual(other.wallet.tickets, 3)
        XCTAssertThrowsError(try other.redeemGiftCode("t3ster"), "cờ đã đổi mã đi theo bản sao lưu")
        XCTAssertEqual(other.ledger.filter { $0.key == LedgerKeys.migrationEcon2 }.count, 1)
    }

    func testRestoringOldBackupWithLegacyT3sterTopsUpOnce() throws {
        let (store, _) = try makeStore()
        var doc = store.makeBackup()
        doc.schemaVersion = 2
        doc.ledger = [LedgerEntry(id: UUID(), key: "gift:\(UUID().uuidString.lowercased())", kind: .gift, xp: 0, coins: 1000,
                                  createdAt: clock.now, refID: nil, memo: "Mã quà")]
        let checked = try BackupCodec.decodeAndValidate(try BackupCodec.encode(doc))
        let (other, _) = try makeStore()
        try other.restore(checked)
        XCTAssertEqual(other.wallet.coins, 10_000)
        try other.restore(checked) // khôi phục lại lần nữa: vẫn chỉ bù một lần trên bộ dữ liệu đó
        XCTAssertEqual(other.wallet.coins, 10_000)
    }
}

extension ProgressStoreTests {
    func testGachaPaymentRecoveryAndAcknowledgementAreAtomic() throws {
        let (store, container) = try makeStore()
        try store.redeemGiftCode("t3ster")
        let before = store.wallet
        store.failNextSaveForTesting = true
        XCTAssertThrowsError(try store.pullGacha(count:10))
        XCTAssertEqual(store.wallet,before)
        XCTAssertTrue(store.unseenGachaPulls.isEmpty)
        XCTAssertTrue(store.owned.isEmpty)
        let pulls = try store.pullGacha(count:10)
        let paid = store.wallet
        XCTAssertThrowsError(try store.pullGacha(count:1),"unread batch blocks a double tap")
        XCTAssertEqual(store.wallet,paid)
        let freshDefaults = UserDefaults(suiteName:"Recovery-\(UUID())")!
        let reopened = try AppStore(container:container,clock:clock,calendar:calendar,defaults:freshDefaults)
        XCTAssertEqual(reopened.unseenGachaPulls.map(\.entry.id),pulls.map(\.entry.id),"no UserDefaults dependency")
        reopened.failNextSaveForTesting = true
        XCTAssertThrowsError(try reopened.markGachaSeen())
        XCTAssertEqual(reopened.unseenGachaPulls.count,10)
        let backup = try BackupCodec.decodeAndValidate(BackupCodec.encode(reopened.makeBackup()))
        let (restored, _) = try makeStore()
        try restored.restore(backup)
        XCTAssertEqual(restored.unseenGachaPulls.map(\.entry.id),pulls.map(\.entry.id))
        try restored.markGachaSeen()
        XCTAssertTrue(restored.unseenGachaPulls.isEmpty)
        XCTAssertEqual(restored.wallet,paid)
    }

    func testStarterPetGrantedOnceAndOnboardingCannotChangeExistingPlayer() throws {
        let (store, _) = try makeStore()
        try store.completeOnboarding(userName:"An",petName:"Bông",goals:[],habits:[],species:.puppy)
        XCTAssertEqual(store.petAppearance.species,.puppy)
        XCTAssertTrue(store.realOwnedIDs.contains("species.puppy"))
        try store.completeOnboarding(userName:"Other",petName:"Other",goals:[],habits:[],species:.bunny)
        XCTAssertEqual(store.profile.petName,"Bông")
        XCTAssertFalse(store.realOwnedIDs.contains("species.bunny"))
    }

    func testKeepsakeFreezesStoryAndPlacementSurvivesBackup() throws {
        let (store, _) = try makeStore()
        try satisfy(store,[DailyQuest(kind:.tasks,target:4)])
        let day = store.today
        _ = try store.claimAdventure(day:day)
        let memory = try XCTUnwrap(store.keepsakes.first)
        let story = store.savedAdventureStory(on:day)
        XCTAssertNil(try store.claimAdventure(day:day))
        XCTAssertEqual(store.keepsakes.count,1)
        try store.updateProfile { $0.petName = "Tên khác" }
        XCTAssertEqual(store.savedAdventureStory(on:day),story)
        try store.placeKeepsake(memory.id,in:.study)
        let backup = try BackupCodec.decodeAndValidate(BackupCodec.encode(store.makeBackup()))
        let (restored, _) = try makeStore()
        try restored.restore(backup)
        XCTAssertEqual(restored.keepsakes.first?.placedRoom,RoomKind.study.rawValue)
        XCTAssertEqual(restored.keepsakes.first?.petName,memory.petName)
        XCTAssertEqual(restored.savedAdventureStory(on:day),story)
    }

    func testPurchaseAndEquipRollbackTogether() throws {
        let (store, container) = try makeStore()
        try store.redeemGiftCode("t3ster")
        try store.buy(itemID:"hat.beanie",equipAfterBuying:true)
        let before = store.wallet
        store.failNextSaveForTesting = true
        XCTAssertThrowsError(try store.buy(itemID:"hat.flower",equipAfterBuying:true))
        XCTAssertEqual(store.wallet,before)
        XCTAssertFalse(store.realOwnedIDs.contains("hat.flower"))
        XCTAssertEqual(store.equippedMap[.hat],"hat.beanie")
        let (reopened, _) = try makeStore(container)
        XCTAssertEqual(reopened.wallet,before)
        XCTAssertFalse(reopened.realOwnedIDs.contains("hat.flower"))
        XCTAssertEqual(reopened.equippedMap[.hat],"hat.beanie")
        try reopened.buy(itemID:"hat.flower",equipAfterBuying:true)
        XCTAssertEqual(reopened.equippedMap[.hat],"hat.flower")
        XCTAssertTrue(reopened.realOwnedIDs.contains("hat.flower"))
    }

    func testMeaningfulDaysRemainStableAcrossTimezoneAndBackup() throws {
        clock.now = calendar.date(from:DateComponents(year:2026,month:11,day:3,hour:1))!
        let (store, container) = try makeStore()
        try satisfy(store, [DailyQuest(kind:.tasks,target:1)])
        let days = store.meaningfulDays
        XCTAssertEqual(days, [store.today])
        let west = Calendar.gregorian(timeZone:TimeZone(identifier:"America/Los_Angeles")!)
        let reopened = try AppStore(container:container,clock:clock,calendar:west,defaults:defaults)
        XCTAssertNotEqual(reopened.today, store.today)
        XCTAssertEqual(reopened.meaningfulDays, days)
        let backup = try BackupCodec.decodeAndValidate(BackupCodec.encode(reopened.makeBackup()))
        let (restored, _) = try makeStore()
        try restored.restore(backup)
        XCTAssertEqual(restored.meaningfulDays, days)
    }

    func testEventRewardAndBadgeCannotBeClaimedTwiceOrInTestMode() throws {
        clock.now = calendar.date(from:DateComponents(year:2026,month:10,day:20,hour:9))!
        let (store, _) = try makeStore()
        let event = try XCTUnwrap(VietnameseEvents.active(at:clock.now).first)
        try satisfy(store,event.quests)
        store.failNextSaveForTesting=true
        XCTAssertThrowsError(try store.claimEvent(event))
        XCTAssertTrue(store.keepsakes.isEmpty)
        try store.claimEvent(event)
        let balance = store.wallet.coins
        XCTAssertThrowsError(try store.claimEvent(event))
        XCTAssertEqual(store.wallet.coins,balance)
        XCTAssertEqual(store.keepsakes.count,1)
        try satisfy(store,[DailyQuest(kind:.care,target:10)])
        let badge = try XCTUnwrap(CozyBadge.all.first { $0.id == "care10" })
        try store.claimBadge(badge)
        XCTAssertThrowsError(try store.claimBadge(badge))
        let tasks = store.occurrences
        try store.enableTesterMode()
        try store.disableTesterMode()
        XCTAssertTrue(store.hasTestData)
        XCTAssertEqual(store.occurrences,tasks)
        XCTAssertThrowsError(try store.claimBadge(badge))
    }
}
