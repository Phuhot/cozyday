import Foundation
import SwiftData

extension AppStore {
    var hasTestData: Bool { isTesterMode || ledger.contains { $0.kind == .tester || $0.key == "system:tester-history" } }

    /// Count actual recorded activity, not launches, purchases, currency grants or reward claims.
    var meaningfulDays: Set<DayKey> {
        Set(ledger.filter { $0.key.hasPrefix("system:active-day:") }
            .compactMap { $0.refID.flatMap(DayKey.init(string:)) })
    }

    /// Freeze legacy local dates once. Subsequent timezone changes must not count an activity twice.
    func migrateEngagementDays() throws {
        let migration = "system:engagement-days-v1"
        guard !ledgerKeys.contains(migration) else { return }
        var days = Set(ledger.filter { [.taskCompleted, .focusCompleted, .journalWritten, .breathing].contains($0.kind) }
            .map { DayKey($0.createdAt, calendar: calendar) })
        days.formUnion(careActions.filter { $0.kind != .freeMeal }.map(\.day))
        days.formUnion(minigameResults.filter { $0.note != .implausible && $0.note != .notCompleted }.map(\.day))
        days.formUnion(ledger.filter { $0.kind == .quest }.compactMap { $0.refID.flatMap(DayKey.init(string:)) })
        try commit {
            for day in days { self.recordMeaningfulDay(day) }
            self.insertLedger(LedgerEntry(id:UUID(),key:migration,kind:.system,xp:0,coins:0,
                                         createdAt:self.now,refID:nil,memo:"Giữ ngày gắn bó theo lịch đã ghi"))
        }
    }

    func badgeProgress(_ badge: CozyBadge) -> Int {
        switch badge.metric {
        case .care: return ledger.filter { $0.key.hasPrefix("system:care-action:") }.count + careActions.filter { !ledgerKeys.contains("system:care-action:\($0.id.uuidString)") }.count
        case .focus: return focusSessions.filter { $0.kind == .focus && $0.status == .completed }.reduce(0) { $0 + Int($1.focusedSeconds/60) }
        case .games: return ledger.filter { $0.key.hasPrefix("system:game-complete:") }.count + minigameResults.filter { $0.note != .implausible && $0.note != .notCompleted && !ledgerKeys.contains("system:game-complete:\($0.id.uuidString)") }.count
        case .collection: return realOwnedIDs.subtracting(Catalog.defaultIDs).count
        case .adventures: return ledger.filter { $0.kind == .adventure }.count
        case .days: return meaningfulDays.count
        }
    }

    func claimBadge(_ badge: CozyBadge) throws {
        try commit {
            guard CozyBadge.all.contains(badge), !self.hasTestData, self.badgeProgress(badge) >= badge.target,
                  !self.ledgerKeys.contains(LedgerKeys.badge(badge.id)) else {
                throw StoreError.invalid("Chưa thể nhận huy hiệu này hoặc đã nhận rồi.")
            }
            self.insertLedger(LedgerEntry(id:UUID(),key:LedgerKeys.badge(badge.id),kind:.badge,xp:0,coins:badge.coins,
                                          createdAt:self.now,refID:badge.id,memo:badge.title))
        }
    }

    /// Called inside the existing write transaction; stable date stamps survive pruning and travel.
    func recordMeaningfulDay(_ day: DayKey) {
        let key = "system:active-day:\(day.string)"
        guard !isTesterMode, !ledgerKeys.contains(key) else { return }
        insertLedger(LedgerEntry(id:UUID(),key:key,kind:.system,xp:0,coins:0,createdAt:now,refID:day.string,memo:"Ngày gắn bó"))
    }

    func eventActivity(_ event: CozyEvent) -> DayActivity {
        let c = VietnameseEvents.calendar
        func inside(_ date: Date) -> Bool { event.contains(DayKey(date,calendar:c)) }
        var a = DayActivity()
        a.careActions = careActions.filter { inside($0.performedAt) }.count
        a.focusMinutes = focusSessions.filter { $0.kind == .focus && $0.status == .completed && inside($0.endedAt ?? $0.startedAt) }
            .reduce(0) { $0 + Int($1.focusedSeconds/60) }
        a.journalWritten = journal.contains { inside($0.createdAt) }
        return a
    }

    func claimEvent(_ event: CozyEvent) throws {
        try commit {
            guard !self.hasTestData, VietnameseEvents.all.contains(event),
                  VietnameseEvents.claimable(event,now:self.now,activity:self.eventActivity(event),keys:self.ledgerKeys) else {
                throw StoreError.invalid("Sự kiện chưa đủ điều kiện, đã nhận hoặc đã kết thúc.")
            }
            let key = LedgerKeys.event(event.id,"complete")
            self.insertLedger(LedgerEntry(id:UUID(),key:key,kind:.event,xp:0,coins:event.coins,
                createdAt:self.now,refID:event.id,memo:event.title))
            let record = KeepsakeRecord(id:UUID(),sourceKey:key,artID:event.artID,title:event.keepsakeTitle,
                story:"\(self.profile.displayPetName) cùng bạn đón \(event.title.lowercased()).",
                day:DayKey(self.now,calendar:VietnameseEvents.calendar),petName:self.profile.displayPetName,
                species:self.petAppearance.species.rawValue,createdAt:self.now,placedRoom:nil)
            self.context.insert(KeepsakeModel(record:record)); self.keepsakes.append(record)
        }
    }

    func placeKeepsake(_ id: UUID, in room: RoomKind?) throws {
        guard room?.isUnlocked(level: wallet.level) ?? true else { throw StoreError.invalid("Phòng chưa mở.") }
        try commit {
            let models = try self.context.fetch(FetchDescriptor<KeepsakeModel>())
            guard let chosen = models.first(where: { $0.id == id }) else { throw StoreError.notFound }
            // One display pedestal per room. Moving an object never destroys the previous one.
            if let room {
                for m in models where m.placedRoom == room.rawValue { m.placedRoom = nil }
            }
            chosen.placedRoom = room?.rawValue
        }
        try reloadAll()
    }

    func savedAdventureStory(on day: DayKey) -> AdventureStory {
        if let memory = keepsakes.first(where: { $0.sourceKey == LedgerKeys.adventure(day) }) {
            return AdventureStory(title:memory.title,text:memory.story,keepsake:memory.artID == "postcard" ? "Bưu thiếp chuyến đi" : memory.title)
        }
        if let old = ledger.first(where: { $0.key == LedgerKeys.adventure(day) }) {
            return AdventureStory(title:old.memo,text:"Chuyến đi từ bản lưu cũ. Phiên bản đó chưa lưu tên, loài và toàn bộ câu chuyện tại thời điểm nhận.",keepsake:"Ký ức cũ")
        }
        return Adventure.story(for:day,petName:profile.displayPetName,species:petAppearance.species)
    }
}
