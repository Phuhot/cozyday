import Foundation
import SwiftData

extension AppStore {
    // MARK: Đọc

    /// Việc của một ngày (không gồm bia mộ), việc có giờ xếp theo giờ, việc chưa xếp giờ ở cuối.
    func tasks(on day: DayKey) -> [TaskOccurrenceRecord] {
        occurrences
            .filter { $0.day == day && !$0.isRemoved }
            .sorted { a, b in
                switch (a.startMinute, b.startMinute) {
                case let (x?, y?) where x != y: return x < y
                case (nil, _?): return false
                case (_?, nil): return true
                default: return a.createdAt < b.createdAt
                }
            }
    }

    /// Hộp chờ: việc chưa xếp ngày.
    var inbox: [TaskOccurrenceRecord] {
        occurrences
            .filter { $0.day == nil && !$0.isRemoved }
            .sorted { a, b in
                if a.status != b.status { return a.status == .open }
                if a.priority != b.priority { return a.priority > b.priority }
                return a.createdAt < b.createdAt
            }
    }

    func occurrence(_ id: UUID) -> TaskOccurrenceRecord? {
        occurrences.first { $0.id == id && !$0.isRemoved }
    }

    func template(_ id: UUID?) -> TaskTemplateRecord? {
        guard let id else { return nil }
        return templates.first { $0.id == id }
    }

    // MARK: Sinh occurrence từ mẫu lặp

    /// Đảm bảo các ngày `days` đã có occurrence cho mọi mẫu lặp. An toàn khi gọi lặp lại nhiều lần.
    func ensureOccurrences(for days: [DayKey]) throws {
        let missing = OccurrenceFactory.missing(
            templates: templates, existingKeys: Set(occurrences.map(\.occurrenceKey)),
            days: days, calendar: calendar, now: now
        )
        guard !missing.isEmpty else { return }
        try commit {
            for occ in missing {
                self.context.insert(TaskOccurrenceModel(record: occ))
                self.occurrences.append(occ)
            }
        }
    }

    /// Hôm nay và 7 ngày tới — đủ cho timeline và cửa sổ nhắc việc.
    func ensureUpcomingOccurrences() throws {
        try ensureOccurrences(for: today.through(today.adding(days: ReminderPlanner.horizonDays, calendar: calendar), calendar: calendar))
    }

    // MARK: Tạo / sửa / xóa

    @discardableResult
    func createTask(_ draft: TaskDraft) throws -> UUID? {
        if let error = TaskValidation.validate(draft) { throw StoreError.invalid(error.message) }
        if draft.repeatFrequency != nil, let startDay = draft.day {
            guard let template = OccurrenceFactory.makeTemplate(from: draft, startDay: startDay, now: now) else { return nil }
            try commit {
                self.context.insert(TaskTemplateModel(record: template))
                self.templates.append(template)
            }
            let window = startDay.through(max(startDay, today).adding(days: ReminderPlanner.horizonDays, calendar: calendar), calendar: calendar)
            try ensureOccurrences(for: window)
            return occurrences.first { $0.templateID == template.id && $0.day == startDay }?.id
        }
        let occ = OccurrenceFactory.makeOneOff(from: draft, now: now)
        try commit {
            self.context.insert(TaskOccurrenceModel(record: occ))
            self.occurrences.append(occ)
        }
        return occ.id
    }

