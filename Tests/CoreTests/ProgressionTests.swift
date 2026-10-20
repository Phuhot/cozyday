import Foundation
import XCTest
#if canImport(CozyCore)
@testable import CozyCore
#else
@testable import Cozyday
#endif

/// Phiên 9: đường cấp mới, giữ cấp cũ, quà mốc, nhiệm vụ ngày, rương tuần, giá đồ đổi màu, gacha bảo đảm 40, vé.
final class ProgressionTests: XCTestCase {
    private func entry(_ kind: LedgerKind, key: String = UUID().uuidString, xp: Int = 0, coins: Int = 0, tickets: Int = 0,
                       at date: Date = Date(), refID: String? = nil, memo: String = "") -> LedgerEntry {
        LedgerEntry(id: UUID(), key: key, kind: kind, xp: xp, coins: coins, createdAt: date, refID: refID, memo: memo, tickets: tickets)
    }

    // MARK: Cấp

    func testCurveKeepsOldPaceUpToTenThenGrows() {
        XCTAssertEqual(LevelCurve.level(forXP: 0), 1)
        XCTAssertEqual(LevelCurve.level(forXP: 99), 1)
        XCTAssertEqual(LevelCurve.level(forXP: 100), 2)
        XCTAssertEqual(LevelCurve.level(forXP: 900), 10, "cấp 1–10 giữ đúng 100 XP/cấp như bản cũ")
        XCTAssertEqual(LevelCurve.threshold(11), 1050)
        XCTAssertEqual(LevelCurve.threshold(30), 5400)
        XCTAssertEqual(LevelCurve.level(forXP: 5399), 29)
        XCTAssertEqual(LevelCurve.level(forXP: 5400), 30)
        XCTAssertEqual(LevelCurve.level(forXP: 999_999), 30)
        for l in 1..<30 { XCTAssertGreaterThanOrEqual(LevelCurve.cost(from: l + 1), LevelCurve.cost(from: l)) }
        for l in 1...30 { XCTAssertEqual(LevelCurve.level(forXP: LevelCurve.threshold(l)), l) }
    }

    func testLevelFloorNeverLowersOldUsers() {
        // Người dùng cũ có 1.900 XP: công thức cũ là cấp 20, đường mới chỉ ~cấp 15.
        let xp = entry(.taskCompleted, xp: 1900)
        XCTAssertEqual(LevelCurve.legacyLevel(forXP: 1900), 20)
        XCTAssertLessThan(LevelCurve.level(forXP: 1900), 20)
        let floor = entry(.system, key: LedgerKeys.levelFloor, memo: "20")
        let w = Wallet(entries: [xp, floor])
        XCTAssertEqual(w.level, 20)
        XCTAssertEqual(w.xpIntoLevel, 0, "giữ cấp: thanh tiến độ bắt đầu từ 0 cho tới khi XP bắt kịp")
        XCTAssertEqual(w.xpToNextLevel, LevelCurve.threshold(21) - 1900)
        // XP bắt kịp rồi vượt: cấp tăng theo đường mới.
        let more = entry(.taskCompleted, xp: LevelCurve.threshold(22) - 1900)
        XCTAssertEqual(Wallet(entries: [xp, floor, more]).level, 22)
        // Cấp cũ quá 30 bị chặn ở 30.
        XCTAssertEqual(Wallet(entries: [entry(.system, key: LedgerKeys.levelFloor, memo: "41")]).level, 30)
    }

    func testTesterModeShowsMaxLevelButRealLevelStays() {
        let w = Wallet(entries: [entry(.taskCompleted, xp: 150), entry(.tester, key: LedgerKeys.testerMode)])
        XCTAssertEqual(w.level, 30)
        XCTAssertEqual(w.realLevel, 2)
        XCTAssertTrue(LevelMilestones.claimable(realLevel: w.realLevel, existingKeys: []).isEmpty,
                      "chế độ thử nghiệm không mở quà mốc cấp thật")
    }

