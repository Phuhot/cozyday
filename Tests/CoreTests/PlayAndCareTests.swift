import Foundation
import XCTest
#if canImport(CozyCore)
@testable import CozyCore
#else
@testable import Cozyday
#endif

/// Nhu cầu thú cưng, đồ ăn, thưởng chăm sóc.
final class CareTests: XCTestCase {
    private let t0 = date(2026, 10, 19, 8)

    func testDecayIsSlowHasFloorAndCaps24Hours() {
        let start = PetNeeds(fullness: 100, cleanliness: 100, happiness: 100, asOf: t0)
        let tenMinutes = start.at(t0.addingTimeInterval(600))
        XCTAssertEqual(tenMinutes.fullness, 99.5, accuracy: 0.001, "vài phút chỉ giảm rất ít")
        let tenHours = start.at(t0.addingTimeInterval(10 * 3600))
        XCTAssertEqual(tenHours.fullness, 70, accuracy: 0.001)
        XCTAssertEqual(tenHours.cleanliness, 80, accuracy: 0.001)
        XCTAssertEqual(tenHours.happiness, 75, accuracy: 0.001)
        // Một tuần vắng mặt = 24 giờ, không thấp hơn sàn.
        let week = start.at(t0.addingTimeInterval(7 * 24 * 3600))
        let day = start.at(t0.addingTimeInterval(24 * 3600))
        XCTAssertEqual(week.fullness, day.fullness)
        XCTAssertEqual(day.fullness, 28, accuracy: 0.001)
        let low = PetNeeds(fullness: 30, cleanliness: 25, happiness: 21, asOf: t0).at(t0.addingTimeInterval(7 * 24 * 3600))
        XCTAssertEqual(low.fullness, CareConfig.floor)
        XCTAssertEqual(low.cleanliness, CareConfig.floor)
        XCTAssertEqual(low.happiness, CareConfig.floor)
    }

    func testReadingRepeatedlyDoesNotDecayTwiceAndClockRollbackNeverRaises() {
        let stored = PetNeeds(fullness: 60, cleanliness: 60, happiness: 60, asOf: t0)
        let later = t0.addingTimeInterval(5 * 3600)
        XCTAssertEqual(stored.at(later), stored.at(later))
        // Đọc lại từ bản đã tính (asOf mới) cũng ra cùng kết quả.
        XCTAssertEqual(stored.at(later).at(later), stored.at(later))
        // Đồng hồ quay ngược: không tăng chỉ số, mốc không lùi.
        let earlier = stored.at(t0.addingTimeInterval(-3 * 3600))
        XCTAssertEqual(earlier.fullness, 60)
        XCTAssertEqual(earlier.asOf, t0)
        let afterRollback = stored.at(later).at(t0)
        XCTAssertEqual(afterRollback.fullness, stored.at(later).fullness)
    }

    func testMostUrgentPicksOneNeed() {
        XCTAssertNil(PetNeeds(fullness: 50, cleanliness: 80, happiness: 40, asOf: t0).mostUrgent)
        XCTAssertEqual(PetNeeds(fullness: 30, cleanliness: 22, happiness: 34, asOf: t0).mostUrgent, .cleanliness)
        XCTAssertEqual(NeedLevel(34.9), .needsCare)
        XCTAssertEqual(NeedLevel(35), .normal)
        XCTAssertEqual(NeedLevel(70), .good)
    }

    private func perform(_ kind: CareActionKind, food: String? = nil, needs: PetNeeds, history: [CareActionRecord] = [],
                         at: Date? = nil) throws -> CareOutcome {
        let when = at ?? t0
        return try CarePolicy.perform(kind, foodID: food, actionID: UUID(), stored: needs, now: when,
                                      day: DayKey(when, calendar: cal()), history: history, existingKeys: [])
    }

