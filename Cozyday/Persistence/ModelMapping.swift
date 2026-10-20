import Foundation

// Chuyển đổi hai chiều giữa model SwiftData và bản ghi giá trị trong Core.
// Logic nghiệp vụ chỉ làm việc với bản ghi giá trị; model chỉ để lưu.

extension ProfileModel {
    convenience init(record r: ProfileRecord) {
        self.init(
            userName: r.userName, petName: r.petName, goalsRaw: r.goals.joined(separator: ","),
            activeStartMinute: r.activeStartMinute, activeEndMinute: r.activeEndMinute,
            hapticsEnabled: r.hapticsEnabled, journalReminderEnabled: r.journalReminderEnabled,
            journalReminderMinute: r.journalReminderMinute, onboardingCompleted: r.onboardingCompleted,
            createdAt: r.createdAt, dataVersion: BackupDocument.currentSchemaVersion
        )
    }

    var record: ProfileRecord {
        ProfileRecord(
            userName: userName, petName: petName,
            goals: goalsRaw.split(separator: ",").map(String.init),
            activeStartMinute: activeStartMinute, activeEndMinute: activeEndMinute,
            hapticsEnabled: hapticsEnabled, journalReminderEnabled: journalReminderEnabled,
            journalReminderMinute: journalReminderMinute, onboardingCompleted: onboardingCompleted,
            createdAt: createdAt
        )
    }

    func apply(_ r: ProfileRecord) {
        userName = r.userName
        petName = r.petName
        goalsRaw = r.goals.joined(separator: ",")
        activeStartMinute = r.activeStartMinute
        activeEndMinute = r.activeEndMinute
        hapticsEnabled = r.hapticsEnabled
        journalReminderEnabled = r.journalReminderEnabled
        journalReminderMinute = r.journalReminderMinute
        onboardingCompleted = r.onboardingCompleted
        createdAt = r.createdAt
    }
}

extension TaskTemplateModel {
    convenience init(record: TaskTemplateRecord) {
        self.init(id: record.id)
        apply(record)
    }

    /// nil nếu dữ liệu lưu bị hỏng (ví dụ ngày không đọc được) — bản ghi đó được bỏ qua khi hiển thị.
    var record: TaskTemplateRecord? {
        guard let startDay = DayKey(string: startDayRaw) else { return nil }
        let weekdays = weekdaysRaw.split(separator: ",").compactMap { Int($0) }
        return TaskTemplateRecord(
            id: id, title: title, notes: notes,
            category: TaskCategory(rawValue: categoryRaw) ?? .personal,
            priority: TaskPriority(rawValue: priorityRaw) ?? .normal,
            startMinute: startMinute, durationMinutes: durationMinutes, isFixed: isFixed,
            reminderOffsetMinutes: reminderOffsetMinutes,
            recurrence: RecurrenceRule(
                frequency: RecurrenceFrequency(rawValue: frequencyRaw) ?? .daily,
                weekdays: weekdays, startDay: startDay,
                endDay: endDayRaw.flatMap { DayKey(string: $0) }
            ),
            createdAt: createdAt,
            subtasks: subtasksJSON.isEmpty ? nil : Subtasks.decode(subtasksJSON)
        )
    }

    func apply(_ r: TaskTemplateRecord) {
        title = r.title
        notes = r.notes
        categoryRaw = r.category.rawValue
        priorityRaw = r.priority.rawValue
        startMinute = r.startMinute
        durationMinutes = r.durationMinutes
        isFixed = r.isFixed
        reminderOffsetMinutes = r.reminderOffsetMinutes
        frequencyRaw = r.recurrence.frequency.rawValue
        weekdaysRaw = r.recurrence.weekdays.map(String.init).joined(separator: ",")
        startDayRaw = r.recurrence.startDay.string
        endDayRaw = r.recurrence.endDay?.string
        createdAt = r.createdAt
        subtasksJSON = Subtasks.encode(r.checklist)
    }
}

extension TaskOccurrenceModel {
    convenience init(record: TaskOccurrenceRecord) {
        self.init(id: record.id)
        apply(record)
    }