    func testMilestonesOncePerLevel() {
        XCTAssertEqual(LevelMilestones.claimable(realLevel: 11, existingKeys: []).count, 0)
        let at15 = LevelMilestones.claimable(realLevel: 15, existingKeys: [])
        XCTAssertEqual(at15.map(\.level), [12, 15])
        let m = at15[0]
        let e = LevelMilestones.entry(m, realLevel: 15, existingKeys: [], now: Date())!
        XCTAssertEqual(e.tickets, m.tickets)
        XCTAssertNil(LevelMilestones.entry(m, realLevel: 15, existingKeys: [e.key], now: Date()))
        XCTAssertNil(LevelMilestones.entry(LevelMilestones.milestone(30)!, realLevel: 29, existingKeys: [], now: Date()))
    }

    // MARK: Nhiệm vụ ngày

    func testQuestsAreStableVariedAndFromDifferentGroups() {
        var kinds = Set<QuestKind>()
        for i in 0..<30 {
            let d = day("2026-11-01").adding(days: i, calendar: cal())
            let q = DailyQuests.quests(for: d)
            XCTAssertEqual(q, DailyQuests.quests(for: d), "mở lại app không đổi đề")
            XCTAssertEqual(q.count, 3)
            XCTAssertEqual(Set(q.map(\.kind)).count, 3)
            XCTAssertTrue([QuestKind.tasks, .focus].contains(q[0].kind))
            XCTAssertEqual(q[1].kind, .care)
            XCTAssertTrue([QuestKind.minigame, .journal, .breathing].contains(q[2].kind))
            kinds.formUnion(q.map(\.kind))
        }
        XCTAssertEqual(kinds, Set(QuestKind.allCases), "30 ngày phải có đủ các loại mục tiêu")
    }

    func testQuestSetPaysFifteenOnceAndOnlyWhenAllDone() {
        let d = day("2026-11-03")
        let quests = DailyQuests.quests(for: d)
        var a = DayActivity(tasksDone: 2, focusMinutes: 25, careActions: 2, minigameRuns: 1, journalWritten: true, breathingDone: true)
        let e = DailyQuests.claimEntry(day: d, today: d, calendar: cal(), activity: a, existingKeys: [], now: Date())!
        XCTAssertEqual(e.coins, DailyQuests.setRewardCoins)
        XCTAssertEqual(e.coins, 15, "tổng 15 xu cho cả bộ, không phải mỗi mục")
        XCTAssertNil(DailyQuests.claimEntry(day: d, today: d, calendar: cal(), activity: a, existingKeys: [e.key], now: Date()))
        // Thiếu một mục → chưa nhận được.
        a.careActions = 1
        XCTAssertFalse(DailyQuests.allDone(quests, a))
        XCTAssertNil(DailyQuests.claimEntry(day: d, today: d, calendar: cal(), activity: a, existingKeys: [], now: Date()))
    }

    func testQuestClaimGraceIsOnlyYesterday() {
        let a = DayActivity(tasksDone: 9, focusMinutes: 99, careActions: 9, minigameRuns: 9, journalWritten: true, breathingDone: true)
        let d = day("2026-11-03")
        XCTAssertNotNil(DailyQuests.claimEntry(day: d, today: day("2026-11-04"), calendar: cal(), activity: a, existingKeys: [], now: Date()))
        XCTAssertNil(DailyQuests.claimEntry(day: d, today: day("2026-11-05"), calendar: cal(), activity: a, existingKeys: [], now: Date()))
        XCTAssertNil(DailyQuests.claimEntry(day: day("2026-11-06"), today: day("2026-11-05"), calendar: cal(), activity: a, existingKeys: [], now: Date()))
    }

    // MARK: Rương tuần

    private func questClaim(_ d: String) -> LedgerEntry {
        entry(.quest, key: "quest:\(d)", coins: 15, refID: d)
    }

    func testWeekStartsMonday() {
        XCTAssertEqual(WeeklyChest.weekStart(of: day("2026-11-02"), calendar: cal()), day("2026-11-02")) // thứ Hai
        XCTAssertEqual(WeeklyChest.weekStart(of: day("2026-11-08"), calendar: cal()), day("2026-11-02")) // Chủ nhật
        XCTAssertEqual(WeeklyChest.weekStart(of: day("2026-11-09"), calendar: cal()), day("2026-11-09"))
        XCTAssertEqual(WeeklyChest.weekStart(of: day("2026-11-05"), calendar: cal(TZ.newYork)), day("2026-11-02"))
    }