    func testCareRewardsOnlyWhenNeededAndCapsPerKindAndDay() throws {
        let hungry = PetNeeds(fullness: 30, cleanliness: 30, happiness: 30, asOf: t0)
        let fed = try perform(.feed, food: "food.apple", needs: hungry)
        XCTAssertEqual(fed.needs.fullness, 48, accuracy: 0.01)
        XCTAssertEqual(fed.record.xp, CareConfig.feedXP)
        XCTAssertEqual(fed.ledger?.key, LedgerKeys.care(fed.record.id))
        XCTAssertEqual(fed.ledger?.kind, .care)

        // Còn tốt: không thưởng, vẫn tăng chỉ số.
        let fine = try perform(.cuddle, needs: PetNeeds(fullness: 80, cleanliness: 80, happiness: 60, asOf: t0))
        XCTAssertEqual(fine.record.note, .notNeeded)
        XCTAssertNil(fine.ledger)
        XCTAssertEqual(fine.needs.happiness, 95, accuracy: 0.01)

        // Tối đa 2 lượt có thưởng mỗi loại mỗi ngày.
        var history = [fed.record]
        history.append(try perform(.feed, food: "food.apple", needs: hungry, history: history).record)
        let third = try perform(.feed, food: "food.apple", needs: hungry, history: history)
        XCTAssertEqual(third.record.note, .kindLimit)
        XCTAssertNil(third.ledger)

        // Tổng hạn mức: 2 lần dọn (6 XP, 4 xu) + 2 cho ăn (4 XP, 2 xu) = 10 XP, 6 xu → nựng chỉ còn 2 XP, 0 xu.
        history.append(try perform(.clean, needs: hungry, history: history).record)
        history.append(try perform(.clean, needs: hungry, history: history).record)
        let cuddle = try perform(.cuddle, needs: hungry, history: history)
        XCTAssertEqual(cuddle.record.xp, 2)
        XCTAssertEqual(cuddle.record.coins, 0)
        history.append(cuddle.record)
        let totals = CarePolicy.todayTotals(day: DayKey(t0, calendar: cal()), history: history)
        XCTAssertLessThanOrEqual(totals.xp, CareConfig.dailyXPCap)
        XCTAssertLessThanOrEqual(totals.coins, CareConfig.dailyCoinCap)
        let over = try perform(.cuddle, needs: hungry, history: history)
        XCTAssertEqual(over.record.note, .dailyLimit)

        // Sang ngày mới (qua nửa đêm): hạn mức mới.
        let tomorrow = date(2026, 10, 20, 0, 5)
        let fresh = try perform(.feed, food: "food.apple", needs: PetNeeds(fullness: 30, cleanliness: 90, happiness: 90, asOf: tomorrow),
                                history: history, at: tomorrow)
        XCTAssertEqual(fresh.record.note, .rewarded)
    }

    func testFeedingCapsAt100AndFullPetKeepsFood() throws {
        let nearlyFull = PetNeeds(fullness: 90, cleanliness: 90, happiness: 99, asOf: t0)
        let fed = try perform(.feed, food: "food.picnic", needs: nearlyFull)
        XCTAssertEqual(fed.needs.fullness, 100)
        XCTAssertEqual(fed.needs.happiness, 100)
        let full = PetNeeds(fullness: 96, cleanliness: 90, happiness: 90, asOf: t0)
        XCTAssertThrowsError(try perform(.feed, food: "food.apple", needs: full)) { XCTAssertEqual($0 as? CareError, .alreadyFull) }
        XCTAssertThrowsError(try perform(.feed, food: "food.unknown", needs: nearlyFull))
        XCTAssertThrowsError(try perform(.clean, needs: PetNeeds(fullness: 50, cleanliness: 97, happiness: 50, asOf: t0)))
    }

    func testFreeMealOnlyWhenHungryNoRewardNoStockpile() throws {
        let hungry = PetNeeds(fullness: 25, cleanliness: 90, happiness: 90, asOf: t0)
        let meal = try perform(.freeMeal, needs: hungry)
        XCTAssertEqual(meal.needs.fullness, CareConfig.freeMealTo)
        XCTAssertNil(meal.ledger)
        XCTAssertEqual(meal.record.note, .freeMeal)
        XCTAssertThrowsError(try perform(.freeMeal, needs: meal.needs)) { XCTAssertEqual($0 as? CareError, .notHungry) }
    }

    func testFoodPurchaseTransactionIDIsIdempotentAndChecksCoins() throws {
        let tx = UUID()
        let entry = try XCTUnwrap(FoodShopPolicy.purchase(foodID: "food.carrot", quantity: 2, transactionID: tx, coins: 10, stock: 0, existingKeys: [], now: t0))
        XCTAssertEqual(entry.coins, -6)
        XCTAssertEqual(entry.key, "food-purchase:\(tx.uuidString.lowercased())")
        XCTAssertNotEqual(entry.key, LedgerKeys.purchase("food.carrot"))
        XCTAssertNil(try FoodShopPolicy.purchase(foodID: "food.carrot", quantity: 2, transactionID: tx, coins: 10, stock: 2, existingKeys: [entry.key], now: t0))
        XCTAssertThrowsError(try FoodShopPolicy.purchase(foodID: "food.picnic", quantity: 1, transactionID: UUID(), coins: 24, stock: 0, existingKeys: [], now: t0))
        XCTAssertThrowsError(try FoodShopPolicy.purchase(foodID: "food.apple", quantity: 0, transactionID: UUID(), coins: 99, stock: 0, existingKeys: [], now: t0))
    }

    func testFoodCatalogBalanced() {
        XCTAssertEqual(FoodCatalog.all.count, 6)
        XCTAssertEqual(Set(FoodCatalog.all.map(\.id)).count, 6)
        // Món rẻ nhất đắt hơn thưởng cho ăn → không thể "mua rồi cho ăn" để kiếm xu.
        XCTAssertGreaterThan(FoodCatalog.all.map(\.price).min()!, CareConfig.feedCoins)
        for f in FoodCatalog.all { XCTAssertTrue(f.id.hasPrefix("food.")) }
    }

