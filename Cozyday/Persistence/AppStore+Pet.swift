import Foundation

extension AppStore {
    // MARK: Ngoại hình

    var equippedMap: [ItemSlot: String] {
        Dictionary(equipped.map { ($0.slot, $0.itemID) }, uniquingKeysWith: { a, _ in a })
    }

    var petAppearance: PetAppearance {
        PetAppearance(equipped: equippedMap, level: wallet.level)
    }

    /// Món đang dùng ở một vị trí của thú cưng, kể cả lựa chọn mặc định.
    func petItemInUse(_ slot: ItemSlot) -> String? {
        petAppearance.itemID(in: slot)
    }

    // MARK: Chuyến phiêu lưu

    func adventureEnergy(on day: DayKey) -> Int {
        Adventure.energy(on: day, ledger: ledger, calendar: calendar)
    }

    func adventureClaimed(on day: DayKey) -> Bool {
        ledgerKeys.contains(LedgerKeys.adventure(day))
    }

    /// Nghe thú cưng kể chuyện khi đủ năng lượng: thưởng một lần mỗi ngày.
    @discardableResult
    func claimAdventure(day: DayKey) throws -> LedgerEntry? {
        guard Adventure.isReady(on: day, ledger: ledger, calendar: calendar) else {
            throw StoreError.invalid("\(profile.displayPetName) chưa đủ năng lượng để đi chơi hôm nay.")
        }
        guard let entry = Adventure.reward(day: day, existingKeys: ledgerKeys, petName: profile.displayPetName, now: now) else {
            return nil
        }
        try commit { self.insertLedger(entry) }
        return entry
    }

    /// Các chuyến đi đã nghe kể, mới nhất trước.
    var adventureMemories: [AdventureMemory] {
        ledger.filter { $0.kind == .adventure }
            .compactMap { e in e.refID.flatMap(DayKey.init(string:)) }
            .sorted(by: >)
            .map { AdventureMemory(day: $0, story: Adventure.story(for: $0, petName: profile.displayPetName)) }
    }

    // MARK: Bài thở

    @discardableResult
    func completeBreathing(day: DayKey) throws -> LedgerEntry? {
        guard let entry = RewardPolicy.forBreathing(day: day, existingKeys: ledgerKeys, now: now) else { return nil }
        try commit { self.insertLedger(entry) }
        return entry
    }

    // MARK: Lời thoại

    func petDialogueContext(today: DayKey) -> PetDialogue.Context {
        let tasks = self.tasks(on: today).filter { $0.status != .skipped }
        let active = Set(StatsCalculator.summary(
            days: today.adding(days: -60, calendar: calendar).through(today, calendar: calendar),
            occurrences: occurrences, focusSessions: focusSessions, journal: journal, calendar: calendar
        ).days.filter(\.isActive).map(\.day))
        return PetDialogue.Context(
            minuteOfDay: calendar.minuteOfDay(now),
            tasksDone: tasks.filter { $0.status == .done }.count,
            tasksTotal: tasks.count,
            wroteJournal: journalEntry(for: today) != nil,
            focusRunning: activeFocus != nil,
            adventureReady: Adventure.isReady(on: today, ledger: ledger, calendar: calendar) && !adventureClaimed(on: today),
            streak: StatsCalculator.currentStreak(activeDays: active, today: today, calendar: calendar),
            userName: profile.userName
        )
    }
}