    func testChestNeedsFourDistinctDaysNotConsecutiveOncePerWeek() {
        let week = day("2026-11-02")
        let three = ["2026-11-02", "2026-11-04", "2026-11-07"].map(questClaim)
        XCTAssertNil(WeeklyChest.claimEntry(weekStart: week, today: day("2026-11-07"), calendar: cal(), ledger: three, existingKeys: [], now: Date()))
        // Ngày của tuần sau không tính vào tuần này.
        let withNextWeek = three + [questClaim("2026-11-09")]
        XCTAssertEqual(WeeklyChest.completedDays(weekStart: week, ledger: withNextWeek, calendar: cal()).count, 3)
        let four = three + [questClaim("2026-11-08")]
        let chest = WeeklyChest.claimEntry(weekStart: week, today: day("2026-11-08"), calendar: cal(), ledger: four, existingKeys: [], now: Date())!
        XCTAssertEqual(chest.tickets, 1)
        XCTAssertEqual(chest.coins, WeeklyChest.coins)
        XCTAssertNil(WeeklyChest.claimEntry(weekStart: week, today: day("2026-11-08"), calendar: cal(), ledger: four + [chest],
                                            existingKeys: [chest.key], now: Date()), "tối đa một rương mỗi tuần")
        // Lỡ sang tuần sau vẫn nhận được rương tuần trước; trễ hai tuần thì thôi.
        XCTAssertNotNil(WeeklyChest.claimEntry(weekStart: week, today: day("2026-11-10"), calendar: cal(), ledger: four, existingKeys: [], now: Date()))
        XCTAssertNil(WeeklyChest.claimEntry(weekStart: week, today: day("2026-11-17"), calendar: cal(), ledger: four, existingKeys: [], now: Date()))
    }

    // MARK: Giá đồ đổi màu

    func testVariantPriceIsSeventyPercentRoundedToFive() {
        XCTAssertEqual(CatalogItem.variantPrice(100), 70)
        XCTAssertEqual(CatalogItem.variantPrice(45), 30)   // 31,5 → 30
        XCTAssertEqual(CatalogItem.variantPrice(55), 40)   // 38,5 → 40
        XCTAssertEqual(CatalogItem.variantPrice(5), 5)
        XCTAssertEqual(CatalogItem.variantPrice(0), 0)
        // Chỉ đồ đổi màu bị giảm: đồ gốc giữ giá, biến thể rẻ hơn gốc cùng giá niêm yết.
        let variants = Catalog.items.filter { $0.variantOf != nil && !$0.gachaOnly }
        XCTAssertGreaterThan(variants.count, 50)
        for v in variants where v.price > 0 { XCTAssertEqual(v.price % 5, 0, v.id) }
        XCTAssertEqual(Catalog.item("lamp.candle")?.price, 20, "đồ gốc không đổi giá")
    }

    // MARK: Gacha

    func testOddsSumToHundredWithThreePercentSecret() {
        XCTAssertEqual(GachaConfig.weights.reduce(0) { $0 + $1.1 }, 100)
        XCTAssertEqual(GachaConfig.weights.first { $0.0 == .secret }?.1, 3)
    }

    func testSecretGuaranteedOnFortiethAfterThirtyNineMisses() {
        for seed in 0..<200 {
            var rng = SeededRNG(seed: UInt64(seed))
            XCTAssertEqual(GachaPolicy.rollTier(sinceEpic: 0, sinceSecret: 39, minimum: .common, rng: &rng), .secret)
        }
        // Lượt 39 (38 lượt trượt) chưa bảo đảm: có lúc không ra Bí mật.
        var rng = SeededRNG(seed: 1)
        let tiers = (0..<200).map { _ in GachaPolicy.rollTier(sinceEpic: 0, sinceSecret: 38, minimum: .common, rng: &rng) }
        XCTAssertTrue(tiers.contains { $0 != .secret })
    }