    func testCuddleNeedsRealStrokingTime() {
        var p = CuddleProgress()
        p.stroke(at: 0)
        p.stroke(at: 10) // một lần vuốt sau 10 giây: chỉ tính 0,25 giây
        XCTAssertEqual(p.seconds, CareConfig.cuddleMaxGap, accuracy: 0.0001)
        var completedAt: Double?
        var t = 10.0
        while completedAt == nil && t < 30 {
            t += 1.0 / 30
            if p.stroke(at: t) { completedAt = t }
        }
        let done = try? XCTUnwrap(completedAt)
        XCTAssertNotNil(done)
        XCTAssertEqual(done ?? 0, 10 + CareConfig.cuddleSeconds - CareConfig.cuddleMaxGap, accuracy: 0.05)
        XCTAssertFalse(p.stroke(at: t + 0.1), "chỉ báo hoàn thành một lần")
    }

    func testDirtSpotsDeterministicSeparatedAndVaried() {
        let a = CleanPlan.spots(count: 8, seed: 42)
        XCTAssertEqual(a.count, 8)
        XCTAssertEqual(a, CleanPlan.spots(count: 8, seed: 42))
        XCTAssertTrue(a.contains { $0.kind == .cobweb }, "có mạng nhện")
        XCTAssertTrue(a.contains { $0.kind == .stain }, "có vết bẩn")
        for (i, s) in a.enumerated() {
            if s.kind == .cobweb { XCTAssertLessThan(s.y, 0.25, "mạng nhện ở trên cao") }
            for t in a[(i + 1)...] { XCTAssertFalse(abs(s.x - t.x) < 0.12 && abs(s.y - t.y) < 0.1) }
        }
        for seed in UInt64(1)...50 {
            XCTAssertEqual(CleanPlan.spots(count: 6, seed: seed).count, 6, "seed \(seed)")
        }
        XCTAssertEqual(CleanPlan.visibleDust(cleanliness: 90), 0)
        XCTAssertGreaterThan(CleanPlan.visibleDust(cleanliness: 25), CleanPlan.visibleDust(cleanliness: 50))
    }

    /// Chà qua lại: đúng dụng cụ sạch sau vài lượt; sai dụng cụ chậm hơn; nhấc tay nhảy cóc không tính quãng lớn.
    func testRubbingCleansGraduallyWithRightToolFaster() {
        func scrub(_ work: inout CleanWork, tool: CleanTool, strokes: Int) {
            let s = work.spots[0]
            for k in 0..<strokes {
                let from = (x: s.x - 0.05, y: s.y), to = (x: s.x + 0.05, y: s.y)
                if k % 2 == 0 { work.rub(from: from, to: to, tool: tool) } else { work.rub(from: to, to: from, tool: tool) }
            }
        }
        let stain = DirtSpot(x: 0.5, y: 0.6, kind: .stain)
        var right = CleanWork(spots: [stain])
        scrub(&right, tool: .cloth, strokes: 4)
        XCTAssertFalse(right.isDone, "một hai lần chà chưa sạch ngay")
        XCTAssertGreaterThan(right.fraction, 0.2)
        scrub(&right, tool: .cloth, strokes: 8)
        XCTAssertTrue(right.isDone)

        var wrong = CleanWork(spots: [stain])
        scrub(&wrong, tool: .broom, strokes: 12)
        XCTAssertFalse(wrong.isDone, "dùng chổi lau vết bẩn vẫn được nhưng chậm hơn")
        XCTAssertGreaterThan(wrong.fraction, 0)

        var jump = CleanWork(spots: [DirtSpot(x: 0.5, y: 0.5, kind: .dust)])
        jump.rub(from: (x: 0, y: 0), to: (x: 0.5, y: 0.5), tool: .broom)
        XCTAssertFalse(jump.isDone, "kéo một phát từ xa không làm sạch ngay")

        var far = CleanWork(spots: [DirtSpot(x: 0.2, y: 0.2, kind: .dust)])
        far.rub(from: (x: 0.7, y: 0.8), to: (x: 0.8, y: 0.8), tool: .broom)
        XCTAssertEqual(far.fraction, 0, "chà chỗ khác không ảnh hưởng")

        var a11y = CleanWork(spots: CleanPlan.spots(count: 6, seed: 3))
        a11y.clear(0)
        XCTAssertEqual(a11y.cleanedCount, 1)
        a11y.clearAll()
        XCTAssertTrue(a11y.isDone)
    }
}

/// Vòng đời lượt chơi, quy đổi xu, hạn mức.
final class MinigameRuleTests: XCTestCase {
    private let t0 = date(2026, 10, 19, 20)

