import Foundation

enum TaskStatus: String, Codable, CaseIterable {
    case open
    case done
    case skipped
}

enum TaskPriority: Int, Codable, CaseIterable, Comparable {
    case low = 0
    case normal = 1
    case high = 2

    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .low: return "Thấp"
        case .normal: return "Vừa"
        case .high: return "Cao"
        }
    }
}

/// Nhóm việc. Màu của từng nhóm nằm trong DesignSystem (UI), ở đây chỉ có định danh + tên.
enum TaskCategory: String, Codable, CaseIterable, Identifiable {
    case study
    case work
    case health
    case personal
    case home

    var id: String { rawValue }

    var label: String {
        switch self {
        case .study: return "Học tập"
        case .work: return "Công việc"
        case .health: return "Sức khỏe"
        case .personal: return "Cá nhân"
        case .home: return "Nhà cửa"
        }
    }
}

/// Bản ghi một mẫu việc lặp lại (recurring template).
struct TaskTemplateRecord: Codable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var notes: String
    var category: TaskCategory
    var priority: TaskPriority
    var startMinute: Int?
    var durationMinutes: Int
    var isFixed: Bool
    var reminderOffsetMinutes: Int?
    var recurrence: RecurrenceRule
    var createdAt: Date
}

/// Bản ghi một lần xuất hiện cụ thể của việc (occurrence). Việc một lần cũng là occurrence
/// (templateID = nil). `day == nil` nghĩa là việc nằm trong Hộp chờ (chưa xếp ngày).
struct TaskOccurrenceRecord: Codable, Equatable, Identifiable {
    var id: UUID
    /// Khóa ổn định: "t:<templateID>|<yyyy-MM-dd>" cho việc lặp, "o:<id>" cho việc một lần.
    var occurrenceKey: String
    var templateID: UUID?
    var day: DayKey?
    var startMinute: Int?
    var durationMinutes: Int
    var title: String
    var notes: String
    var category: TaskCategory
    var priority: TaskPriority
    var isFixed: Bool
    var reminderOffsetMinutes: Int?
    var status: TaskStatus
    var completedAt: Date?
    /// Đã được sửa riêng "chỉ lần này" — sửa mẫu về sau không ghi đè lần này.
    var isDetached: Bool
    /// Bia mộ: lần lặp đã bị xóa "chỉ lần này", giữ lại để không bị tạo lại.
    var isRemoved: Bool
    var createdAt: Date
    var updatedAt: Date

    var isScheduled: Bool { day != nil && startMinute != nil }
    var endMinute: Int? { startMinute.map { $0 + durationMinutes } }
    var isRecurring: Bool { templateID != nil }
}

/// Nội dung người dùng nhập trong form việc — dùng chung cho tạo mới và chỉnh sửa.
struct TaskDraft: Equatable {
    var title: String = ""
    var notes: String = ""
    var category: TaskCategory = .personal
    var priority: TaskPriority = .normal
    var day: DayKey?
    var startMinute: Int?
    var durationMinutes: Int = 30
    var isFixed: Bool = false
    var reminderOffsetMinutes: Int?
    var repeatFrequency: RecurrenceFrequency?
    var repeatWeekdays: Set<Int> = []
    var repeatEndDay: DayKey?

    var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
}

extension TaskDraft {
    init(occurrence o: TaskOccurrenceRecord, template: TaskTemplateRecord?) {
        self.init(
            title: o.title, notes: o.notes, category: o.category, priority: o.priority,
            day: o.day, startMinute: o.startMinute, durationMinutes: o.durationMinutes,
            isFixed: o.isFixed, reminderOffsetMinutes: o.reminderOffsetMinutes,
            repeatFrequency: template?.recurrence.frequency,
            repeatWeekdays: Set(template?.recurrence.weekdays ?? []),
            repeatEndDay: template?.recurrence.endDay
        )
    }
}

/// Phạm vi áp dụng khi sửa/xóa một lần của việc lặp.
enum RecurringScope: Equatable {
    case thisOnly
    case thisAndFuture
}
