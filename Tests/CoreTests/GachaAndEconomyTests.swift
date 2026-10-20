import XCTest
#if canImport(CozyCore)
@testable import CozyCore
#else
@testable import Cozyday
#endif

final class GachaAndEconomyTests: XCTestCase {
    private func gift(_ coins: Int, at date: Date = Date()) -> LedgerEntry {
        let id = UUID()
        return LedgerEntry(id: id, key: LedgerKeys.gift(id), kind: .gift, xp: 0, coins: coins, createdAt: date, refID: nil, memo: "test")
    }

    // MARK: Hạn mức thưởng việc

    func testTaskRewardsAreCappedPerDay() {
        let calendar = cal()
        let now = Date()
        var ledger: [LedgerEntry] = []
        for _ in 0..<(RewardConfig.taskRewardsPerDay + 3) {
            let rewarded = RewardPolicy.taskRewardsToday(ledger, now: now, calendar: calendar)
            let entry = RewardPolicy.forTaskCompletion(occurrence: makeOneOff(), existingKeys: Set(ledger.map(\.key)),
                                                       rewardedToday: rewarded, now: now)!
            ledger.append(entry)
        }
        XCTAssertEqual(Wallet(entries: ledger).xp, RewardConfig.taskRewardsPerDay * RewardConfig.taskXP)
        XCTAssertEqual(Wallet(entries: ledger).coins, RewardConfig.taskRewardsPerDay * RewardConfig.taskCoins)
        XCTAssertTrue(ledger.last!.memo.hasPrefix(RewardPolicy.taskCapMemo))
        // Ngày hôm sau có lại hạn mức.
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        XCTAssertEqual(RewardPolicy.taskRewardsToday(ledger, now: tomorrow, calendar: calendar), 0)
    }

    // MARK: Máy gacha

    func testGachaNeedsCoins() {
        var rng = SeededRNG(seed: 1)
        XCTAssertThrowsError(try GachaPolicy.pull(count: 1, ledger: [gift(59)], owned: [], now: Date(), rng: &rng)) { error in
            XCTAssertEqual(error as? GachaError, .insufficientCoins(needed: 60, available: 59))
        }
    }

    func testSinglePullChargesAndGivesNewItem() throws {
        var rng = SeededRNG(seed: 7)
        let ledger = [gift(100)]
        let pulls = try GachaPolicy.pull(count: 1, ledger: ledger, owned: [], now: Date(), rng: &rng)
        XCTAssertEqual(pulls.count, 1)
        let p = pulls[0]
        XCTAssertFalse(p.isDuplicate)
        XCTAssertEqual(p.entry.coins, -GachaConfig.singlePrice)
        XCTAssertEqual(p.entry.kind, .gacha)
        XCTAssertNotNil(Catalog.item(p.itemID))
        XCTAssertTrue(Catalog.item(p.itemID)!.gachaOnly, "máy chỉ ra đồ riêng của máy")
        XCTAssertEqual(Wallet(entries: ledger + [p.entry]).coins, 40)
    }

    func testTenPullCostsTenPriceAndHasAtLeastRare() throws {
        for seed in 0..<40 {
            var rng = SeededRNG(seed: UInt64(seed))
            let pulls = try GachaPolicy.pull(count: 10, ledger: [gift(1000)], owned: [], now: Date(), rng: &rng)
            XCTAssertEqual(pulls.count, 10)
            let refunds = pulls.reduce(0) { $0 + $1.refund }
            XCTAssertEqual(-pulls.reduce(0) { $0 + $1.entry.coins } + refunds, GachaConfig.tenPrice)
            XCTAssertTrue(pulls.contains { $0.tier >= .rare }, "seed \(seed)")
            XCTAssertEqual(Set(pulls.map(\.entry.key)).count, 10)
            // Ưu tiên món chưa có: còn món chưa có trong nhóm thì không ra món trùng.
            var seen = Set<String>()
            for p in pulls {
                let unseenLeft = (GachaPolicy.pool()[p.tier] ?? []).contains { !seen.contains($0.id) }
                if unseenLeft { XCTAssertFalse(seen.contains(p.itemID), "seed \(seed)") }
                seen.insert(p.itemID)
            }
        }
    }