    func testPityCounterResetsAfterSecretAndCountsSequentially() throws {
        let secret = try XCTUnwrap(Catalog.items.first { $0.gachaOnly && $0.rarity == .secret })
        let other = try XCTUnwrap(Catalog.items.first { $0.gachaOnly && $0.rarity != .secret })
        var ledger: [LedgerEntry] = []
        func pull(_ item: CatalogItem, _ i: Int) {
            let id = UUID()
            ledger.append(LedgerEntry(id: id, key: LedgerKeys.gacha(id), kind: .gacha, xp: 0, coins: -60,
                                      createdAt: Date(timeIntervalSince1970: Double(i)), refID: item.id, memo: ""))
        }
        for i in 0..<20 { pull(other, i) }
        XCTAssertEqual(GachaPolicy.pityCounters(ledger: ledger).sinceSecret, 20)
        pull(secret, 20)
        XCTAssertEqual(GachaPolicy.pityCounters(ledger: ledger).sinceSecret, 0, "ra Bí mật trước lượt 40 → đếm lại")
        for i in 21..<26 { pull(other, i) }
        XCTAssertEqual(GachaPolicy.pityCounters(ledger: ledger).sinceSecret, 5)
    }

    func testTenPullHitsGuaranteeInsideTheBatch() throws {
        // 35 lượt trượt trước đó: trong 10 lượt tiếp theo phải có Bí mật muộn nhất ở lượt thứ 5.
        let other = try XCTUnwrap(Catalog.items.first { $0.gachaOnly && $0.rarity != .secret })
        var ledger = [entry(.gift, key: "gift:t", coins: 5000)]
        for i in 0..<35 {
            let id = UUID()
            ledger.append(LedgerEntry(id: id, key: LedgerKeys.gacha(id), kind: .gacha, xp: 0, coins: -60,
                                      createdAt: Date(timeIntervalSince1970: Double(i)), refID: other.id, memo: ""))
        }
        for seed in 0..<30 {
            var rng = SeededRNG(seed: UInt64(seed))
            let pulls = try GachaPolicy.pull(count: 10, ledger: ledger, owned: [], now: Date(timeIntervalSince1970: 100), rng: &rng)
            let first = try XCTUnwrap(pulls.firstIndex { $0.tier == .secret })
            XCTAssertLessThanOrEqual(first, 4, "seed \(seed)")
        }
    }

    func testPoolHasNoShopItems() {
        let pool = GachaPolicy.pool().values.flatMap { $0 }
        XCTAssertFalse(pool.isEmpty)
        for item in pool {
            XCTAssertTrue(item.gachaOnly, item.id)
            XCTAssertEqual(PurchasePolicy.decide(itemID: item.id, owned: [], ledger: [entry(.gift, coins: 99_999)], now: Date()), .gachaOnly)
        }
        let shopIDs = Set(Catalog.items.filter { !$0.gachaOnly }.map(\.id))
        XCTAssertTrue(Set(pool.map(\.id)).isDisjoint(with: shopIDs))
    }

    func testTicketPullsUseOneTicketEachAndNeedTickets() throws {
        var rng = SeededRNG(seed: 9)
        XCTAssertThrowsError(try GachaPolicy.pull(count: 1, ledger: [], owned: [], now: Date(), payment: .tickets, rng: &rng))
        let ledger = [entry(.quest, key: "chest:x", tickets: 1)]
        let p = try GachaPolicy.pull(count: 1, ledger: ledger, owned: [], now: Date(), payment: .tickets, rng: &rng)[0]
        XCTAssertEqual(p.entry.tickets, -1)
        XCTAssertGreaterThanOrEqual(p.entry.coins, 0, "trả bằng vé không trừ xu")
        XCTAssertEqual(Wallet(entries: ledger + [p.entry]).tickets, 0)
    }

    // MARK: Dữ liệu cũ

    func testLedgerEntryWithoutTicketsDecodes() throws {
        let json = #"{"id":"5A1B0E2C-1111-4F6A-9A0B-111111111111","key":"task:x","kind":"taskCompleted","xp":10,"coins":8,"createdAt":0,"memo":"x"}"#
        let e = try JSONDecoder().decode(LedgerEntry.self, from: Data(json.utf8))
        XCTAssertEqual(e.tickets, 0)
        let roundTrip = try JSONDecoder().decode(LedgerEntry.self, from: JSONEncoder().encode(entry(.quest, tickets: 2)))
        XCTAssertEqual(roundTrip.tickets, 2)
    }
}