    func testSessionStateMachine() {
        var s = PlaySession()
        XCTAssertEqual(s.phase, .ready)
        s.finish()
        XCTAssertEqual(s.phase, .ready, "chưa chơi thì không kết thúc được")
        s.start(at: 10)
        XCTAssertEqual(s.countdownRemaining(at: 10), 3)
        s.tick(at: 12.9)
        XCTAssertFalse(s.isRunning)
        s.tick(at: 13)
        XCTAssertTrue(s.isRunning)
        s.pause()
        XCTAssertEqual(s.phase, .paused)
        s.resume(at: 100)
        XCTAssertFalse(s.isRunning, "tiếp tục luôn có đếm ngược")
        s.pause() // vào nền giữa đếm ngược
        XCTAssertEqual(s.phase, .paused)
        s.resume(at: 200)
        s.tick(at: 203)
        s.finish()
        XCTAssertEqual(s.phase, .finished)
        s.abandon()
        XCTAssertEqual(s.phase, .finished, "đã xong thì không thành bỏ dở")
        var other = PlaySession()
        other.start(at: 0)
        other.abandon()
        XCTAssertEqual(other.phase, .abandoned)
    }

    func testRunClockIgnoresPausedTime() {
        var c = RunClock()
        c.run(at: 100)
        c.stop(at: 130)
        XCTAssertEqual(c.elapsed(at: 500), 30)
        c.run(at: 500)
        XCTAssertEqual(c.elapsed(at: 510), 40)
        c.run(at: 505) // gọi thừa không reset
        XCTAssertEqual(c.elapsed(at: 510), 40)
        XCTAssertEqual(StepClock.substeps(for: 5).reduce(0, +), StepClock.maxFrame, accuracy: 1e-9)
        XCTAssertTrue(StepClock.substeps(for: 0).isEmpty)
    }

    private func outcome(_ kind: MinigameKind, score: Int, primary: Int, secondary: Int = 0, seconds: Double,
                         completed: Bool = true, level: MemoryLevel? = nil) -> MinigameOutcome {
        MinigameOutcome(sessionID: UUID(), kind: kind, score: score, primary: primary, secondary: secondary, level: level,
                        activeSeconds: seconds, completed: completed, species: "cat",
                        startedAt: t0.addingTimeInterval(-seconds), finishedAt: t0)
    }

    func testCoinConversionWithinLimits() {
        // Nhảy Mây: 45 m + 2 sao = 51 điểm → 3 xu.
        let jump = outcome(.cloudJump, score: CloudJumpEngine.score(heightMeters: 45, stars: 2), primary: 45, secondary: 2, seconds: 40)
        XCTAssertEqual(MinigamePolicy.coins(for: jump).0, 3)
        // Rất cao vẫn tối đa 6 xu/lượt.
        let huge = outcome(.cloudJump, score: CloudJumpEngine.score(heightMeters: 900, stars: 30), primary: 900, secondary: 30, seconds: 400)
        XCTAssertEqual(MinigamePolicy.coins(for: huge).0, MinigameConfig.maxCoinsPerRun)
        // Dưới ngưỡng: không xu.
        let short = outcome(.cloudJump, score: 10, primary: 10, seconds: 8)
        XCTAssertEqual(MinigamePolicy.coins(for: short).1, .belowThreshold)
        // Giỏ quà: thoát sớm (chưa hết 60 giây) không có xu.
        let early = outcome(.giftBasket, score: 80, primary: 40, seconds: 30, completed: false)
        XCTAssertEqual(MinigamePolicy.coins(for: early).1, .notCompleted)
        let basket = outcome(.giftBasket, score: 70, primary: 40, secondary: 12, seconds: 60)
        XCTAssertEqual(MinigamePolicy.coins(for: basket).0, 3)
        // Lật thẻ chưa xong bàn: không xu.
        let unfinished = outcome(.memoryMatch, score: 0, primary: 5, secondary: 3, seconds: 20, completed: false, level: .easy)
        XCTAssertEqual(MinigamePolicy.coins(for: unfinished).1, .notCompleted)
        let perfect = outcome(.memoryMatch, score: 560, primary: 6, secondary: 6, seconds: 30, level: .easy)
        XCTAssertEqual(MinigamePolicy.coins(for: perfect).0, 5)
        let slow = outcome(.memoryMatch, score: 100, primary: 20, secondary: 8, seconds: 200, level: .medium)
        XCTAssertEqual(MinigamePolicy.coins(for: slow).0, 3)
    }

    func testImplausibleResultsGetNothing() {
        // Leo 300 m trong 10 giây là không thể.
        let cheat = outcome(.cloudJump, score: 300, primary: 300, seconds: 10)
        XCTAssertEqual(MinigamePolicy.coins(for: cheat).1, .implausible)
        // Điểm không khớp độ cao + sao.
        let mismatch = outcome(.cloudJump, score: 999, primary: 40, seconds: 60)
        XCTAssertEqual(MinigamePolicy.coins(for: mismatch).1, .implausible)
        let fastMemory = outcome(.memoryMatch, score: 600, primary: 6, secondary: 6, seconds: 1, level: .easy)
        XCTAssertEqual(MinigamePolicy.coins(for: fastMemory).1, .implausible)
        let basket = outcome(.giftBasket, score: 5000, primary: 60, seconds: 60)
        XCTAssertEqual(MinigamePolicy.coins(for: basket).1, .implausible)
    }