    var record: TaskOccurrenceRecord {
        TaskOccurrenceRecord(
            id: id, occurrenceKey: occurrenceKey, templateID: templateID,
            day: dayRaw.isEmpty ? nil : DayKey(string: dayRaw),
            startMinute: startMinute, durationMinutes: durationMinutes,
            title: title, notes: notes,
            category: TaskCategory(rawValue: categoryRaw) ?? .personal,
            priority: TaskPriority(rawValue: priorityRaw) ?? .normal,
            isFixed: isFixed, reminderOffsetMinutes: reminderOffsetMinutes,
            status: TaskStatus(rawValue: statusRaw) ?? .open,
            completedAt: completedAt, isDetached: isDetached, isRemoved: isRemoved,
            createdAt: createdAt, updatedAt: updatedAt,
            subtasks: subtasksJSON.isEmpty ? nil : Subtasks.decode(subtasksJSON)
        )
    }

    func apply(_ r: TaskOccurrenceRecord) {
        occurrenceKey = r.occurrenceKey
        templateID = r.templateID
        dayRaw = r.day?.string ?? ""
        startMinute = r.day == nil ? nil : r.startMinute
        durationMinutes = r.durationMinutes
        title = r.title
        notes = r.notes
        categoryRaw = r.category.rawValue
        priorityRaw = r.priority.rawValue
        isFixed = r.isFixed
        reminderOffsetMinutes = r.reminderOffsetMinutes
        statusRaw = r.status.rawValue
        completedAt = r.completedAt
        isDetached = r.isDetached
        isRemoved = r.isRemoved
        createdAt = r.createdAt
        updatedAt = r.updatedAt
        subtasksJSON = Subtasks.encode(r.checklist)
    }
}

extension LedgerEntryModel {
    convenience init(record r: LedgerEntry) {
        self.init(id: r.id)
        key = r.key
        kindRaw = r.kind.rawValue
        xp = r.xp
        coins = r.coins
        createdAt = r.createdAt
        refID = r.refID
        memo = r.memo
        tickets = r.tickets
    }

    var record: LedgerEntry? {
        guard let kind = LedgerKind(rawValue: kindRaw) else { return nil }
        return LedgerEntry(id: id, key: key, kind: kind, xp: xp, coins: coins, createdAt: createdAt, refID: refID, memo: memo,
                           tickets: tickets)
    }
}

extension KeepsakeModel {
    convenience init(record r: KeepsakeRecord) {
        self.init(id: r.id)
        apply(r)
    }

    func apply(_ r: KeepsakeRecord) {
        sourceKey = r.sourceKey
        artID = r.artID
        title = r.title
        story = r.story
        dayRaw = r.day.string
        petName = r.petName
        species = r.species
        createdAt = r.createdAt
        placedRoom = r.placedRoom
    }

    var record: KeepsakeRecord? {
        guard let day = DayKey(string: dayRaw) else { return nil }
        return KeepsakeRecord(id: id, sourceKey: sourceKey, artID: artID, title: title, story: story, day: day,
                              petName: petName, species: species, createdAt: createdAt, placedRoom: placedRoom)
    }
}

extension OwnedItemModel {
    convenience init(record r: OwnedItemRecord) {
        self.init(itemID: r.itemID, acquiredAt: r.acquiredAt, transactionID: r.transactionID)
    }

    var record: OwnedItemRecord {
        OwnedItemRecord(itemID: itemID, acquiredAt: acquiredAt, transactionID: transactionID)
    }
}

extension EquippedSlotModel {
    convenience init(record r: EquippedRecord) {
        self.init(slotRaw: r.slot.rawValue, itemID: r.itemID)
    }

    var record: EquippedRecord? {
        ItemSlot(rawValue: slotRaw).map { EquippedRecord(slot: $0, itemID: itemID) }
    }
}

extension FocusSessionModel {
    convenience init(record: FocusSessionRecord) {
        self.init(id: record.id)
        apply(record)
    }