    func testEpicPityAfterNineMisses() throws {
        let common = try XCTUnwrap(GachaPolicy.pool()[.common]?.first ?? GachaPolicy.pool()[.rare]?.first)
        var ledger = [gift(5000)]
        for i in 0..<(GachaConfig.epicPity - 1) {
            let id = UUID()
            ledger.append(LedgerEntry(id: id, key: LedgerKeys.gacha(id), kind: .gacha, xp: 0, coins: -60,
                                      createdAt: Date().addingTimeInterval(Double(i)), refID: common.id, memo: ""))
        }
        XCTAssertEqual(GachaPolicy.pityCounters(ledger: ledger).sinceEpic, GachaConfig.epicPity - 1)
        for seed in 0..<20 {
            var rng = SeededRNG(seed: UInt64(seed))
            let p = try GachaPolicy.pull(count: 1, ledger: ledger, owned: [], now: Date().addingTimeInterval(100), rng: &rng)[0]
            XCTAssertGreaterThanOrEqual(p.tier, .epic)
        }
    }

    func testDuplicateRefundsWhenTierFullyOwned() throws {
        let pool = GachaPolicy.pool()
        let everything = Set(pool.values.flatMap { $0.map(\.id) })
        var rng = SeededRNG(seed: 3)
        let p = try GachaPolicy.pull(count: 1, ledger: [gift(100)], owned: everything, now: Date(), rng: &rng)[0]
        XCTAssertTrue(p.isDuplicate)
        XCTAssertEqual(p.refund, GachaConfig.duplicateRefund(p.tier))
        XCTAssertEqual(p.entry.coins, p.refund - GachaConfig.singlePrice)
    }

    func testOddsRoughlyMatchConfig() {
        var rng = SeededRNG(seed: 42)
        var counts: [ItemRarity: Int] = [:]
        let n = 20000
        for _ in 0..<n {
            counts[GachaPolicy.rollTier(sinceEpic: 0, sinceSecret: 0, minimum: .common, rng: &rng), default: 0] += 1
        }
        for (r, w) in GachaConfig.weights {
            XCTAssertEqual(Double(counts[r] ?? 0) / Double(n), Double(w) / 100, accuracy: 0.015, "\(r)")
        }
    }

    func testGachaOnlyItemsCannotBeBought() {
        for item in Catalog.items where item.gachaOnly {
            let d = PurchasePolicy.decide(itemID: item.id, owned: [], ledger: [gift(100_000)], now: Date())
            XCTAssertEqual(d, .gachaOnly)
        }
    }
}

final class GiftCodeTests: XCTestCase {
    private func legacyRedemption(_ i: Int) -> LedgerEntry {
        let id = UUID()
        return LedgerEntry(id: id, key: LedgerKeys.gift(id), kind: .gift, xp: 0, coins: 1000,
                           createdAt: Date().addingTimeInterval(Double(i)), refID: nil, memo: "Mã quà")
    }

    func testCodeKinds() {
        XCTAssertEqual(GiftCodes.kind(of: " T3STER "), .coins)
        XCTAssertEqual(GiftCodes.kind(of: "PhuHotDz"), .testerMode)
        XCTAssertNil(GiftCodes.kind(of: "tester"))
    }

    func testT3sterGivesTenThousandOncePerDataset() {
        let first = GiftCodes.t3sterEntry(ledger: [], existingKeys: [], now: Date(), isTopUp: false)!
        XCTAssertEqual(first.coins, 10_000)
        XCTAssertEqual(first.key, LedgerKeys.giftT3ster)
        XCTAssertNil(GiftCodes.t3sterEntry(ledger: [first], existingKeys: [first.key], now: Date(), isTopUp: false),
                     "khóa cố định: nhập lại không nhận thêm")
    }

    func testLegacyRedemptionTopsUpToTenThousand() {
        let once = [legacyRedemption(0)]
        XCTAssertEqual(GiftCodes.legacyT3sterReceived(once), 1000)
        XCTAssertEqual(GiftCodes.t3sterEntry(ledger: once, existingKeys: [], now: Date(), isTopUp: true)?.coins, 9_000)
        // Bản cũ cho nhập lại: đã nhận 3 lần → bù 7.000; đã nhận 12 lần → không bù thêm, vẫn khóa mã (0 xu), không thu hồi.
        let three = (0..<3).map(legacyRedemption)
        XCTAssertEqual(GiftCodes.t3sterEntry(ledger: three, existingKeys: [], now: Date(), isTopUp: true)?.coins, 7_000)
        let twelve = (0..<12).map(legacyRedemption)
        let lock = GiftCodes.t3sterEntry(ledger: twelve, existingKeys: [], now: Date(), isTopUp: true)
        XCTAssertEqual(lock?.coins, 0)
        XCTAssertEqual(lock?.key, LedgerKeys.giftT3ster)
        // Dòng gift khác (không đúng dấu vết 1.000 xu "Mã quà") không bị coi là t3ster cũ.
        let other = LedgerEntry(id: UUID(), key: "gift:x", kind: .gift, xp: 0, coins: 500, createdAt: Date(), refID: nil, memo: "Quà")
        XCTAssertEqual(GiftCodes.legacyT3sterReceived([other]), 0)
    }
}
