import Foundation

/// Tiện ích hiển thị giờ dạng "08:30" từ số phút tính từ nửa đêm.
enum TimeOfDay {
    static let minutesPerDay = 24 * 60

    static func label(_ minute: Int) -> String {
        let m = ((minute % minutesPerDay) + minutesPerDay) % minutesPerDay
        return String(format: "%02d:%02d", m / 60, m % 60)
    }

    static func rangeLabel(start: Int, duration: Int) -> String {
        "\(label(start))–\(label(start + duration))"
    }

    /// "1 giờ 30 phút", "45 phút", "2 giờ".
    static func durationLabel(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        switch (h, m) {
        case (0, _): return "\(m) phút"
        case (_, 0): return "\(h) giờ"
        default: return "\(h) giờ \(m) phút"
        }
    }

    /// Làm tròn lên bội số `step` phút.
    static func roundUp(_ minute: Int, step: Int) -> Int {
        guard step > 0 else { return minute }
        return ((minute + step - 1) / step) * step
    }
}