    func testDailyCapPartialAndReached() {
        let o = outcome(.giftBasket, score: 120, primary: 60, seconds: 60) // 6 xu
        XCTAssertEqual(MinigamePolicy.reward(for: o, awardedToday: 0), MinigameReward(coins: 6, earned: 6, note: .rewarded))
        XCTAssertEqual(MinigamePolicy.reward(for: o, awardedToday: MinigameConfig.dailyCoinCap - 4),
                       MinigameReward(coins: 4, earned: 6, note: .partialCap))
        XCTAssertEqual(MinigamePolicy.reward(for: o, awardedToday: MinigameConfig.dailyCoinCap),
                       MinigameReward(coins: 0, earned: 6, note: .dailyCapReached))
    }

    func testBestAndRetention() {
        func rec(_ kind: MinigameKind, _ score: Int, daysAgo: Int) -> MinigameResultRecord {
            let when = t0.addingTimeInterval(Double(-daysAgo) * 86400)
            return MinigameResultRecord(id: UUID(), kind: kind, score: score, primary: score, secondary: 0, level: nil,
                                        activeSeconds: 30, species: "cat", startedAt: when, finishedAt: when,
                                        day: DayKey(when, calendar: cal()), coins: 0, earned: 0, note: .belowThreshold)
        }
        let old = rec(.cloudJump, 500, daysAgo: 400)
        var all = [old]
        for i in 1...250 { all.append(rec(.cloudJump, i, daysAgo: i)) }
        XCTAssertEqual(MinigamePolicy.best(.cloudJump, results: all)?.id, old.id)
        let kept = MinigamePolicy.retained(all, since: t0.addingTimeInterval(-3 * 86400), keep: 200)
        XCTAssertTrue(kept.contains(old.id), "kỷ lục luôn được giữ")
        XCTAssertEqual(kept.count, 201)
    }
}

/// Logic ba minigame.
final class MinigameEngineTests: XCTestCase {
    // MARK: Nhảy Mây

    func testJumpBouncingInPlaceDoesNotIncreaseScore() {
        var e = CloudJumpEngine(seed: 1, layout: [JumpPlatform(id: 0, x: 50, y: 0, width: 100)])
        var bounces = 0
        for _ in 0..<(60 * 20) {
            bounces += e.step(1.0 / 60).filter { if case .bounce = $0 { return true } else { return false } }.count
        }
        XCTAssertGreaterThan(bounces, 10, "tự nảy liên tục")
        XCTAssertEqual(e.score, 0)
        XCTAssertFalse(e.isOver)
    }

    func testJumpOnlyLandsWhenFallingThroughTop() {
        // Bệ ở độ cao 20 ngay trên đầu: lúc đi lên xuyên qua, không đáp; chỉ đáp khi rơi xuống.
        var e = CloudJumpEngine(seed: 1, layout: [JumpPlatform(id: 0, x: 50, y: 0, width: 100),
                                                   JumpPlatform(id: 7, x: 50, y: 20, width: 30)])
        var landedOn: [Int] = []
        var velAtLanding: [Double] = []
        var previousVel = e.velY
        for _ in 0..<(60 * 3) {
            for ev in e.step(1.0 / 60) { if case .bounce(let id) = ev { landedOn.append(id); velAtLanding.append(previousVel) } }
            previousVel = e.velY
        }
        XCTAssertEqual(landedOn.first, 7, "lần đầu chạm là lúc rơi xuống bệ 7, không phải lúc đi lên")
        XCTAssertTrue(landedOn.allSatisfy { $0 == 7 })
        XCTAssertTrue(velAtLanding.allSatisfy { $0 < 0 })
        XCTAssertEqual(e.heightMeters, 2)

        // Đi ngang lệch khỏi bệ: không chạm cạnh để nảy lại.
        var side = CloudJumpEngine(seed: 1, layout: [JumpPlatform(id: 0, x: 50, y: 0, width: 10)])
        side.setTarget(x: 95)
        var fell = false
        for _ in 0..<(60 * 5) where !fell { fell = side.step(1.0 / 60).contains(.fell) }
        XCTAssertTrue(fell)
        XCTAssertEqual(side.landings, 0)
    }

