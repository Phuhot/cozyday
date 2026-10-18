import XCTest
#if canImport(CozyCore)
@testable import CozyCore
#else
@testable import Cozyday
#endif

final class PetTests: XCTestCase {
    private func income(_ coins: Int, xp: Int) -> LedgerEntry {
        LedgerEntry(id: UUID(), key: "task:\(UUID())", kind: .taskCompleted, xp: xp, coins: coins, createdAt: Date(), refID: nil, memo: "")
    }

    func testLevelLockedItemNeedsLevelEvenWithEnoughCoins() {
        let ledger = [income(500, xp: 150)] // cấp 2
        XCTAssertEqual(
            PurchasePolicy.decide(itemID: "species.fox", owned: [], ledger: ledger, now: Date()),
            .levelLocked(required: 6, current: 2)
        )
        guard case .approved = PurchasePolicy.decide(itemID: "species.bunny", owned: [], ledger: ledger, now: Date()) else {
            return XCTFail("thỏ mở ở cấp 2")
        }
    }

    func testDefaultItemsAreAlwaysOwned() {
        XCTAssertEqual(PurchasePolicy.decide(itemID: "species.cat", owned: [], ledger: [], now: Date()), .alreadyOwned)
        XCTAssertEqual(PurchasePolicy.decide(itemID: "fur.cream", owned: [], ledger: [], now: Date()), .alreadyOwned)
        XCTAssertTrue(Catalog.isOwned("fur.cream", owned: []))
        XCTAssertFalse(Catalog.isOwned("fur.snow", owned: []))
    }

    func testAppearanceFromEquippedIgnoresWrongSlotAndUnknownIDs() {
        let a = PetAppearance(equipped: [.species: "species.fox", .fur: "fur.midnight", .hat: "hat.crown", .neck: "hat.bow", .glasses: "glasses.nope"], level: 12)
        XCTAssertEqual(a.species, .fox)
        XCTAssertEqual(a.fur, .midnight)
        XCTAssertEqual(a.hat, "hat.crown")
        XCTAssertNil(a.neck)
        XCTAssertNil(a.glasses)
        XCTAssertEqual(a.stage, .grown)
        XCTAssertEqual(PetAppearance(equipped: [:], level: 1), PetAppearance(stage: .little))
    }

    func testTryOnAndRemoveDoNotTouchOtherLayers() {
        let base = PetAppearance(equipped: [.hat: "hat.beanie"], level: 5)
        let tried = base.trying(Catalog.item("species.bear")!).trying(Catalog.item("neck.scarf")!)
        XCTAssertEqual(tried.species, .bear)
        XCTAssertEqual(tried.hat, "hat.beanie")
        XCTAssertEqual(tried.neck, "neck.scarf")
        XCTAssertEqual(tried.removing(.species).species, .cat)
        XCTAssertNil(tried.removing(.hat).hat)
        XCTAssertEqual(tried.itemID(in: .species), "species.bear")
    }

    func testStageThresholds() {
        XCTAssertEqual(PetStage.forLevel(1), .little)
        XCTAssertEqual(PetStage.forLevel(3), .little)
        XCTAssertEqual(PetStage.forLevel(4), .growing)
        XCTAssertEqual(PetStage.forLevel(10), .grown)
        XCTAssertEqual(PetStage.forLevel(99), .grown)
    }

    func testAdventureEnergyCountsTodayActivitiesOnly() {
        let c = cal()
        let today = day("2026-10-18")
        let todayNoon = today.date(atMinute: 12 * 60, in: c)
        let yesterday = today.adding(days: -1, calendar: c).date(atMinute: 12 * 60, in: c)
        func entry(_ kind: LedgerKind, _ at: Date) -> LedgerEntry {
            LedgerEntry(id: UUID(), key: UUID().uuidString, kind: kind, xp: 1, coins: 1, createdAt: at, refID: nil, memo: "")
        }
        var ledger = [entry(.taskCompleted, todayNoon), entry(.purchase, todayNoon), entry(.taskCompleted, yesterday)]
        XCTAssertEqual(Adventure.energy(on: today, ledger: ledger, calendar: c), 25)
        ledger += [entry(.focusCompleted, todayNoon), entry(.journalWritten, todayNoon)]
        XCTAssertFalse(Adventure.isReady(on: today, ledger: ledger, calendar: c))
        ledger += [entry(.breathing, todayNoon), entry(.taskCompleted, todayNoon)]
        XCTAssertEqual(Adventure.energy(on: today, ledger: ledger, calendar: c), 100)
        XCTAssertTrue(Adventure.isReady(on: today, ledger: ledger, calendar: c))
    }

