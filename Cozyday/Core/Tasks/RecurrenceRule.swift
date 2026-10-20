import Foundation

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily
    case weekly

    var label: String {
        switch self {
        case .daily: return "Hằng ngày"
        case .weekly: return "Theo thứ trong tuần"
        }
    }
}

/// Lịch lặp đơn giản: hằng ngày hoặc các thứ đã chọn trong tuần, từ `startDay` tới `endDay`
/// (bao gồm). Không triển khai RRULE đầy đủ. Lặp theo giờ đồng hồ địa phương.
struct RecurrenceRule: Codable, Equatable {
    var frequency: RecurrenceFrequency
    /// 1 = Chủ nhật … 7 = Thứ bảy (quy ước Calendar). Chỉ dùng khi weekly. Luôn được sắp xếp.
    var weekdays: [Int]
    var startDay: DayKey
    var endDay: DayKey?

    init(frequency: RecurrenceFrequency, weekdays: [Int] = [], startDay: DayKey, endDay: DayKey? = nil) {
        self.frequency = frequency
        self.weekdays = Array(Set(weekdays.filter { (1...7).contains($0) })).sorted()
        self.startDay = startDay
        self.endDay = endDay
    }

    func occurs(on day: DayKey, calendar: Calendar) -> Bool {
        guard day >= startDay else { return false }
        if let endDay, day > endDay { return false }
        switch frequency {
        case .daily:
            return true
        case .weekly:
            return weekdays.contains(day.weekday(calendar: calendar))
        }
    }

    /// Các ngày có lần lặp trong khoảng [from, through].
    func days(from: DayKey, through: DayKey, calendar: Calendar) -> [DayKey] {
        let lower = max(from, startDay)
        let upper = endDay.map { min($0, through) } ?? through
        return lower.through(upper, calendar: calendar).filter { occurs(on: $0, calendar: calendar) }
    }

    /// Mô tả ngắn: "Hằng ngày", "T2, T4, T6", kèm "đến 31/12" nếu có ngày kết thúc.
    var summary: String {
        var text: String
        switch frequency {
        case .daily:
            text = "Hằng ngày"
        case .weekly:
            let order = [2, 3, 4, 5, 6, 7, 1]
            text = order.filter { weekdays.contains($0) }.map(Weekday.shortLabel).joined(separator: ", ")
            if text.isEmpty { text = "Chưa chọn thứ" }
        }
        if let endDay {
            text += " · đến \(endDay.day)/\(endDay.month)"
        }
        return text
    }
}

enum Weekday {
    /// Thứ tự hiển thị bắt đầu Thứ hai.
    static let displayOrder = [2, 3, 4, 5, 6, 7, 1]

    static func shortLabel(_ weekday: Int) -> String {
        weekday == 1 ? "CN" : "T\(weekday)"
    }

    static func longLabel(_ weekday: Int) -> String {
        let names = ["hai", "ba", "tư", "năm", "sáu", "bảy"]
        guard (2...7).contains(weekday) else { return "Chủ nhật" }
        return "Thứ \(names[weekday - 2])"
    }
}