    func testGeneratedPlatformsAreReachableAndBounded() {
        for seed in UInt64(1)...30 {
            var e = CloudJumpEngine(seed: seed)
            var all: [Int: JumpPlatform] = [:]
            var hazards: [Int: JumpHazard] = [:]
            // Đẩy camera lên bằng một bot (xem test bên dưới) không cần thiết: chỉ kiểm tra bộ sinh.
            var bot = JumpBot()
            for _ in 0..<(60 * 240) where !e.isOver {
                bot.drive(&e)
                e.step(1.0 / 60)
                for p in e.platforms { all[p.id] = p }
                for h in e.hazards { hazards[h.id] = h }
                XCTAssertLessThanOrEqual(e.hazards.count, CloudJumpEngine.maxHazards)
                XCTAssertLessThanOrEqual(e.platforms.count, CloudJumpEngine.maxPlatforms)
                XCTAssertLessThanOrEqual(e.stars.count, CloudJumpEngine.maxStars)
            }
            let sorted = all.values.sorted { $0.y < $1.y }
            for (a, b) in zip(sorted, sorted.dropFirst()) {
                let dy = b.y - a.y
                XCTAssertLessThanOrEqual(dy, CloudJumpEngine.maxGap + 1e-9)
                XCTAssertLessThan(dy, CloudJumpEngine.apex * 0.8)
                XCTAssertLessThanOrEqual(abs(b.baseX - a.baseX) + b.amplitude,
                                         max(4, CloudJumpEngine.reach(dy: dy) * CloudJumpEngine.reachSafety) + 1e-6,
                                         "seed \(seed): bệ \(b.id) quá xa")
                XCTAssertGreaterThanOrEqual(b.baseX - b.amplitude - b.width / 2, 0)
                XCTAssertLessThanOrEqual(b.baseX + b.amplitude + b.width / 2, CloudJumpEngine.worldWidth)
                XCTAssertFalse(a.fragile && b.fragile, "seed \(seed): hai mây mỏng liền nhau")
            }
            // Chướng ngại không bao giờ chạm vùng của mây ngay bên dưới (đứng nảy tại chỗ luôn an toàn).
            XCTAssertFalse(hazards.isEmpty, "seed \(seed): phải có chướng ngại")
            for h in hazards.values {
                guard let i = sorted.lastIndex(where: { $0.y < h.y }), i > 0 else { continue }
                for p in [sorted[i], sorted[i - 1]] {
                    let half = p.width / 2 + p.amplitude
                    let gap = abs(h.baseX - p.baseX) - half - h.amplitude - h.radius - CloudJumpEngine.footHalfWidth
                    XCTAssertGreaterThan(gap, 0, "seed \(seed): \(h.kind) \(h.id) đè lên vùng bệ \(p.id)")
                }
                if h.kind == .bird { XCTAssertFalse(sorted[i].fragile, "seed \(seed): chim trên mây mỏng") }
                XCTAssertGreaterThanOrEqual(h.baseX - h.amplitude, 0)
                XCTAssertLessThanOrEqual(h.baseX + h.amplitude, CloudJumpEngine.worldWidth)
            }
        }
    }

    func testHazardKnocksDownOnceAndFragileCloudBreaks() {
        let layout = [JumpPlatform(id: 0, x: 50, y: 0, width: 100), JumpPlatform(id: 1, x: 50, y: 25, width: 30, fragile: true)]
        var e = CloudJumpEngine(seed: 1, layout: layout,
                                hazards: [JumpHazard(id: 9, kind: .storm, baseX: 50, y: 30, amplitude: 0, speed: 0, phase: 0)])
        var events: [JumpEvent] = []
        for _ in 0..<(60 * 3) { events += e.step(1.0 / 60) }
        XCTAssertEqual(events.filter { $0 == .hit(.storm) }.count, 1, "chạm một lần rồi mây giông bay đi")
        XCTAssertEqual(e.hits, 1)
        XCTAssertTrue(e.hazards.isEmpty)
        XCTAssertTrue(events.contains(.broke(platformID: 1)), "mây mỏng tan sau một lần nảy")
        XCTAssertFalse(e.platforms.contains { $0.id == 1 })
        XCTAssertFalse(e.isOver, "bị chặn không mất lượt — rơi về mây bên dưới")
    }

    func testBotCanAlwaysClimb() {
        // Một người chơi "máy" chỉ nhắm vào bệ kế tiếp phải leo được rất cao với mọi seed:
        // chứng minh không có khoảng cách bất khả thi.
        for seed in UInt64(100)...130 {
            var e = CloudJumpEngine(seed: seed)
            var bot = JumpBot()
            for _ in 0..<(60 * 180) where !e.isOver {
                bot.drive(&e)
                e.step(1.0 / 60)
            }
            XCTAssertFalse(e.isOver, "seed \(seed): bot rơi ở \(e.heightMeters) m")
            XCTAssertGreaterThan(e.heightMeters, 200, "seed \(seed)")
            XCTAssertGreaterThan(e.difficulty, 0.4)
        }
    }

    func testJumpStarsCountOnce() {
        var e = CloudJumpEngine(seed: 9)
        var bot = JumpBot()
        var starEvents = 0
        for _ in 0..<(60 * 120) where !e.isOver {
            bot.drive(&e)
            starEvents += e.step(1.0 / 60).filter { $0 == .star }.count
        }
        XCTAssertEqual(starEvents, e.starsCollected)
        XCTAssertEqual(e.score, e.heightMeters + e.starsCollected * CloudJumpEngine.pointsPerStar)
    }

    // MARK: Giỏ Quà

