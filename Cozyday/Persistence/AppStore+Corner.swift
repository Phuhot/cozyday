import Foundation
import SwiftData

extension AppStore {
    var ownedIDs: Set<String> { Set(owned.map(\.itemID)) }

    func equippedItem(in slot: ItemSlot) -> CatalogItem? {
        equipped.first { $0.slot == slot }.flatMap { Catalog.item($0.itemID) }
    }

    /// Mua (hoặc nhận đồ miễn phí). Trừ xu + thêm vào kho trong cùng một lần save.
    /// Món vừa mua được trang bị luôn nếu vị trí đó đang trống.
    func buy(itemID: String) throws {
        let decision = PurchasePolicy.decide(itemID: itemID, owned: ownedIDs, ledger: ledger, now: now)
        guard case .approved(let entry) = decision else {
            throw StoreError.invalid(decision.message ?? "Không mua được.")
        }
        guard let item = Catalog.item(itemID) else { throw StoreError.notFound }
        let ownedRecord = OwnedItemRecord(itemID: itemID, acquiredAt: now, transactionID: entry.id)
        try commit {
            self.insertLedger(entry)
            self.context.insert(OwnedItemModel(record: ownedRecord))
            self.owned.append(ownedRecord)
            if self.equippedItem(in: item.slot) == nil {
                try self.setEquipped(slot: item.slot, itemID: itemID)
            }
        }
    }

    /// Dùng một món đã có. Món mặc định (mèo, lông kem) = bỏ trống vị trí đó.
    func equip(itemID: String) throws {
        guard let item = Catalog.item(itemID) else { throw StoreError.notFound }
        guard Catalog.isOwned(itemID, owned: ownedIDs) else { throw StoreError.invalid("Bạn chưa sở hữu món này.") }
        try commit {
            if item.isDefault {
                try self.removeEquipped(slot: item.slot)
            } else {
                try self.setEquipped(slot: item.slot, itemID: itemID)
            }
        }
    }

    func unequip(slot: ItemSlot) throws {
        try commit {
            try self.removeEquipped(slot: slot)
        }
    }

    private func removeEquipped(slot: ItemSlot) throws {
        let raw = slot.rawValue
        let models = try context.fetch(FetchDescriptor<EquippedSlotModel>(predicate: #Predicate { $0.slotRaw == raw }))
        models.forEach { context.delete($0) }
        equipped.removeAll { $0.slot == slot }
    }

    private func setEquipped(slot: ItemSlot, itemID: String) throws {
        let raw = slot.rawValue
        let models = try context.fetch(FetchDescriptor<EquippedSlotModel>(predicate: #Predicate { $0.slotRaw == raw }))
        if let first = models.first {
            first.itemID = itemID
            models.dropFirst().forEach { context.delete($0) }
        } else {
            context.insert(EquippedSlotModel(slotRaw: raw, itemID: itemID))
        }
        equipped.removeAll { $0.slot == slot }
        equipped.append(EquippedRecord(slot: slot, itemID: itemID))
    }
}

extension AppStore {
    // MARK: Nhật ký

    func journalEntry(for day: DayKey) -> JournalRecord? {
        journal.first { $0.day == day }
    }

    /// Lưu nhật ký của một ngày. Lần đầu có nhật ký cho ngày đó → thưởng (một lần mỗi ngày).
    @discardableResult
    func saveJournal(day: DayKey, mood: Mood, note: String) throws -> LedgerEntry? {
        let trimmed = String(note.prefix(JournalRecord.maxNoteLength))
        var granted: LedgerEntry?
        try commit {
            let raw = day.string
            let models = try self.context.fetch(FetchDescriptor<JournalEntryModel>(predicate: #Predicate { $0.dayRaw == raw }))
            let record: JournalRecord
            if let model = models.first, var existing = model.record {
                existing.mood = mood.rawValue
                existing.note = trimmed
                existing.updatedAt = self.now
                model.apply(existing)
                record = existing
            } else {
                record = JournalRecord(id: UUID(), day: day, mood: mood.rawValue, note: trimmed, createdAt: self.now, updatedAt: self.now)
                self.context.insert(JournalEntryModel(record: record))
            }
            self.journal.removeAll { $0.day == day }
            self.journal.append(record)
            if day <= self.today, let entry = RewardPolicy.forJournal(day: day, existingKeys: self.ledgerKeys, now: self.now) {
                self.insertLedger(entry)
                granted = entry
            }
        }
        return granted
    }

    func deleteJournal(day: DayKey) throws {
        try commit {
            let raw = day.string
            let models = try self.context.fetch(FetchDescriptor<JournalEntryModel>(predicate: #Predicate { $0.dayRaw == raw }))
            models.forEach { self.context.delete($0) }
            self.journal.removeAll { $0.day == day }
        }
    }
}

extension AppStore {
    // MARK: Onboarding

    func completeOnboarding(userName: String, petName: String, goals: [UsageGoal], habits: [HabitSuggestion]) throws {
        var updated = profile
        updated.userName = String(userName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
        let pet = petName.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.petName = pet.isEmpty ? ProfileRecord.defaultPetName : String(pet.prefix(30))
        updated.goals = goals.map(\.rawValue)
        updated.onboardingCompleted = true
        let start = today
        let newTemplates: [TaskTemplateRecord] = habits.compactMap { habit in
            var draft = TaskDraft()
            draft.title = habit.title
            draft.category = habit.category
            draft.day = start
            draft.startMinute = habit.startMinute
            draft.durationMinutes = habit.duration
            draft.repeatFrequency = .daily
            return OccurrenceFactory.makeTemplate(from: draft, startDay: start, now: now)
        }
        try commit {
            guard let model = try self.fetchProfileModel() else { throw StoreError.notFound }
            model.apply(updated)
            self.profile = updated
            for t in newTemplates {
                self.context.insert(TaskTemplateModel(record: t))
                self.templates.append(t)
            }
        }
        try ensureUpcomingOccurrences()
    }
}
