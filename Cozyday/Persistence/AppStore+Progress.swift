import Foundation
import SwiftData

// Phiên 9: dấu dữ liệu một lần, mã quà, chế độ "Dữ liệu thử nghiệm", nhiệm vụ ngày, rương tuần, quà mốc cấp.
// Mọi phần thưởng là dòng sổ cái có khóa cố định → nhận lại / bấm nhanh hai lần / mở lại app không nhận thêm.

enum GiftRedemption: Equatable {
    /// Nhận xu (số xu thực nhận; 0 khi đã nhận đủ ở bản cũ).
    case coins(Int)
    /// Mã chế độ thử nghiệm: cần hỏi lại người dùng trước khi bật (`enableTesterMode()`).
    case needsTesterConfirmation
    case testerAlreadyOn
}

extension AppStore {
    // MARK: Dấu dữ liệu một lần

    /// Chạy đúng một lần cho mỗi bộ dữ liệu (khóa `system:migration:econ2` trong sổ cái, có trong bản sao lưu):
    /// 1. Giữ cấp: ai đang ở cấp cao hơn đường XP mới (công thức cũ 100 XP/cấp) được ghi cấp tối thiểu.
    /// 2. Bù mã t3ster: người đã đổi bản cũ (1.000 xu/lần) được bù tới tổng 10.000 xu, đúng một lần.
    /// Bản sao lưu cũ được khôi phục sau đó cũng chạy bước này (vì chưa có khóa).
    func runDataMigrations() throws {
        guard !ledgerKeys.contains(LedgerKeys.migrationEcon2) else { return }
        try commit {
            let keys = self.ledgerKeys
            let xp = self.wallet.xp
            let legacy = LevelCurve.legacyLevel(forXP: xp)
            if legacy > LevelCurve.level(forXP: xp), !keys.contains(LedgerKeys.levelFloor) {
                self.insertLedger(LedgerEntry(id: UUID(), key: LedgerKeys.levelFloor, kind: .system, xp: 0, coins: 0,
                                              createdAt: self.now, refID: nil, memo: String(legacy)))
            }
            if GiftCodes.legacyT3sterReceived(self.ledger) > 0,
               let topUp = GiftCodes.t3sterEntry(ledger: self.ledger, existingKeys: keys, now: self.now, isTopUp: true) {
                self.insertLedger(topUp)
            }
            self.insertLedger(LedgerEntry(id: UUID(), key: LedgerKeys.migrationEcon2, kind: .system, xp: 0, coins: 0,
                                          createdAt: self.now, refID: nil, memo: "Kinh tế phiên 9"))
        }
    }

    // MARK: Mã quà

    @discardableResult
    func redeemGiftCode(_ code: String) throws -> GiftRedemption {
        switch GiftCodes.kind(of: code) {
        case nil:
            throw StoreError.invalid("Mã không đúng.")
        case .testerMode?:
            return isTesterMode ? .testerAlreadyOn : .needsTesterConfirmation
        case .coins?:
            // Kiểm tra lại khóa BÊN TRONG lần ghi: bấm nhanh hai lần thì lần sau thấy khóa đã có.
            var granted = 0
            try commit {
                guard let entry = GiftCodes.t3sterEntry(ledger: self.ledger, existingKeys: self.ledgerKeys, now: self.now,
                                                        isTopUp: false) else {
                    throw StoreError.invalid("Mã này đã được dùng cho bộ dữ liệu này.")
                }
                self.insertLedger(entry)
                granted = entry.coins
            }
            return .coins(granted)
        }
    }

    // MARK: Chế độ "Dữ liệu thử nghiệm" (mã phuhotdz)

    var isTesterMode: Bool { wallet.testerMode }

    /// Bật: chỉ ghi một dòng cờ. Toàn bộ đồ trong danh mục (kể cả đồ thêm ở bản sau) được coi như đã có
    /// và cấp hiển thị là cấp tối đa — KHÔNG ghi đồ, XP, việc, nhật ký, huy hiệu, chuỗi ngày hay kết quả chơi.
    func enableTesterMode() throws {
        guard !isTesterMode else { return }
        try commit {
            if !self.ledgerKeys.contains("system:tester-history") {
                self.insertLedger(LedgerEntry(id: UUID(), key: "system:tester-history", kind: .system, xp: 0, coins: 0,
                                             createdAt: self.now, refID: nil, memo: "Bộ dữ liệu từng bật thử nghiệm"))
            }
            self.insertLedger(LedgerEntry(id: UUID(), key: LedgerKeys.testerMode, kind: .tester, xp: 0, coins: 0,
                                          createdAt: self.now, refID: nil, memo: "Bật Dữ liệu thử nghiệm"))
        }
    }