    var record: FocusSessionRecord {
        FocusSessionRecord(
            id: id, kind: FocusKind(rawValue: kindRaw) ?? .focus, plannedSeconds: plannedSeconds,
            startedAt: startedAt, accumulatedSeconds: accumulatedSeconds, runningSince: runningSince,
            endedAt: endedAt, status: FocusStatus(rawValue: statusRaw) ?? .endedEarly,
            occurrenceID: occurrenceID, focusedSeconds: focusedSeconds
        )
    }

    func apply(_ r: FocusSessionRecord) {
        kindRaw = r.kind.rawValue
        plannedSeconds = r.plannedSeconds
        startedAt = r.startedAt
        accumulatedSeconds = r.accumulatedSeconds
        runningSince = r.runningSince
        endedAt = r.endedAt
        statusRaw = r.status.rawValue
        occurrenceID = r.occurrenceID
        focusedSeconds = r.focusedSeconds
    }
}

extension JournalEntryModel {
    convenience init(record: JournalRecord) {
        self.init(id: record.id)
        apply(record)
    }

    var record: JournalRecord? {
        guard let day = DayKey(string: dayRaw) else { return nil }
        return JournalRecord(id: id, day: day, mood: mood, note: note, createdAt: createdAt, updatedAt: updatedAt)
    }

    func apply(_ r: JournalRecord) {
        dayRaw = r.day.string
        mood = r.mood
        note = r.note
        createdAt = r.createdAt
        updatedAt = r.updatedAt
    }
}

extension PetCareStateModel {
    convenience init(record r: PetCareRecord) {
        self.init(createdAt: r.createdAt)
        apply(r)
    }

    var record: PetCareRecord {
        PetCareRecord(
            needs: PetNeeds(fullness: fullness, cleanliness: cleanliness, happiness: happiness, asOf: asOf),
            welcomeGranted: welcomeGranted, createdAt: createdAt
        )
    }

    func apply(_ r: PetCareRecord) {
        fullness = r.needs.fullness
        cleanliness = r.needs.cleanliness
        happiness = r.needs.happiness
        asOf = r.needs.asOf
        welcomeGranted = r.welcomeGranted
        createdAt = r.createdAt
    }
}

extension FoodStockModel {
    convenience init(record r: FoodStockRecord) {
        self.init(foodID: r.foodID, count: r.count)
    }

    var record: FoodStockRecord { FoodStockRecord(foodID: foodID, count: count) }
}

extension CareActionModel {
    convenience init(record r: CareActionRecord) {
        self.init(id: r.id)
        kindRaw = r.kind.rawValue
        dayRaw = r.day.string
        performedAt = r.performedAt
        foodID = r.foodID
        before = r.before
        after = r.after
        xp = r.xp
        coins = r.coins
        noteRaw = r.note.rawValue
    }

    var record: CareActionRecord? {
        guard let kind = CareActionKind(rawValue: kindRaw), let day = DayKey(string: dayRaw) else { return nil }
        return CareActionRecord(id: id, kind: kind, day: day, performedAt: performedAt, foodID: foodID, before: before,
                                after: after, xp: xp, coins: coins, note: CareRewardNote(rawValue: noteRaw) ?? .notNeeded)
    }
}

extension MinigameResultModel {
    convenience init(record r: MinigameResultRecord) {
        self.init(id: r.id)
        kindRaw = r.kind.rawValue
        score = r.score
        primary = r.primary
        secondary = r.secondary
        levelRaw = r.level?.rawValue
        activeSeconds = r.activeSeconds
        species = r.species
        startedAt = r.startedAt
        finishedAt = r.finishedAt
        dayRaw = r.day.string
        coins = r.coins
        earned = r.earned
        noteRaw = r.note.rawValue
    }

    var record: MinigameResultRecord? {
        guard let kind = MinigameKind(rawValue: kindRaw), let day = DayKey(string: dayRaw) else { return nil }
        return MinigameResultRecord(
            id: id, kind: kind, score: score, primary: primary, secondary: secondary,
            level: levelRaw.flatMap(MemoryLevel.init(rawValue:)), activeSeconds: activeSeconds, species: species,
            startedAt: startedAt, finishedAt: finishedAt, day: day, coins: coins, earned: earned,
            note: MinigameRewardNote(rawValue: noteRaw) ?? .belowThreshold
        )
    }
}