    func testAdventureStoryIsStablePerDayAndRewardOnce() {
        let d = day("2026-10-18")
        XCTAssertEqual(Adventure.story(for: d, petName: "Bông"), Adventure.story(for: d, petName: "Bông"))
        XCTAssertTrue(Adventure.story(for: d, petName: "Bông").text.hasPrefix("Bông "))
        let stories = Set((0..<30).map { Adventure.story(for: d.adding(days: $0, calendar: cal()), petName: "B").text })
        XCTAssertGreaterThan(stories.count, 20, "các ngày khác nhau nên ra câu chuyện khác nhau")
        let first = Adventure.reward(day: d, existingKeys: [], petName: "Bông", now: Date())!
        XCTAssertEqual(first.kind, .adventure)
        XCTAssertNil(Adventure.reward(day: d, existingKeys: [first.key], petName: "Bông", now: Date()))
        XCTAssertEqual(Adventure.stableHash("abc"), 0xe71fa2190541574b)
    }

    func testBreathingRewardOncePerDay() {
        let d = day("2026-10-18")
        let first = RewardPolicy.forBreathing(day: d, existingKeys: [], now: Date())!
        XCTAssertNil(RewardPolicy.forBreathing(day: d, existingKeys: [first.key], now: Date()))
    }

    func testDialogueAlwaysHasALineAndRotates() {
        let ctx = PetDialogue.Context(minuteOfDay: 9 * 60, tasksDone: 1, tasksTotal: 3, wroteJournal: false,
                                      focusRunning: false, adventureReady: true, streak: 4, userName: "An")
        let lines = PetDialogue.lines(for: ctx)
        XCTAssertTrue(lines.contains { $0.contains("1/3") })
        XCTAssertTrue(lines.first!.contains("năng lượng"))
        XCTAssertNotEqual(PetDialogue.line(for: ctx, tap: 0), PetDialogue.line(for: ctx, tap: 1))
        XCTAssertEqual(PetDialogue.line(for: ctx, tap: -1), lines.last)
        var night = ctx
        night.minuteOfDay = 2 * 60
        night.focusRunning = true
        XCTAssertTrue(PetDialogue.lines(for: night).allSatisfy { !$0.isEmpty })
    }
}

final class BreathingTests: XCTestCase {
    func testPhaseAndExpansionFollowPattern() {
        let box = BreathingPattern.box
        XCTAssertEqual(box.cycleSeconds, 16)
        XCTAssertEqual(box.phase(at: 1).phase.kind, .inhale)
        XCTAssertEqual(box.phase(at: 5).phase.kind, .hold)
        XCTAssertEqual(box.phase(at: 9).phase.kind, .exhale)
        XCTAssertEqual(box.phase(at: 13).phase.kind, .rest)
        XCTAssertEqual(box.phase(at: 17).phase.kind, .inhale, "lặp lại sau mỗi chu kỳ")
        XCTAssertEqual(box.expansion(at: 2), 0.5, accuracy: 0.001)
        XCTAssertEqual(box.expansion(at: 6), 1)
        XCTAssertEqual(box.expansion(at: 10), 0.5, accuracy: 0.001)
        XCTAssertEqual(BreathingPattern.sleepy.phase(at: 10).phase.kind, .hold)
        XCTAssertEqual(BreathingPattern.calm.expansion(at: -3), 0)
    }

    func testJournalPromptStablePerDayAndShifts() {
        let d = day("2026-10-18")
        XCTAssertEqual(JournalPrompts.prompt(for: d), JournalPrompts.prompt(for: d))
        XCTAssertNotEqual(JournalPrompts.prompt(for: d), JournalPrompts.prompt(for: d, shift: 1))
        XCTAssertEqual(JournalPrompts.prompt(for: d, shift: JournalPrompts.all.count), JournalPrompts.prompt(for: d))
    }
}
