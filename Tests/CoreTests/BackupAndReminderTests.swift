import XCTest
#if canImport(CozyCore)
@testable import CozyCore
#else
@testable import Cozyday
#endif

final class BackupTests: XCTestCase {
    static func sampleDocument() -> BackupDocument {
        let template = makeTemplate(weekdays: [])
        var occ = OccurrenceFactory.make(from: template, day: day("2026-10-18"), now: date(2026, 10, 18, 6))
        occ.status = .done
        occ.completedAt = date(2026, 10, 18, 8, 31)
        let inbox = makeOneOff(title: "Gọi điện cho bà", day: nil, start: nil)
        let reward = RewardPolicy.forTaskCompletion(occurrence: occ, existingKeys: [], now: date(2026, 10, 18, 8, 31))!
        let journalReward = RewardPolicy.forJournal(day: day("2026-10-18"), existingKeys: [], now: date(2026, 10, 18, 21))!
        let buy = LedgerEntry(id: UUID(), key: LedgerKeys.purchase("desk.pine"), kind: .purchase, xp: 0, coins: 0,
                              createdAt: date(2026, 10, 18, 9), refID: "desk.pine", memo: "Bàn gỗ thông")
        var focus = FocusSessionRecord.start(kind: .focus, minutes: 25, occurrenceID: occ.id, now: date(2026, 10, 18, 9))
        focus.reconcile(at: date(2026, 10, 18, 10))
        var profile = ProfileRecord.makeDefault(now: date(2026, 10, 1))
        profile.userName = "Phú"
        profile.petName = "Mochi"
        profile.onboardingCompleted = true
        return BackupDocument(
            format: BackupDocument.formatID,
            schemaVersion: BackupDocument.currentSchemaVersion,
            exportedAt: date(2026, 10, 18, 22),
            appVersion: "1.0 (1)",
            profile: profile,
            templates: [template],
            occurrences: [occ, inbox],
            ledger: [reward, journalReward, buy],
            ownedItems: [OwnedItemRecord(itemID: "desk.pine", acquiredAt: date(2026, 10, 18, 9), transactionID: buy.id)],
            equipped: [EquippedRecord(slot: .desk, itemID: "desk.pine")],
            focusSessions: [focus],
            journal: [JournalRecord(id: UUID(), day: day("2026-10-18"), mood: 4, note: "Một ngày ổn \"đẹp\"\nDòng 2",
                                    createdAt: date(2026, 10, 18, 21), updatedAt: date(2026, 10, 18, 21))]
        )
    }

    func testRoundTripKeepsEverything() throws {
        let doc = Self.sampleDocument()
        let data = try BackupCodec.encode(doc)
        let decoded = try BackupCodec.decodeAndValidate(data)
        XCTAssertEqual(decoded, doc)
        XCTAssertEqual(decoded.counts.coins, RewardConfig.taskCoins + RewardConfig.journalCoins)
        XCTAssertEqual(decoded.counts.ownedItems, 1)
    }

    func testRejectsNewerSchema() throws {
        var doc = Self.sampleDocument()
        doc.schemaVersion = BackupDocument.currentSchemaVersion + 1
        let data = try BackupCodec.encode(doc)
        XCTAssertThrowsError(try BackupCodec.decodeAndValidate(data)) { error in
            XCTAssertEqual(error as? BackupError, .unsupportedVersion(found: 2, supported: 1))
        }
    }

    func testRejectsGarbageAndForeignJSON() {
        XCTAssertThrowsError(try BackupCodec.decodeAndValidate(Data("không phải json".utf8))) {
            XCTAssertEqual($0 as? BackupError, .notJSON)
        }
        XCTAssertThrowsError(try BackupCodec.decodeAndValidate(Data("{\"hello\": 1}".utf8))) {
            XCTAssertEqual($0 as? BackupError, .wrongFormat)
        }
    }

    func testRejectsTruncatedFile() throws {
        let data = try BackupCodec.encode(Self.sampleDocument())
        let cut = data.prefix(data.count / 2)
        XCTAssertThrowsError(try BackupCodec.decodeAndValidate(Data(cut)))
    }

    func testRejectsMissingField() throws {
        let data = try BackupCodec.encode(Self.sampleDocument())
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        json.removeValue(forKey: "ledger")
        let broken = try JSONSerialization.data(withJSONObject: json)
        XCTAssertThrowsError(try BackupCodec.decodeAndValidate(broken)) { error in
            guard case .corrupted = error as? BackupError else { return XCTFail("\(error)") }
        }
    }

