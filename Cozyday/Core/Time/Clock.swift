import Foundation

/// Nguồn thời gian có thể thay thế trong test.
protocol AppClock {
    var now: Date { get }
}

struct SystemClock: AppClock {
    var now: Date { Date() }
}

/// Đồng hồ cố định/điều khiển được cho test.
final class ManualClock: AppClock {
    var now: Date
    init(_ now: Date) { self.now = now }
    func advance(seconds: TimeInterval) { now = now.addingTimeInterval(seconds) }
}

extension Calendar {
    /// Lịch Gregorian với múi giờ chỉ định — dùng trong test và khi cần cố định múi giờ.
    static func gregorian(timeZone: TimeZone) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        cal.locale = Locale(identifier: "vi_VN")
        cal.firstWeekday = 2 // tuần bắt đầu Thứ hai
        return cal
    }

    /// Phút trong ngày (0…1439) của thời điểm `date` theo giờ địa phương.
    func minuteOfDay(_ date: Date) -> Int {
        let c = dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}
