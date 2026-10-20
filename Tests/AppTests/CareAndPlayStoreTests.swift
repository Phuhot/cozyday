import XCTest
import SwiftData
@testable import Cozyday

/// Chăm thú cưng và Sân chơi trên lớp lưu trữ thật (SwiftData trong bộ nhớ): giao dịch, thử lại, hạn mức, sao lưu.
@MainActor
final class CareAndPlayStoreTests: XCTestCase {
    private var clock: ManualClock!
    private var calendar: Calendar!

    override func setUp() async throws {
        calendar = Calendar.gregorian(timeZone: TimeZone(identifier: "Asia/Ho_Chi_Minh")!)
        clock = ManualClock(calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 9))!)
    }

    private func makeStore(_ container: ModelContainer? = nil) throws -> (AppStore, ModelContainer) {
        let c = try container ?? PersistenceController.makeContainer(inMemory: true)
        return (try AppStore(container: c, clock: clock, calendar: calendar), c)
    }

    private func grantCoins(_ store: AppStore, _ coins: Int, xp: Int = 0) throws {
        try store.commit {
            store.insertLedger(LedgerEntry(id: UUID(), key: "test:\(UUID())", kind: .taskCompleted, xp: xp, coins: coins,
                                           createdAt: store.now, refID: nil, memo: "test"))
        }
    }

    private func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    // MARK: Chăm sóc

    func testCareProfileAndWelcomePackCreatedOnlyOnce() throws {
        let (store, container) = try makeStore()
        XCTAssertEqual(store.foodCount("food.apple"), 3)
        XCTAssertEqual(store.foodCount("food.riceball"), 1)
        XCTAssertEqual(store.currentNeeds.fullness, CareConfig.initialFullness)
        XCTAssertNil(store.currentNeeds.mostUrgent, "pet mới không đói, nhà không bẩn")
        let (relaunched, _) = try makeStore(container)
        XCTAssertEqual(relaunched.foodCount("food.apple"), 3, "mở lại app không tặng thêm")
        XCTAssertEqual(try ModelContext(container).fetch(FetchDescriptor<PetCareStateModel>()).count, 1)
    }

    func testFeedingUsesOneFoodRewardsOnlyWhenHungryAndRetryIsNoOp() throws {
        let (store, _) = try makeStore()
        // Đang ổn: cho ăn được nhưng không thưởng.
        let calm = try store.performCare(.feed, foodID: "food.apple", actionID: UUID())
        XCTAssertEqual(calm.note, .notNeeded)
        XCTAssertEqual(store.foodCount("food.apple"), 2)
        XCTAssertEqual(store.wallet.xp, 0)

        clock.advance(seconds: 22 * 3600) // 98 − 66 = 32
        XCTAssertEqual(store.currentNeeds.level(.fullness), .needsCare)
        let id = UUID()
        let fed = try store.performCare(.feed, foodID: "food.apple", actionID: id)
        XCTAssertEqual(fed.note, .rewarded)
        XCTAssertEqual(store.foodCount("food.apple"), 1)
        XCTAssertEqual(store.wallet.xp, CareConfig.feedXP)
        XCTAssertEqual(store.wallet.coins, CareConfig.feedCoins)
        // Bấm nhanh/thử lại cùng ID: không trừ thêm đồ ăn, không thưởng thêm.
        XCTAssertEqual(try store.performCare(.feed, foodID: "food.apple", actionID: id), fed)
        XCTAssertEqual(store.foodCount("food.apple"), 1)
        XCTAssertEqual(store.ledger.filter { $0.kind == .care }.count, 1)
        XCTAssertLessThanOrEqual(store.currentNeeds.fullness, 100)
    }

    func testFullPetKeepsFoodAndEmptyTrayRefuses() throws {
        let (store, _) = try makeStore()
        _ = try store.performCare(.feed, foodID: "food.riceball", actionID: UUID()) // 80 → 100
        XCTAssertEqual(store.currentNeeds.fullness, 100)
        XCTAssertThrowsError(try store.performCare(.feed, foodID: "food.apple", actionID: UUID()))
        XCTAssertEqual(store.foodCount("food.apple"), 3, "no tối đa: không tiêu hao đồ ăn")
        clock.advance(seconds: 10 * 3600)
        XCTAssertThrowsError(try store.performCare(.feed, foodID: "food.picnic", actionID: UUID())) {
            XCTAssertEqual($0 as? CareError, .noFood)
        }
    }

    func testFoodPurchaseRepeatableRetrySafeAndNeedsCoins() throws {
        let (store, _) = try makeStore()
        XCTAssertThrowsError(try store.buyFood("food.carrot", transactionID: UUID()), "0 xu: không mua được")
        XCTAssertEqual(store.foodCount("food.carrot"), 0)
        XCTAssertEqual(store.ledger.count, 0)
        try grantCoins(store, 20)
        let tx = UUID()
        XCTAssertTrue(try store.buyFood("food.carrot", transactionID: tx))
        XCTAssertFalse(try store.buyFood("food.carrot", transactionID: tx), "thử lại cùng giao dịch")
        XCTAssertTrue(try store.buyFood("food.carrot", transactionID: UUID()), "mua lặp lại được")
        XCTAssertEqual(store.foodCount("food.carrot"), 2)
        XCTAssertEqual(store.wallet.coins, 20 - 2 * 3)
        XCTAssertFalse(store.ownedIDs.contains("food.carrot"), "đồ ăn không phải đồ sở hữu vĩnh viễn")
        XCTAssertThrowsError(try store.buyFood("food.picnic", transactionID: UUID()))
        XCTAssertEqual(store.wallet.coins, 14)
    }

    func testSaveFailureRollsBackAndRetryWithSameIDAppliesOnce() throws {
        let (store, _) = try makeStore()
        clock.advance(seconds: 24 * 3600)
        let needsBefore = store.currentNeeds
        let id = UUID()
        store.failNextSaveForTesting = true
        XCTAssertThrowsError(try store.performCare(.feed, foodID: "food.apple", actionID: id))
        XCTAssertEqual(store.foodCount("food.apple"), 3, "lỗi lưu: không mất đồ ăn")
        XCTAssertEqual(store.wallet, Wallet())
        XCTAssertNil(store.careAction(id))
        XCTAssertEqual(store.currentNeeds, needsBefore)
        try store.performCare(.feed, foodID: "food.apple", actionID: id)
        try store.performCare(.feed, foodID: "food.apple", actionID: id)
        XCTAssertEqual(store.foodCount("food.apple"), 2)
        XCTAssertEqual(store.ledger.filter { $0.kind == .care }.count, 1)

        // Mua đồ ăn lỗi lưu rồi thử lại.
        try grantCoins(store, 10)
        let tx = UUID()
        store.failNextSaveForTesting = true
        XCTAssertThrowsError(try store.buyFood("food.apple", transactionID: tx))
        XCTAssertEqual(store.wallet.coins, 10 + CareConfig.feedCoins)
        XCTAssertTrue(try store.buyFood("food.apple", transactionID: tx))
        XCTAssertFalse(try store.buyFood("food.apple", transactionID: tx))
        XCTAssertEqual(store.foodCount("food.apple"), 3)
    }

    func testFreeMealRescuesHungryPetWithoutCoinsAndCannotFarm() throws {
        let (store, _) = try makeStore()
        XCTAssertThrowsError(try store.performCare(.freeMeal, actionID: UUID()), "chưa đói")
        clock.advance(seconds: 24 * 3600)
        let meal = try store.performCare(.freeMeal, actionID: UUID())
        XCTAssertEqual(meal.note, .freeMeal)
        XCTAssertEqual(store.currentNeeds.fullness, CareConfig.freeMealTo)
        XCTAssertThrowsError(try store.performCare(.freeMeal, actionID: UUID()), "bấm liên tục không được")
        XCTAssertEqual(store.wallet, Wallet())
        XCTAssertEqual(store.totalFood, 4, "không tạo vật phẩm")
    }

    func testCleanAndCuddleCapsAcrossMidnightAndSpeciesChangeKeepsNeeds() throws {
        let (store, _) = try makeStore()
        clock.now = at(20, 22) // ~37 giờ sau: mọi chỉ số chạm mức 24 giờ
        XCTAssertEqual(store.currentNeeds.level(.cleanliness), .normal, "nhà bẩn chậm hơn")
        clock.now = at(21, 9)
        let needs = store.currentNeeds
        // Đổi loài không đổi nhu cầu.
        try grantCoins(store, 60, xp: RewardConfig.xpPerLevel)
        try store.buy(itemID: "species.bunny")
        try store.equip(itemID: "species.bunny")
        XCTAssertEqual(store.currentNeeds, needs)

        XCTAssertEqual(try store.performCare(.cuddle, actionID: UUID()).note, .rewarded)
        clock.now = at(21, 9, 5)
        // Đã vui (20 + 35 = 55): nựng thêm vẫn được nhưng không thưởng.
        let again = try store.performCare(.cuddle, actionID: UUID())
        XCTAssertEqual(again.note, .notNeeded)
        XCTAssertEqual(again.after, 90)
        // Đúng nửa đêm: hạn mức ngày mới, nhưng chỉ số phải dưới ngưỡng mới có thưởng.
        clock.now = at(22, 0, 1)
        XCTAssertEqual(store.today.string, "2026-10-22")
        XCTAssertEqual(store.careTotalsToday.xp, 0)
    }

    // MARK: Sân chơi

    private func outcome(_ kind: MinigameKind = .giftBasket, score: Int = 120, finished: Date? = nil, id: UUID = UUID()) -> MinigameOutcome {
        let end = finished ?? clock.now
        return MinigameOutcome(sessionID: id, kind: kind, score: score, primary: 50, secondary: 10, level: nil,
                               activeSeconds: 60, completed: true, species: "cat",
                               startedAt: end.addingTimeInterval(-60), finishedAt: end)
    }

    func testMinigameRewardSavedOnceAndSurvivesRelaunch() throws {
        let (store, container) = try makeStore()
        let o = outcome()
        let save = try store.recordMinigame(o)
        XCTAssertTrue(save.isNew)
        XCTAssertTrue(save.isNewBest)
        XCTAssertEqual(save.record.coins, 6)
        XCTAssertEqual(store.wallet.coins, 6)
        XCTAssertEqual(store.wallet.xp, 0, "Sân chơi không cho XP")
        XCTAssertFalse(try store.recordMinigame(o).isNew, "bấm nhận lại không cộng thêm")
        let (relaunched, _) = try makeStore(container)
        XCTAssertEqual(relaunched.minigameResult(o.sessionID)?.coins, 6, "đóng app trước màn kết quả vẫn đọc lại được")
        XCTAssertFalse(try relaunched.recordMinigame(o).isNew)
        XCTAssertEqual(relaunched.wallet.coins, 6)
        XCTAssertEqual(relaunched.ledger.filter { $0.key == LedgerKeys.minigame(o.sessionID) }.count, 1)
        XCTAssertEqual(relaunched.bestResult(.giftBasket)?.id, o.sessionID)
    }

    func testDailyCapPartialThenZeroButScoreStillSavedAndMidnightResets() throws {
        let (store, _) = try makeStore()
        var total = 0
        for _ in 0..<3 { total += try store.recordMinigame(outcome()).record.coins } // 18
        XCTAssertEqual(total, 18)
        let partial = try store.recordMinigame(outcome())
        XCTAssertEqual(partial.record.coins, MinigameConfig.dailyCoinCap - 18)
        XCTAssertEqual(partial.record.note, .partialCap)
        let capped = try store.recordMinigame(outcome(score: 300))
        XCTAssertEqual(capped.record.coins, 0)
        XCTAssertEqual(capped.record.note, .dailyCapReached)
        XCTAssertTrue(capped.isNewBest, "hết hạn mức vẫn lưu kỷ lục")
        XCTAssertEqual(store.minigameCoins(on: store.today), MinigameConfig.dailyCoinCap)

        // Lượt bắt đầu trước nửa đêm, kết thúc sau nửa đêm: tính vào ngày mới.
        clock.now = at(20, 0, 0)
        let crossing = try store.recordMinigame(outcome(finished: at(20, 0, 0)))
        XCTAssertEqual(crossing.record.day.string, "2026-10-20")
        XCTAssertEqual(crossing.record.coins, 6)
    }

    func testEarlyExitAndImplausibleGiveNothing() throws {
        let (store, _) = try makeStore()
        var early = outcome()
        early.completed = false
        early.activeSeconds = 20
        XCTAssertEqual(try store.recordMinigame(early).record.coins, 0)
        var cheat = outcome(score: 99_999)
        cheat.sessionID = UUID()
        XCTAssertEqual(try store.recordMinigame(cheat).record.note, .implausible)
        XCTAssertEqual(store.wallet.coins, 0)
        // Mốc kết thúc ở tương lai bị kẹp về hiện tại.
        let future = try store.recordMinigame(outcome(finished: clock.now.addingTimeInterval(5 * 86400)))
        XCTAssertEqual(future.record.day, store.today)
    }

    func testMinigameSaveFailureCanRetrySameSession() throws {
        let (store, _) = try makeStore()
        let o = outcome()
        store.failNextSaveForTesting = true
        XCTAssertThrowsError(try store.recordMinigame(o))
        XCTAssertNil(store.minigameResult(o.sessionID))
        XCTAssertEqual(store.wallet.coins, 0, "lỗi lưu: không báo đã nhận")
        let retry = try store.recordMinigame(o)
        XCTAssertTrue(retry.isNew)
        XCTAssertEqual(store.wallet.coins, 6)
        XCTAssertFalse(try store.recordMinigame(o).isNew)
        XCTAssertEqual(store.wallet.coins, 6)
    }

    // MARK: Sao lưu

    func testBackupRoundTripKeepsCareStockResultsAndLedger() throws {
        let (store, _) = try makeStore()
        try grantCoins(store, 30)
        try store.buyFood("food.picnic", transactionID: UUID())
        clock.advance(seconds: 24 * 3600)
        try store.performCare(.clean, actionID: UUID())
        try store.recordMinigame(outcome())
        let doc = try BackupCodec.decodeAndValidate(try BackupCodec.encode(store.makeBackup()))
        let (other, _) = try makeStore()
        try other.restore(doc)
        XCTAssertEqual(other.petCare, store.petCare)
        XCTAssertEqual(other.foodCount("food.picnic"), 1)
        XCTAssertEqual(other.foodCount("food.apple"), 3)
        XCTAssertEqual(other.careActions, store.careActions)
        XCTAssertEqual(other.minigameResults, store.minigameResults)
        XCTAssertEqual(other.wallet, store.wallet)
        // Sau khôi phục vẫn chống thưởng trùng.
        let o = try XCTUnwrap(store.minigameResults.first)
        XCTAssertFalse(try other.recordMinigame(outcome(id: o.id)).isNew)
        XCTAssertEqual(other.wallet, store.wallet)
    }

    func testRestoringOldBackupUsesDefaultsWithoutSecondWelcomePack() throws {
        let (store, _) = try makeStore()
        var doc = store.makeBackup()
        doc.schemaVersion = 1
        doc.petCare = nil
        doc.foodStock = nil
        doc.careActions = nil
        doc.minigameResults = nil
        let decoded = try BackupCodec.decodeAndValidate(try BackupCodec.encode(doc))
        try store.performCare(.feed, foodID: "food.apple", actionID: UUID())
        try store.restore(decoded)
        XCTAssertEqual(store.totalFood, 0, "bản sao lưu cũ: khay trống, không tặng lại gói chào mừng")
        XCTAssertEqual(store.currentNeeds.fullness, CareConfig.initialFullness)
        XCTAssertTrue(store.careActions.isEmpty)
    }
}