    func testRejectsDuplicateIDsAndBadReferences() throws {
        var dup = Self.sampleDocument()
        dup.occurrences.append(dup.occurrences[0])
        XCTAssertThrowsError(try BackupCodec.decodeAndValidate(BackupCodec.encode(dup))) {
            XCTAssertEqual($0 as? BackupError, .duplicateID("việc"))
        }

        var equipNotOwned = Self.sampleDocument()
        equipNotOwned.equipped.append(EquippedRecord(slot: .lamp, itemID: "lamp.candle"))
        XCTAssertThrowsError(try BackupCodec.decodeAndValidate(BackupCodec.encode(equipNotOwned)))

        var wrongSlot = Self.sampleDocument()
        wrongSlot.equipped = [EquippedRecord(slot: .wall, itemID: "desk.pine")]
        XCTAssertThrowsError(try BackupCodec.decodeAndValidate(BackupCodec.encode(wrongSlot)))

        var badMood = Self.sampleDocument()
        badMood.journal[0].mood = 9
        XCTAssertThrowsError(try BackupCodec.decodeAndValidate(BackupCodec.encode(badMood)))

        var negative = Self.sampleDocument()
        negative.ledger.append(LedgerEntry(id: UUID(), key: "purchase:wall.shelf", kind: .purchase, xp: 0, coins: -999,
                                           createdAt: Date(), refID: "wall.shelf", memo: ""))
        XCTAssertThrowsError(try BackupCodec.decodeAndValidate(BackupCodec.encode(negative))) {
            XCTAssertEqual($0 as? BackupError, .invalidValue("số xu âm"))
        }

        var crossing = Self.sampleDocument()
        crossing.occurrences[0].startMinute = 23 * 60 + 50
        XCTAssertThrowsError(try BackupCodec.decodeAndValidate(BackupCodec.encode(crossing)))
    }

    func testTooLarge() {
        let big = Data(repeating: 0x20, count: BackupCodec.maxBytes + 1)
        XCTAssertThrowsError(try BackupCodec.decodeAndValidate(big)) {
            guard case .tooLarge = $0 as? BackupError else { return XCTFail() }
        }
    }
}

final class ReminderPlannerTests: XCTestCase {
    func testOnlyFutureOpenTasksWithinHorizonSorted() {
        let c = cal()
        let now = date(2026, 10, 18, 9)
        var a = makeOneOff(title: "A", day: day("2026-10-18"), start: 10 * 60) // nhắc 9:50
        a.reminderOffsetMinutes = 10
        var b = makeOneOff(title: "B", day: day("2026-10-18"), start: 9 * 60) // đã qua
        b.reminderOffsetMinutes = 0
        var done = makeOneOff(title: "C", day: day("2026-10-18"), start: 11 * 60, status: .done)
        done.reminderOffsetMinutes = 0
        var far = makeOneOff(title: "D", day: day("2026-11-30"), start: 11 * 60)
        far.reminderOffsetMinutes = 0
        var tomorrow = makeOneOff(title: "E", day: day("2026-10-19"), start: 7 * 60)
        tomorrow.reminderOffsetMinutes = 5
        let noReminder = makeOneOff(title: "F", day: day("2026-10-18"), start: 12 * 60)

        let result = ReminderPlanner.taskReminders(occurrences: [tomorrow, a, b, done, far, noReminder], now: now, calendar: c)
        XCTAssertEqual(result.map(\.title), ["A", "E"])
        XCTAssertEqual(result[0].fireDate, date(2026, 10, 18, 9, 50))
        XCTAssertEqual(result[0].id, ReminderIDs.task(a.id))
    }

    func testRespectsLimitAndDiff() {
        let c = cal()
        let now = date(2026, 10, 18, 0)
        let many: [TaskOccurrenceRecord] = (0..<100).map { i in
            var o = makeOneOff(title: "T\(i)", day: day("2026-10-18"), start: 60 + i * 5, duration: 5)
            o.reminderOffsetMinutes = 0
            return o
        }
        let result = ReminderPlanner.taskReminders(occurrences: many, now: now, calendar: c)
        XCTAssertEqual(result.count, ReminderPlanner.taskLimit)
        XCTAssertLessThan(result.count + 2, ReminderPlanner.systemPendingLimit + 1)

        let pending: Set<String> = ["task.old", ReminderIDs.focusEnd, ReminderIDs.journalDaily, result[0].id]
        let diff = ReminderPlanner.diff(pendingIDs: pending, desired: result)
        XCTAssertEqual(diff.remove, ["task.old"])
    }
}

final class StatsTests: XCTestCase {
    func testSummaryUsesRealDataOnly() {
        let c = cal()
        let days = day("2026-10-12").through(day("2026-10-18"), calendar: c)
        let done1 = makeOneOff(day: day("2026-10-18"), status: .done)
        let done2 = makeOneOff(day: day("2026-10-15"), status: .done)
        let open = makeOneOff(day: day("2026-10-18"))
        let old = makeOneOff(day: day("2026-09-01"), status: .done)
        var focus = FocusSessionRecord.start(kind: .focus, minutes: 50, occurrenceID: nil, now: date(2026, 10, 17, 9))
        focus.endEarly(at: date(2026, 10, 17, 9, 30))
        var rest = FocusSessionRecord.start(kind: .rest, minutes: 10, occurrenceID: nil, now: date(2026, 10, 17, 10))
        rest.reconcile(at: date(2026, 10, 17, 11))
        let journal = JournalRecord(id: UUID(), day: day("2026-10-13"), mood: 3, note: "", createdAt: Date(), updatedAt: Date())

        let s = StatsCalculator.summary(days: days, occurrences: [done1, done2, open, old], focusSessions: [focus, rest], journal: [journal], calendar: c)
        XCTAssertEqual(s.completedTasks, 2)
        XCTAssertEqual(s.focusMinutes, 30)
        XCTAssertEqual(s.activeDays, 4)
        XCTAssertEqual(s.days.count, 7)

        let active = Set(s.days.filter(\.isActive).map(\.day))
        XCTAssertEqual(StatsCalculator.currentStreak(activeDays: active, today: day("2026-10-18"), calendar: c), 2)
    }
}
