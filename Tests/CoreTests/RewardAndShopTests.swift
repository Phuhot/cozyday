import XCTest
#if canImport(CozyCore)
@testable import CozyCore
#else
@testable import Cozyday
#endif

final class RewardAndShopTests: XCTestCase {
    func testTaskRewardOnlyOncePerOccurrence() {
        let occ = makeOneOff()
        var ledger: [LedgerEntry] = []
        // Bấm nhanh 3 lần / bỏ hoàn thành rồi hoàn thành lại
        for _ in 0..<3 {
            if let entry = RewardPolicy.forTaskCompletion(occurrence: occ, existingKeys: Set(ledger.map(\.key)), now: Date()) {
                ledger.append(entry)
            }
        }
        XCTAssertEqual(ledger.count, 1)
        XCTAssertEqual(Wallet(entries: ledger), Wallet(xp: RewardConfig.taskXP, coins: RewardConfig.taskCoins))
    }

    func testFocusRewardNeedsMinimumAndIsCapped() {
        XCTAssertEqual(RewardConfig.focusReward(plannedMinutes: 5).xp, 0)
        XCTAssertEqual(RewardConfig.focusReward(plannedMinutes: 25).xp, 10)
        XCTAssertEqual(RewardConfig.focusReward(plannedMinutes: 25).coins, 5)
        XCTAssertEqual(RewardConfig.focusReward(plannedMinutes: 500).xp, RewardConfig.focusReward(plannedMinutes: 120).xp)
        let id = UUID()
        let first = RewardPolicy.forFocus(sessionID: id, plannedMinutes: 25, existingKeys: [], now: Date())
        XCTAssertNotNil(first)
        XCTAssertNil(RewardPolicy.forFocus(sessionID: id, plannedMinutes: 25, existingKeys: [first!.key], now: Date()))
    }

    func testJournalRewardOncePerDay() {
        let d = day("2026-10-18")
        let first = RewardPolicy.forJournal(day: d, existingKeys: [], now: Date())!
        XCTAssertNil(RewardPolicy.forJournal(day: d, existingKeys: [first.key], now: Date()))
        XCTAssertNotNil(RewardPolicy.forJournal(day: d.adding(days: 1, calendar: cal()), existingKeys: [first.key], now: Date()))
    }

    func testCatalogHasFixedUniqueIDsAndFreeItems() {
        XCTAssertEqual(Set(Catalog.items.map(\.id)).count, Catalog.items.count)
        XCTAssertTrue((12...15).contains(Catalog.items.count))
        XCTAssertGreaterThanOrEqual(Catalog.items.filter(\.isFree).count, 3)
        for slot in RoomSlot.allCases {
            XCTAssertFalse(Catalog.items(in: slot).isEmpty, "slot \(slot) trống")
        }
    }

    func testPurchaseRules() {
        let reward = LedgerEntry(id: UUID(), key: "task:x", kind: .taskCompleted, xp: 10, coins: 30, createdAt: Date(), refID: nil, memo: "")
        var ledger = [reward]
        var owned: Set<String> = []

        // Thiếu xu
        XCTAssertEqual(
            PurchasePolicy.decide(itemID: "lamp.desk", owned: owned, ledger: ledger, now: Date()),
            .insufficientCoins(needed: 45, available: 30)
        )
        // Mua được
        guard case .approved(let entry) = PurchasePolicy.decide(itemID: "lamp.candle", owned: owned, ledger: ledger, now: Date()) else {
            return XCTFail("phải mua được")
        }
        ledger.append(entry)
        owned.insert("lamp.candle")
        XCTAssertEqual(Wallet(entries: ledger).coins, 10)
        // Bấm mua lần nữa (kể cả khi inventory chưa kịp cập nhật) → không trừ lần 2
        XCTAssertEqual(PurchasePolicy.decide(itemID: "lamp.candle", owned: [], ledger: ledger, now: Date()), .alreadyOwned)
        XCTAssertEqual(PurchasePolicy.decide(itemID: "lamp.candle", owned: owned, ledger: ledger, now: Date()), .alreadyOwned)
        XCTAssertEqual(Wallet(entries: ledger).coins, 10)
        // Đồ miễn phí
        guard case .approved(let free) = PurchasePolicy.decide(itemID: "desk.pine", owned: owned, ledger: ledger, now: Date()) else {
            return XCTFail("đồ miễn phí phải nhận được")
        }
        XCTAssertEqual(free.coins, 0)
        XCTAssertEqual(PurchasePolicy.decide(itemID: "nope", owned: owned, ledger: ledger, now: Date()), .unknownItem)
    }

    func testLevelProgress() {
        let w = Wallet(xp: 250, coins: 0)
        XCTAssertEqual(w.level, 3)
        XCTAssertEqual(w.xpIntoLevel, 50)
    }
}
