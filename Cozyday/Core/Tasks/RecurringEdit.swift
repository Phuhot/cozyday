import Foundation

/// Kết quả thay đổi dữ liệu khi sửa/xóa việc lặp. Lớp lưu trữ áp dụng toàn bộ trong một lần save.
struct RecurringChangeSet: Equatable {
    var upsertTemplates: [TaskTemplateRecord] = []
    var deleteTemplateIDs: [UUID] = []
    var upsertOccurrences: [TaskOccurrenceRecord] = []
    var deleteOccurrenceIDs: [UUID] = []
}

/// Quy tắc sửa/xóa việc lặp:
/// - "Chỉ lần này": chỉ đổi occurrence đó và đánh dấu tách riêng (isDetached).
/// - "Lần này trở đi": mẫu cũ kết thúc ngày hôm trước, mẫu mới bắt đầu từ ngày này.
///   Lịch sử trước ngày này không bị đổi. Các lần đã hoàn thành/bỏ qua giữ nguyên nội dung.
enum RecurringEdit {
    static func editThisAndFuture(
        template: TaskTemplateRecord,
        from day: DayKey,
        draft: TaskDraft,
        occurrences: [TaskOccurrenceRecord],
        calendar: Calendar,
        now: Date
    ) -> RecurringChangeSet {
        var changes = RecurringChangeSet()
        let target: TaskTemplateRecord

        if day <= template.recurrence.startDay {
            // Sửa từ lần đầu tiên: sửa mẫu tại chỗ, giữ id.
            var updated = template
            updated.apply(draft)
            target = updated
        } else {
            var old = template
            old.recurrence.endDay = day.adding(days: -1, calendar: calendar)
            var fresh = template
            fresh.id = UUID()
            fresh.createdAt = now
            fresh.recurrence.startDay = day
            fresh.apply(draft)
            changes.upsertTemplates.append(old)
            target = fresh
        }
        changes.upsertTemplates.append(target)

        for var occ in occurrences where occ.templateID == template.id {
            guard let occDay = originalDay(of: occ), occDay >= day else { continue }
            occ.templateID = target.id
            occ.occurrenceKey = OccurrenceFactory.key(templateID: target.id, day: occDay)
            if occ.status == .open && !occ.isDetached && !occ.isRemoved {
                occ.apply(template: target, now: now)
            }
            // Nếu lịch mới không còn rơi vào ngày này thì bỏ lần chưa làm (giữ lần đã xong).
            if !target.recurrence.occurs(on: occDay, calendar: calendar) && occ.status == .open && !occ.isDetached {
                changes.deleteOccurrenceIDs.append(occ.id)
                continue
            }
            changes.upsertOccurrences.append(occ)
        }
        return changes
    }

    static func deleteThisAndFuture(
        template: TaskTemplateRecord,
        from day: DayKey,
        occurrences: [TaskOccurrenceRecord],
        calendar: Calendar
    ) -> RecurringChangeSet {
        var changes = RecurringChangeSet()
        if day <= template.recurrence.startDay {
            changes.deleteTemplateIDs.append(template.id)
        } else {
            var old = template
            old.recurrence.endDay = day.adding(days: -1, calendar: calendar)
            changes.upsertTemplates.append(old)
        }
        for occ in occurrences where occ.templateID == template.id {
            guard let occDay = originalDay(of: occ), occDay >= day else { continue }
            // Giữ lần đã hoàn thành/bỏ qua làm lịch sử; xóa lần chưa làm và bia mộ.
            if occ.status == .open || occ.isRemoved {
                changes.deleteOccurrenceIDs.append(occ.id)
            }
        }
        return changes
    }

    /// Ngày gốc của occurrence lặp lấy từ khóa (occurrence có thể đã bị chuyển sang ngày khác).
    static func originalDay(of occurrence: TaskOccurrenceRecord) -> DayKey? {
        guard occurrence.occurrenceKey.hasPrefix("t:"),
              let bar = occurrence.occurrenceKey.lastIndex(of: "|") else { return occurrence.day }
        return DayKey(string: String(occurrence.occurrenceKey[occurrence.occurrenceKey.index(after: bar)...]))
    }
}