    func updateTask(id: UUID, draft: TaskDraft, scope: RecurringScope) throws {
        if let error = TaskValidation.validate(draft) { throw StoreError.invalid(error.message) }
        guard let current = occurrence(id) else { throw StoreError.notFound }

        // Việc một lần được bật "lặp lại": tạo mẫu lặp bắt đầu từ ngày của việc; chính việc này trở thành
        // lần đầu tiên (giữ id, trạng thái và thưởng đã nhận).
        if current.templateID == nil, draft.repeatFrequency != nil, let startDay = draft.day {
            guard let template = OccurrenceFactory.makeTemplate(from: draft, startDay: startDay, now: now) else { return }
            var updated = current
            updated.apply(draft, now: now)
            updated.templateID = template.id
            updated.occurrenceKey = OccurrenceFactory.key(templateID: template.id, day: startDay)
            try commit {
                self.context.insert(TaskTemplateModel(record: template))
                self.templates.append(template)
                try self.occurrenceModel(updated.id).apply(updated)
                self.replaceCached(updated)
            }
            try ensureOccurrences(for: startDay.through(max(startDay, today).adding(days: ReminderPlanner.horizonDays, calendar: calendar), calendar: calendar))
            return
        }

        // Tắt lặp từ lần này: chuỗi kết thúc hôm trước, lần này thành việc một lần.
        if scope == .thisAndFuture, draft.repeatFrequency == nil, let template = template(current.templateID),
           let originalDay = RecurringEdit.originalDay(of: current) {
            var changes = RecurringEdit.deleteThisAndFuture(
                template: template, from: originalDay,
                occurrences: occurrences.filter { $0.id != current.id }, calendar: calendar
            )
            var single = current
            single.apply(draft, now: now)
            single.templateID = nil
            single.isDetached = false
            single.occurrenceKey = OccurrenceFactory.oneOffKey(id: single.id)
            changes.upsertOccurrences.append(single)
            try apply(changes)
            return
        }

        // Việc một lần, hoặc chỉ sửa lần này của việc lặp.
        guard scope == .thisAndFuture, let template = template(current.templateID),
              let originalDay = RecurringEdit.originalDay(of: current) else {
            var updated = current
            updated.apply(draft, now: now)
            if updated.templateID != nil { updated.isDetached = true }
            try saveOccurrence(updated)
            return
        }

        let changes = RecurringEdit.editThisAndFuture(
            template: template, from: originalDay, draft: draft,
            occurrences: occurrences, calendar: calendar, now: now
        )
        try apply(changes)
        try ensureUpcomingOccurrences()
    }

    func deleteTask(id: UUID, scope: RecurringScope) throws {
        guard let current = occurrence(id) else { throw StoreError.notFound }
        if current.templateID == nil {
            // Việc một lần: xóa hẳn. Sổ cái thưởng là bảng riêng nên không bị xóa theo
            // (không thể nhận lại thưởng bằng cách xóa rồi hoàn thành lại cùng lần việc này).
            try commit {
                self.context.delete(try self.occurrenceModel(id))
                self.occurrences.removeAll { $0.id == id }
            }
            return
        }
        if scope == .thisOnly || template(current.templateID) == nil {
            var tomb = current
            tomb.isRemoved = true
            tomb.updatedAt = now
            try saveOccurrence(tomb)
            return
        }
        guard let template = template(current.templateID), let originalDay = RecurringEdit.originalDay(of: current) else {
            throw StoreError.notFound
        }
        let changes = RecurringEdit.deleteThisAndFuture(
            template: template, from: originalDay, occurrences: occurrences, calendar: calendar
        )
        try apply(changes)
    }

    /// Chuyển việc sang ngày khác (hoặc về Hộp chờ nếu `day == nil`). Việc lặp: chỉ lần này.
    func moveTask(id: UUID, to day: DayKey?, startMinute: Int?) throws {
        guard var occ = occurrence(id) else { throw StoreError.notFound }
        if let start = startMinute, start + occ.durationMinutes > TimeOfDay.minutesPerDay {
            throw StoreError.invalid(TaskValidationError.crossesMidnight(endMinute: start + occ.durationMinutes - TimeOfDay.minutesPerDay).message)
        }
        occ.day = day
        occ.startMinute = day == nil ? nil : startMinute
        if occ.startMinute == nil { occ.reminderOffsetMinutes = nil }
        if occ.templateID != nil { occ.isDetached = true }
        occ.updatedAt = now
        try saveOccurrence(occ)
    }

    // MARK: Trạng thái + thưởng

    /// Đánh dấu / bỏ đánh dấu một việc con. Không có thưởng riêng.
    func toggleSubtask(occurrenceID: UUID, subtaskID: UUID) throws {
        guard var occ = occurrence(occurrenceID) else { throw StoreError.notFound }
        var list = occ.checklist
        guard let i = list.firstIndex(where: { $0.id == subtaskID }) else { throw StoreError.notFound }
        list[i].isDone.toggle()
        occ.checklist = list
        occ.updatedAt = now
        try saveOccurrence(occ)
    }