    func testBasketCatchesEachItemOnceAndBadNeverNegative() {
        var e = GiftBasketEngine(seed: 1, spawns: false)
        e.inject(.gift, x: 50, y: 40, speed: 60)
        e.inject(.mud, x: 52, y: 80, speed: 60)
        var events: [BasketEvent] = []
        for _ in 0..<(60 * 3) { events += e.step(1.0 / 60) }
        XCTAssertEqual(events.filter { if case .caught = $0 { return true } else { return false } }.count, 1)
        XCTAssertEqual(e.score, 2, "5 điểm quà − 3 điểm bùn")
        XCTAssertEqual(e.combo, 0)
        var poor = GiftBasketEngine(seed: 1, spawns: false)
        poor.inject(.rain, x: 50, y: 40, speed: 60)
        for _ in 0..<(60 * 2) { poor.step(1.0 / 60) }
        XCTAssertEqual(poor.score, 0)
        XCTAssertEqual(poor.caughtBad, 1)
        // Món rơi ngoài giỏ: chỉ mất cơ hội.
        var miss = GiftBasketEngine(seed: 1, spawns: false)
        miss.inject(.apple, x: 95, y: 40, speed: 60)
        for _ in 0..<(60 * 2) { miss.step(1.0 / 60) }
        XCTAssertEqual(miss.missedGood, 1)
        XCTAssertEqual(miss.score, 0)
    }

    func testBasketEndsExactlyAt60SecondsAndNoPointsAfter() {
        var e = GiftBasketEngine(seed: 5)
        var finished = 0
        var frames = 0
        // Bot đơn giản: theo món tốt thấp nhất.
        while frames < 60 * 70 {
            if let target = e.items.filter({ $0.kind.isGood }).min(by: { $0.y < $1.y }) { e.setTarget(x: target.x) }
            finished += e.step(1.0 / 60).filter { $0 == .finished }.count
            frames += 1
        }
        XCTAssertEqual(finished, 1)
        XCTAssertTrue(e.isOver)
        XCTAssertEqual(e.time, GiftBasketEngine.duration, accuracy: 1e-9)
        let score = e.score
        XCTAssertTrue(e.step(1).isEmpty)
        XCTAssertEqual(e.score, score)
        XCTAssertGreaterThan(score, MinigameConfig.basketMinScore, "bot chơi tốt phải có xu")
        XCTAssertLessThanOrEqual(Double(score), MinigameConfig.basketMaxPointsPerSecond * 60)
        XCTAssertLessThanOrEqual(e.items.count, GiftBasketEngine.maxItems)
    }

    func testBasketPauseMeansNoTime() {
        var e = GiftBasketEngine(seed: 3)
        for _ in 0..<60 { e.step(1.0 / 60) }
        let snapshot = (e.time, e.items.count, e.spawned)
        // Tạm dừng = lớp giao diện không gọi step. Một khung hình khựng 5 giây chỉ tính 0,1 giây.
        e.step(5)
        XCTAssertEqual(e.time, snapshot.0 + StepClock.maxFrame, accuracy: 1e-9)
    }

    func testBasketSameSeedSameGame() {
        var a = GiftBasketEngine(seed: 77), b = GiftBasketEngine(seed: 77)
        for _ in 0..<(60 * 10) { a.step(1.0 / 60); b.step(1.0 / 60) }
        XCTAssertEqual(a.items, b.items)
    }

    // MARK: Lật thẻ

    func testMemoryBoardHasPairsAndIsSeeded() {
        for level in MemoryLevel.allCases {
            let b = MemoryBoard(level: level, seed: 11)
            XCTAssertEqual(b.cards.count, level.pairs * 2)
            XCTAssertEqual(b.cards.count, level.columns * level.rows)
            let counts = Dictionary(grouping: b.cards, by: \.face).mapValues(\.count)
            XCTAssertEqual(counts.count, level.pairs)
            XCTAssertTrue(counts.values.allSatisfy { $0 == 2 })
            XCTAssertEqual(b.cards.map(\.face), MemoryBoard(level: level, seed: 11).cards.map(\.face))
        }
        XCTAssertNotEqual(MemoryBoard(level: .medium, seed: 1).cards.map(\.face), MemoryBoard(level: .medium, seed: 2).cards.map(\.face))
    }

    func testMemoryNeverMoreThanTwoOpenAndLocksDuringMismatch() {
        var b = MemoryBoard(level: .easy, seed: 3)
        let first = 0
        let other = b.cards.indices.first { b.cards[$0].face != b.cards[first].face }!
        let third = b.cards.indices.first { $0 != first && $0 != other && b.cards[$0].face != b.cards[first].face }!
        XCTAssertEqual(b.flip(first), .opened)
        XCTAssertEqual(b.flip(first), .ignored, "chạm lại thẻ đang mở")
        guard case .mismatch(let token) = b.flip(other) else { return XCTFail("phải là cặp sai") }
        XCTAssertTrue(b.isLocked)
        XCTAssertEqual(b.flip(third), .ignored, "đang khóa: không mở thẻ thứ ba")
        XCTAssertLessThanOrEqual(b.openUnmatched.count, 2)
        XCTAssertFalse(b.resolveMismatch(token: token + 99), "mã cũ/sai bị bỏ qua")
        XCTAssertTrue(b.resolveMismatch(token: token))
        XCTAssertFalse(b.resolveMismatch(token: token), "úp hai lần không sao")
        XCTAssertEqual(b.openUnmatched.count, 0)
        XCTAssertEqual(b.moves, 1)
    }

