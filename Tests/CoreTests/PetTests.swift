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

    // MARK: Câu chuyện phiêu lưu — nội dung mở rộng

    private func sentenceCount(_ text: String) -> Int {
        text.split(whereSeparator: { ".!?".contains($0) })
            .filter { $0.contains(where: { $0.isLetter }) }
            .count
    }

    func testAdventureStoryDeterministicPerDayAndSpecies() {
        let d = day("2026-03-07")
        for s in PetSpecies.allCases {
            XCTAssertEqual(Adventure.story(for: d, petName: "Mây", species: s),
                           Adventure.story(for: d, petName: "Mây", species: s))
        }
        XCTAssertEqual(Adventure.story(for: d, petName: "Mây"), Adventure.story(for: d, petName: "Mây", species: .cat),
                       "mặc định là mèo")
        XCTAssertEqual(Adventure.story(for: d, petName: "").text.hasPrefix(ProfileRecord.defaultPetName + " "), true)
    }

    func testAdventureStoriesValidForEverySpeciesAcrossManyDays() {
        let start = day("2026-01-01")
        for s in PetSpecies.allCases {
            for i in 0..<400 {
                let d = start.adding(days: i, calendar: cal())
                let st = Adventure.story(for: d, petName: "Mochi", species: s)
                XCTAssertFalse(st.title.isEmpty)
                XCTAssertLessThanOrEqual(st.title.count, 42, "tiêu đề ngắn: \(st.title)")
                XCTAssertFalse(st.keepsake.isEmpty)
                XCTAssertTrue(st.keepsake.hasPrefix("một ") || st.keepsake.hasPrefix("vài "), st.keepsake)
                XCTAssertTrue(st.text.hasPrefix("Mochi "), st.text)
                XCTAssertTrue(st.text.contains(st.keepsake), "kỷ vật phải xuất hiện trong truyện: \(st.text)")
                XCTAssertFalse(st.text.contains("  "))
                XCTAssertFalse(st.text.contains("{n}"))
                XCTAssertTrue((3...5).contains(sentenceCount(st.text)), "3–5 câu: \(st.text)")
            }
        }
    }

    func testAdventureHasVarietyAndSpeciesAndSeasonFlavor() {
        let start = day("2026-10-18")
        let days = (0..<60).map { start.adding(days: $0, calendar: cal()) }
        let titles = Set(days.map { Adventure.story(for: $0, petName: "B").title })
        XCTAssertGreaterThanOrEqual(titles.count, 40, "60 ngày nên có nhiều tiêu đề khác nhau")
        let year = (0..<366).map { day("2026-01-01").adding(days: $0, calendar: cal()) }
        let capy = year.map { Adventure.story(for: $0, petName: "B", species: .capybara).text }
        XCTAssertTrue(capy.contains { $0.contains("suối nước nóng") })
        let duck = year.map { Adventure.story(for: $0, petName: "B", species: .duck).text }
        XCTAssertTrue(duck.contains { $0.contains("quạc") })
        XCTAssertTrue(year.contains { Adventure.story(for: $0, petName: "B", species: .cat)
            != Adventure.story(for: $0, petName: "B", species: .panda) })
        XCTAssertEqual(Adventure.Season.of(month: 3), .spring)
        XCTAssertEqual(Adventure.Season.of(month: 6), .summer)
        XCTAssertEqual(Adventure.Season.of(month: 9), .autumn)
        XCTAssertEqual(Adventure.Season.of(month: 12), .winter)
        XCTAssertEqual(Adventure.Season.of(month: 1), .winter)
        let autumn = year.filter { $0.month == 9 }.map { Adventure.story(for: $0, petName: "B").text }.joined()
        let spring = year.filter { $0.month == 3 }.map { Adventure.story(for: $0, petName: "B").text }.joined()
        XCTAssertNotEqual(autumn, spring)
    }

    func testDialogueSpeciesLinesKeepOldBehaviour() {
        let ctx = PetDialogue.Context(minuteOfDay: 20 * 60, tasksDone: 0, tasksTotal: 0, wroteJournal: false,
                                      focusRunning: false, adventureReady: false, streak: 0, userName: "")
        XCTAssertEqual(PetDialogue.lines(for: ctx), PetDialogue.lines(for: ctx, species: .cat))
        for s in PetSpecies.allCases {
            let lines = PetDialogue.lines(for: ctx, species: s)
            XCTAssertGreaterThanOrEqual(lines.count, 10)
            XCTAssertTrue(lines.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
            XCTAssertEqual(PetDialogue.line(for: ctx, tap: lines.count, species: s), lines[0])
        }
        XCTAssertTrue(PetDialogue.lines(for: ctx, species: .puppy).contains { $0.contains("Gâu") })
    }

    func testReactionsNonEmptyShortAndDeterministic() {
        for r in PetReaction.allCases {
            for s in PetSpecies.allCases {
                let pool = PetDialogue.reactionLines(r, petName: "Bông", species: s)
                XCTAssertGreaterThanOrEqual(pool.count, 12)
                XCTAssertEqual(Set(pool).count, pool.count, "không trùng câu")
                for seed in -3..<(pool.count + 3) {
                    let line = PetDialogue.reaction(r, petName: "Bông", species: s, seed: seed)
                    XCTAssertFalse(line.trimmingCharacters(in: .whitespaces).isEmpty)
                    XCTAssertLessThanOrEqual(line.count, 40, line)
                    XCTAssertEqual(line, PetDialogue.reaction(r, petName: "Bông", species: s, seed: seed))
                }
                XCTAssertNotEqual(PetDialogue.reaction(r, petName: "Bông", species: s, seed: 0),
                                  PetDialogue.reaction(r, petName: "Bông", species: s, seed: 1))
            }
        }
        XCTAssertFalse(PetDialogue.reaction(.petted, petName: "", seed: Int.min).isEmpty)
        let catPetted = PetDialogue.reactionLines(.petted, petName: "Bông", species: .cat)
        XCTAssertTrue(catPetted.contains("Gừ gừ… sướng quá!"))
        XCTAssertTrue(PetDialogue.reactionLines(.pickedUp, petName: "Bông").contains("Ơ, bay lên rồi!"))
        XCTAssertTrue(PetDialogue.reactionLines(.dropped, petName: "Bông").contains("Chỗ này cũng xinh nè!"))
        XCTAssertTrue(PetDialogue.reactionLines(.petted, petName: "B", species: .frog).contains { $0.contains("Ộp") })
    }

    func testZZDumpSamples() throws {
        var out = ""
        let start = day("2026-01-01")
        for i in stride(from: 0, to: 366, by: 7) {
            let d = start.adding(days: i, calendar: cal())
            let s = Adventure.story(for: d, petName: "Bông", species: PetSpecies.allCases[i % 11])
            out += "\(d) [\(PetSpecies.allCases[i % 11])] \(s.title)\n  \(s.text)\n"
        }
        let t = Set((0..<60).map { Adventure.story(for: day("2026-10-18").adding(days: $0, calendar: cal()), petName: "B").title }).count
        out += "titles60=\(t)\n"
        try out.write(toFile: "/work/cozyday/samples.txt", atomically: true, encoding: .utf8)
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