    /// Tắt: xóa dòng cờ và tháo những món đang mặc/đặt mà bạn chưa thật sự sở hữu.
    /// Xu/vé thử nghiệm đã cộng và đồ đã MUA trong lúc thử vẫn còn (được đánh dấu trong sổ cái);
    /// đây không phải bản khôi phục nguyên trạng — nên sao lưu trước khi bật.
    func disableTesterMode() throws {
        guard isTesterMode else { return }
        let realOwned = Set(owned.map(\.itemID))
        try commit {
            let key = LedgerKeys.testerMode
            for m in try self.context.fetch(FetchDescriptor<LedgerEntryModel>(predicate: #Predicate { $0.key == key })) {
                self.context.delete(m)
            }
            self.ledger.removeAll { $0.key == key }
            for m in try self.context.fetch(FetchDescriptor<EquippedSlotModel>())
            where !Catalog.isOwned(m.itemID, owned: realOwned) {
                self.context.delete(m)
            }
        }
        try reloadAll()
    }

    /// Bảng công cụ: cộng xu/vé thử (dòng `tester`, không phải phần thưởng thật).
    func grantTesterCurrency(coins: Int, tickets: Int) throws {
        guard isTesterMode else { throw StoreError.invalid("Chỉ dùng được khi đang bật Dữ liệu thử nghiệm.") }
        let id = UUID()
        try commit {
            self.insertLedger(LedgerEntry(id: id, key: LedgerKeys.tester(id), kind: .tester, xp: 0, coins: max(0, coins),
                                          createdAt: self.now, refID: nil, memo: "Xu/vé thử nghiệm", tickets: max(0, tickets)))
        }
    }

    // MARK: Nhiệm vụ ngày

    /// Hoạt động trong ngày, đếm từ dữ liệu sẵn có.
    func activity(on day: DayKey) -> DayActivity {
        var a = DayActivity()
        a.tasksDone = ledger.filter { $0.kind == .taskCompleted && DayKey($0.createdAt, calendar: calendar) == day }.count
        a.focusMinutes = focusSessions
            .filter { $0.kind == .focus && $0.status == .completed && DayKey($0.endedAt ?? $0.startedAt, calendar: calendar) == day }
            .reduce(0) { $0 + Int($1.focusedSeconds / 60) }
        a.careActions = careActions.filter { $0.day == day && $0.kind != .freeMeal }.count
        a.minigameRuns = minigameResults.filter {
            $0.day == day && $0.note != .implausible && $0.note != .notCompleted
        }.count
        a.journalWritten = journal.contains { $0.day == day }
        a.breathingDone = ledgerKeys.contains(LedgerKeys.breathing(day))
        return a
    }

    func dailyQuests(on day: DayKey) -> [DailyQuest] { DailyQuests.quests(for: day) }

    func dailyQuestsClaimed(on day: DayKey) -> Bool { ledgerKeys.contains(LedgerKeys.questDay(day)) }

    @discardableResult
    func claimDailyQuests(day: DayKey) throws -> LedgerEntry {
        var granted: LedgerEntry?
        try commit {
            guard let entry = DailyQuests.claimEntry(day: day, today: self.today, calendar: self.calendar,
                                                     activity: self.activity(on: day), existingKeys: self.ledgerKeys,
                                                     now: self.now) else {
                throw StoreError.invalid(self.dailyQuestsClaimed(on: day) ? "Đã nhận thưởng nhiệm vụ của ngày này." : "Chưa xong đủ ba mục tiêu.")
            }
            self.insertLedger(entry)
            granted = entry
        }
        return granted!
    }

    // MARK: Rương tuần

    var currentWeekStart: DayKey { WeeklyChest.weekStart(of: today, calendar: calendar) }

    func weeklyChestDays(weekStart: DayKey) -> Set<DayKey> {
        WeeklyChest.completedDays(weekStart: weekStart, ledger: ledger, calendar: calendar)
    }

    func weeklyChestClaimed(weekStart: DayKey) -> Bool { ledgerKeys.contains(LedgerKeys.weeklyChest(weekStart)) }

    /// Tuần còn rương chưa nhận: tuần này, hoặc tuần trước nếu đã đủ ngày mà chưa kịp nhận.
    var claimableChestWeek: DayKey? {
        let current = currentWeekStart
        let previous = current.adding(days: -7, calendar: calendar)
        for week in [current, previous] where !weeklyChestClaimed(weekStart: week)
            && weeklyChestDays(weekStart: week).count >= WeeklyChest.requiredDays {
            return week
        }
        return nil
    }

    @discardableResult
    func claimWeeklyChest(weekStart: DayKey) throws -> LedgerEntry {
        var granted: LedgerEntry?
        try commit {
            guard let entry = WeeklyChest.claimEntry(weekStart: weekStart, today: self.today, calendar: self.calendar,
                                                     ledger: self.ledger, existingKeys: self.ledgerKeys, now: self.now) else {
                throw StoreError.invalid(self.weeklyChestClaimed(weekStart: weekStart) ? "Đã mở rương của tuần này." : "Chưa đủ ngày để mở rương.")
            }
            self.insertLedger(entry)
            granted = entry
        }
        return granted!
    }

    // MARK: Quà mốc cấp

    /// Mốc đã đạt theo cấp THẬT (không tính chế độ thử nghiệm) mà chưa nhận.
    var claimableMilestones: [LevelMilestone] {
        LevelMilestones.claimable(realLevel: wallet.realLevel, existingKeys: ledgerKeys)
    }

    @discardableResult
    func claimLevelMilestone(_ level: Int) throws -> LedgerEntry {
        guard let m = LevelMilestones.milestone(level) else { throw StoreError.invalid("Không có quà ở cấp này.") }
        var granted: LedgerEntry?
        try commit {
            guard let entry = LevelMilestones.entry(m, realLevel: self.wallet.realLevel, existingKeys: self.ledgerKeys,
                                                    now: self.now) else {
                throw StoreError.invalid(self.ledgerKeys.contains(LedgerKeys.levelMilestone(level)) ? "Đã nhận quà cấp \(level)." : "Chưa đạt cấp \(level).")
            }
            self.insertLedger(entry)
            granted = entry
        }
        return granted!
    }
}
