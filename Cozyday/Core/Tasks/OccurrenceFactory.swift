import Foundation

/// Tạo occurrence từ mẫu lặp với khóa ổn định, để mở lại app nhiều lần không sinh bản trùng.
enum OccurrenceFactory {
    static func key(templateID: UUID, day: DayKey) -> String {
        "t:\(templateID.uuidString.lowercased())|\(day.string)"
    }

    static func oneOffKey(id: UUID) -> String {
        "o:\(id.uuidString.lowercased())"
    }

    static func make(from template: TaskTemplateRecord, day: DayKey, now: Date) -> TaskOccurrenceRecord {
        TaskOccurrenceRecord(
            id: UUID(),
            occurrenceKey: key(templateID: template.id, day: day),
            templateID: template.id,
            day: day,
            startMinute: template.startMinute,
            durationMinutes: template.durationMinutes,
            title: template.title,
            notes: template.notes,
            category: template.category,
            priority: template.priority,
            isFixed: template.isFixed,
            reminderOffsetMinutes: template.reminderOffsetMinutes,
            status: .open,
            completedAt: nil,
            isDetached: false,
            isRemoved: false,
            createdAt: now,
            updatedAt: now,
            subtasks: template.subtasks.map(Subtasks.fresh)
        )
    }

    /// Occurrence còn thiếu cho các ngày `days`. Không tạo nếu khóa đã tồn tại (kể cả bia mộ
    /// hoặc lần đã bị chuyển sang ngày khác — chúng vẫn giữ khóa gốc).
    static func missing(
        templates: [TaskTemplateRecord],
        existingKeys: Set<String>,
        days: [DayKey],
        calendar: Calendar,
        now: Date
    ) -> [TaskOccurrenceRecord] {
        var keys = existingKeys
        var result: [TaskOccurrenceRecord] = []
        for template in templates {
            for day in days where template.recurrence.occurs(on: day, calendar: calendar) {
                let k = key(templateID: template.id, day: day)
                guard !keys.contains(k) else { continue }
                keys.insert(k)
                result.append(make(from: template, day: day, now: now))
            }
        }
        return result
    }

    static func makeOneOff(from draft: TaskDraft, now: Date) -> TaskOccurrenceRecord {
        let id = UUID()
        return TaskOccurrenceRecord(
            id: id,
            occurrenceKey: oneOffKey(id: id),
            templateID: nil,
            day: draft.day,
            startMinute: draft.day == nil ? nil : draft.startMinute,
            durationMinutes: draft.durationMinutes,
            title: draft.trimmedTitle,
            notes: draft.notes,
            category: draft.category,
            priority: draft.priority,
            isFixed: draft.isFixed,
            reminderOffsetMinutes: draft.startMinute == nil ? nil : draft.reminderOffsetMinutes,
            status: .open,
            completedAt: nil,
            isDetached: false,
            isRemoved: false,
            createdAt: now,
            updatedAt: now,
            subtasks: nilIfEmpty(Subtasks.normalized(draft.subtasks))
        )
    }

    private static func nilIfEmpty(_ list: [Subtask]) -> [Subtask]? { list.isEmpty ? nil : list }

    static func makeTemplate(from draft: TaskDraft, startDay: DayKey, now: Date) -> TaskTemplateRecord? {
        guard let frequency = draft.repeatFrequency else { return nil }
        return TaskTemplateRecord(
            id: UUID(),
            title: draft.trimmedTitle,
            notes: draft.notes,
            category: draft.category,
            priority: draft.priority,
            startMinute: draft.startMinute,
            durationMinutes: draft.durationMinutes,
            isFixed: draft.isFixed,
            reminderOffsetMinutes: draft.startMinute == nil ? nil : draft.reminderOffsetMinutes,
            recurrence: RecurrenceRule(
                frequency: frequency,
                weekdays: Array(draft.repeatWeekdays),
                startDay: startDay,
                endDay: draft.repeatEndDay
            ),
            createdAt: now,
            subtasks: nilIfEmpty(Subtasks.fresh(Subtasks.normalized(draft.subtasks)))
        )
    }
}

extension TaskOccurrenceRecord {
    /// Chép nội dung từ form vào occurrence (không đổi id, khóa, trạng thái hoàn thành).
    mutating func apply(_ draft: TaskDraft, now: Date) {
        title = draft.trimmedTitle
        notes = draft.notes
        category = draft.category
        priority = draft.priority
        day = draft.day
        startMinute = draft.day == nil ? nil : draft.startMinute
        durationMinutes = draft.durationMinutes
        isFixed = draft.isFixed
        reminderOffsetMinutes = startMinute == nil ? nil : draft.reminderOffsetMinutes
        checklist = Subtasks.normalized(draft.subtasks)
        updatedAt = now
    }

    /// Chép nội dung từ mẫu (dùng khi sửa "lần này trở đi") — giữ nguyên ngày của occurrence.
    mutating func apply(template: TaskTemplateRecord, now: Date) {
        title = template.title
        notes = template.notes
        category = template.category
        priority = template.priority
        startMinute = template.startMinute
        durationMinutes = template.durationMinutes
        isFixed = template.isFixed
        reminderOffsetMinutes = template.reminderOffsetMinutes
        checklist = Subtasks.merge(template: template.checklist, keepingStateFrom: checklist)
        updatedAt = now
    }
}

extension TaskTemplateRecord {
    mutating func apply(_ draft: TaskDraft) {
        title = draft.trimmedTitle
        notes = draft.notes
        category = draft.category
        priority = draft.priority
        startMinute = draft.startMinute
        durationMinutes = draft.durationMinutes
        isFixed = draft.isFixed
        reminderOffsetMinutes = draft.startMinute == nil ? nil : draft.reminderOffsetMinutes
        checklist = Subtasks.fresh(Subtasks.normalized(draft.subtasks))
        if let frequency = draft.repeatFrequency {
            recurrence = RecurrenceRule(
                frequency: frequency,
                weekdays: Array(draft.repeatWeekdays),
                startDay: recurrence.startDay,
                endDay: draft.repeatEndDay
            )
        }
    }
}
