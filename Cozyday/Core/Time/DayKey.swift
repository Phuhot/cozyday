import Foundation

/// Ngày theo lịch địa phương của người dùng (năm-tháng-ngày), không gắn múi giờ.
/// Dùng làm "khóa ngày" cho task, nhật ký, thống kê. Không bao giờ suy ra từ việc cắt ngày UTC.
struct DayKey: Hashable, Comparable, Codable, CustomStringConvertible {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// Ngày địa phương chứa thời điểm `date` theo `calendar` (calendar mang múi giờ của thiết bị).
    init(_ date: Date, calendar: Calendar) {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: c.year ?? 1970, month: c.month ?? 1, day: c.day ?? 1)
    }

    /// Đọc chuỗi "yyyy-MM-dd". Trả về nil nếu sai định dạng hoặc ngày không tồn tại.
    init?(string: String) {
        let parts = string.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]),
              (1...12).contains(m), (1...31).contains(d) else { return nil }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? cal.timeZone
        guard let date = cal.date(from: DateComponents(year: y, month: m, day: d)),
              cal.component(.day, from: date) == d,
              cal.component(.month, from: date) == m else { return nil }
        self.init(year: y, month: m, day: d)
    }

    var string: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    var description: String { string }

    static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    /// Thời điểm bắt đầu ngày này theo lịch/múi giờ của `calendar`.
    func startDate(in calendar: Calendar) -> Date {
        let comps = DateComponents(year: year, month: month, day: day)
        return calendar.date(from: comps).map { calendar.startOfDay(for: $0) } ?? Date(timeIntervalSince1970: 0)
    }

    /// Thời điểm tuyệt đối của giờ địa phương `minute` (phút tính từ 00:00) trong ngày này.
    /// Dùng Calendar nên ngày đổi giờ mùa hè (23/25 giờ) vẫn đúng giờ đồng hồ.
    func date(atMinute minute: Int, in calendar: Calendar) -> Date {
        let clamped = max(0, min(minute, 24 * 60 - 1))
        let start = startDate(in: calendar)
        return calendar.date(bySettingHour: clamped / 60, minute: clamped % 60, second: 0, of: start)
            ?? start.addingTimeInterval(TimeInterval(clamped * 60))
    }

    /// Cộng/trừ số ngày theo lịch (không cộng 86.400 giây).
    func adding(days: Int, calendar: Calendar) -> DayKey {
        let base = startDate(in: calendar)
        guard let moved = calendar.date(byAdding: .day, value: days, to: base) else { return self }
        return DayKey(moved, calendar: calendar)
    }

    /// Thứ trong tuần theo quy ước Calendar: 1 = Chủ nhật, 2 = Thứ hai, …, 7 = Thứ bảy.
    func weekday(calendar: Calendar) -> Int {
        calendar.component(.weekday, from: startDate(in: calendar))
    }

    /// Số ngày từ `self` đến `other` (âm nếu `other` trước `self`).
    func days(to other: DayKey, calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: startDate(in: calendar), to: other.startDate(in: calendar)).day ?? 0
    }

    /// Danh sách ngày liên tiếp từ `self` đến `end` (bao gồm cả hai đầu). Rỗng nếu end < self.
    func through(_ end: DayKey, calendar: Calendar) -> [DayKey] {
        guard self <= end else { return [] }
        var result: [DayKey] = []
        var cursor = self
        while cursor <= end {
            result.append(cursor)
            cursor = cursor.adding(days: 1, calendar: calendar)
            if result.count > 3700 { break } // chặn vòng lặp vô hạn nếu dữ liệu bất thường
        }
        return result
    }

    // MARK: Codable dưới dạng chuỗi "yyyy-MM-dd"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let key = DayKey(string: raw) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Ngày không hợp lệ: \(raw)")
        }
        self = key
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(string)
    }
}
