import Foundation

enum TaskValidationError: Error, Equatable {
    case emptyTitle
    case titleTooLong(max: Int)
    case invalidDuration(min: Int, max: Int)
    case invalidStart
    case crossesMidnight(endMinute: Int)
    case weeklyWithoutWeekdays
    case repeatNeedsDay
    case endBeforeStart
    case tooManySubtasks(max: Int)

    var message: String {
        switch self {
        case .emptyTitle:
            return "Hãy đặt tên cho việc."
        case .titleTooLong(let max):
            return "Tên việc dài quá \(max) ký tự."
        case .invalidDuration(let min, let max):
            return "Thời lượng cần từ \(min) phút đến \(max / 60) giờ."
        case .invalidStart:
            return "Giờ bắt đầu không hợp lệ."
        case .crossesMidnight(let end):
            return "Việc kết thúc lúc \(TimeOfDay.label(end)) của ngày hôm sau. Bản này chưa hỗ trợ việc qua nửa đêm — hãy rút ngắn hoặc tách thành hai việc."
        case .weeklyWithoutWeekdays:
            return "Chọn ít nhất một thứ trong tuần để lặp."
        case .repeatNeedsDay:
            return "Việc lặp lại cần có ngày bắt đầu."
        case .endBeforeStart:
            return "Ngày kết thúc lặp phải sau ngày bắt đầu."
        case .tooManySubtasks(let max):
            return "Mỗi việc có tối đa \(max) việc con."
        }
    }
}

enum TaskValidation {
    static let maxTitleLength = 120
    static let minDuration = 5
    static let maxDuration = 12 * 60

    static func validate(_ draft: TaskDraft) -> TaskValidationError? {
        let title = draft.trimmedTitle
        if title.isEmpty { return .emptyTitle }
        if title.count > maxTitleLength { return .titleTooLong(max: maxTitleLength) }
        if draft.durationMinutes < minDuration || draft.durationMinutes > maxDuration {
            return .invalidDuration(min: minDuration, max: maxDuration)
        }
        if let start = draft.startMinute {
            if start < 0 || start >= TimeOfDay.minutesPerDay { return .invalidStart }
            let end = start + draft.durationMinutes
            if end > TimeOfDay.minutesPerDay { return .crossesMidnight(endMinute: end - TimeOfDay.minutesPerDay) }
        }
        if Subtasks.normalized(draft.subtasks).count < draft.subtasks.filter({ !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }).count {
            return .tooManySubtasks(max: Subtasks.maxCount)
        }
        if let frequency = draft.repeatFrequency {
            guard let day = draft.day else { return .repeatNeedsDay }
            if frequency == .weekly && draft.repeatWeekdays.isEmpty { return .weeklyWithoutWeekdays }
            if let end = draft.repeatEndDay, end < day { return .endBeforeStart }
        }
        return nil
    }
}