    /// Đổi trạng thái. Lần đầu hoàn thành → ghi một dòng thưởng (cùng một lần save).
    /// Trả về dòng thưởng nếu vừa được nhận (để UI chạy hiệu ứng).
    @discardableResult
    func setStatus(id: UUID, to status: TaskStatus) throws -> LedgerEntry? {
        guard var occ = occurrence(id) else { throw StoreError.notFound }
        guard occ.status != status else { return nil }
        occ.status = status
        occ.completedAt = status == .done ? now : nil
        occ.updatedAt = now
        var granted: LedgerEntry?
        try commit {
            try self.occurrenceModel(id).apply(occ)
            self.replaceCached(occ)
            if status == .done, let entry = RewardPolicy.forTaskCompletion(
                occurrence: occ, existingKeys: self.ledgerKeys,
                rewardedToday: RewardPolicy.taskRewardsToday(self.ledger, now: self.now, calendar: self.calendar), now: self.now) {
                self.insertLedger(entry)
                granted = entry
            }
        }
        return granted
    }

    // MARK: Replan

    /// `busy`: khoảng thời gian bận khác (ví dụ sự kiện từ app Lịch) — coi như việc cố định, không bao giờ bị dời.
    func replanPlan(for day: DayKey, includeUnscheduled: Bool, busy: [(start: Int, duration: Int)] = []) -> Replanner.Plan {
        let items = tasks(on: day)
        let isToday = day == today
        let nowMinute = isToday ? calendar.minuteOfDay(now) : (day < today ? TimeOfDay.minutesPerDay : 0)
        var tasks = items.enumerated().map { index, o in
            Replanner.Task(
                id: o.id, start: o.startMinute, duration: o.durationMinutes, isFixed: o.isFixed,
                isFinished: o.status != .open, priority: o.priority, order: index
            )
        }
        for (i, b) in busy.enumerated() {
            tasks.append(Replanner.Task(id: UUID(), start: b.start, duration: b.duration, isFixed: true,
                                        isFinished: false, priority: .normal, order: items.count + i))
        }
        return Replanner.plan(
            tasks: tasks, nowMinute: nowMinute,
            activeStart: profile.activeStartMinute, activeEnd: profile.activeEndMinute,
            includeUnscheduled: includeUnscheduled
        )
    }

    func applyReplan(_ plan: Replanner.Plan) throws {
        let updates: [TaskOccurrenceRecord] = plan.moves.compactMap { move in
            guard var occ = occurrence(move.id), occ.status == .open, !occ.isFixed else { return nil }
            occ.startMinute = move.to
            if occ.templateID != nil { occ.isDetached = true }
            occ.updatedAt = now
            return occ
        }
        try commit {
            for occ in updates {
                try self.occurrenceModel(occ.id).apply(occ)
                self.replaceCached(occ)
            }
        }
    }

    // MARK: Nội bộ

    func saveOccurrence(_ occ: TaskOccurrenceRecord) throws {
        try commit {
            try self.occurrenceModel(occ.id).apply(occ)
            self.replaceCached(occ)
        }
    }

    func replaceCached(_ occ: TaskOccurrenceRecord) {
        if let i = occurrences.firstIndex(where: { $0.id == occ.id }) {
            occurrences[i] = occ
        } else {
            occurrences.append(occ)
        }
    }

    private func apply(_ changes: RecurringChangeSet) throws {
        try commit {
            for t in changes.upsertTemplates {
                if let model = try? self.templateModel(t.id) {
                    model.apply(t)
                } else {
                    self.context.insert(TaskTemplateModel(record: t))
                }
                if let i = self.templates.firstIndex(where: { $0.id == t.id }) {
                    self.templates[i] = t
                } else {
                    self.templates.append(t)
                }
            }
            for id in changes.deleteTemplateIDs {
                self.context.delete(try self.templateModel(id))
                self.templates.removeAll { $0.id == id }
            }
            for o in changes.upsertOccurrences {
                try self.occurrenceModel(o.id).apply(o)
                self.replaceCached(o)
            }
            for id in changes.deleteOccurrenceIDs {
                self.context.delete(try self.occurrenceModel(id))
                self.occurrences.removeAll { $0.id == id }
            }
        }
    }
}