    func testMemoryStaleCallbackDoesNotBreakNewMismatch() {
        var b = MemoryBoard(level: .medium, seed: 8)
        func mismatchPair() -> (Int, Int) {
            let downs = b.cards.indices.filter { b.cards[$0].state == .down }
            let a = downs[0]
            let c = downs.first { b.cards[$0].face != b.cards[a].face }!
            return (a, c)
        }
        let (a1, b1) = mismatchPair()
        _ = b.flip(a1)
        guard case .mismatch(let t1) = b.flip(b1) else { return XCTFail() }
        b.resolveMismatch(token: t1)
        let (a2, b2) = mismatchPair()
        _ = b.flip(a2)
        guard case .mismatch(let t2) = b.flip(b2) else { return XCTFail() }
        // Lệnh úp trễ của lần trước tới muộn: không được úp cặp mới.
        XCTAssertFalse(b.resolveMismatch(token: t1))
        XCTAssertTrue(b.isLocked)
        XCTAssertTrue(b.resolveMismatch(token: t2))
    }

    func testMemoryCompletesWithPerfectPlay() {
        var b = MemoryBoard(level: .easy, seed: 21)
        var last: FlipResult = .ignored
        for face in Set(b.cards.map(\.face)) {
            let idx = b.cards.indices.filter { b.cards[$0].face == face }
            _ = b.flip(idx[0])
            last = b.flip(idx[1])
        }
        XCTAssertEqual(last, .completed)
        XCTAssertTrue(b.isComplete)
        XCTAssertEqual(b.moves, 6)
        XCTAssertEqual(b.flip(0), .ignored)
        XCTAssertEqual(MemoryBoard.score(level: .easy, moves: 6, seconds: 20), 580)
        XCTAssertEqual(MemoryBoard.score(level: .easy, moves: 200, seconds: 900), 60)
    }
}

/// Người chơi máy cho Nhảy Mây: nhắm vào bệ thấp nhất cao hơn bệ vừa đáp. Mỗi lần nảy lên, đoán xem chim
/// có cắt ngang đường bay không — nếu có thì nảy tại chỗ chờ lượt sau (như người chơi thật).
struct JumpBot {
    private var standing = 0.0
    private var waitingOn: Int?

    mutating func drive(_ e: inout CloudJumpEngine) {
        if e.velY > CloudJumpEngine.jumpSpeed - 5 {
            standing = e.petY
            let here = e.platforms.first { abs($0.y - standing) < 0.01 }
            let next = e.platforms.filter { $0.y > standing + 1 }.min { $0.y < $1.y }
            if let next, let here, !here.fragile, Self.birdInTheWay(e, from: e.petX, to: next, standing: standing) {
                waitingOn = here.id
            } else {
                waitingOn = nil
            }
        }
        if let id = waitingOn, let p = e.platforms.first(where: { $0.id == id }) {
            e.setTarget(x: p.x(at: e.time))
            return
        }
        // Đang rơi dưới mức bệ vừa đáp (bị chim / mây giông chặn): lái về mây cao nhất bên dưới chân.
        if e.velY < 0, e.petY < standing + 1,
           let below = e.platforms.filter({ $0.y <= e.petY }).max(by: { $0.y < $1.y }) {
            e.setTarget(x: below.x(at: e.time))
            return
        }
        let next = e.platforms.filter { $0.y > standing + 1 }.min { $0.y < $1.y }
        if let next { e.setTarget(x: next.x(at: e.time)) }
    }

    /// Mô phỏng đường bay tới bệ kế tiếp và kiểm tra khoảng cách tới mọi con chim theo thời gian.
    static func birdInTheWay(_ e: CloudJumpEngine, from x0: Double, to next: JumpPlatform, standing: Double) -> Bool {
        let birds = e.hazards.filter { $0.kind == .bird && $0.y > standing - 2 && $0.y < next.y + CloudJumpEngine.bodyHeight + 6 }
        guard !birds.isEmpty else { return false }
        var x = x0, y = standing, v = CloudJumpEngine.jumpSpeed, t = 0.0
        let dt = 1.0 / 60
        while t < 2.5 {
            t += dt
            let target = next.x(at: e.time + t)
            x += max(-CloudJumpEngine.maxSpeedX * dt, min(CloudJumpEngine.maxSpeedX * dt, target - x))
            v -= CloudJumpEngine.gravity * dt
            y += v * dt
            for b in birds {
                let dx = x - b.x(at: e.time + t), dy = y + CloudJumpEngine.bodyHeight / 2 - b.y
                if (dx * dx + dy * dy).squareRoot() < b.radius + CloudJumpEngine.footHalfWidth + 4 { return true }
            }
            if v < 0 && y <= next.y { break }
        }
        return false
    }
}
