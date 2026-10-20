import Foundation
import EventKit
import Observation

/// Một sự kiện đọc từ app Lịch của iPhone, đã cắt theo một ngày. Chỉ để hiển thị —
/// Cozyday không lưu, không sửa, không đưa vào bản sao lưu.
struct CalendarEvent: Identifiable, Equatable {
    let id: UUID
    let title: String
    let startMinute: Int
    let durationMinutes: Int
    let isAllDay: Bool
    let calendarTitle: String
}

/// Đọc (chỉ đọc) sự kiện từ app Lịch, khi người dùng bật trong Cài đặt.
@MainActor
@Observable
final class CalendarService {
    enum Access: Equatable {
        case notDetermined, granted, denied
    }

    private static let enabledKey = "calendar.showEvents"
    private let store = EKEventStore()
    @ObservationIgnored private var observer: NSObjectProtocol?

    private(set) var access: Access = .notDetermined
    /// Tăng khi app Lịch thay đổi → view đọc lại sự kiện.
    private(set) var revision = 0
    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey) }
    }

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        refreshAccess()
        observer = NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: store, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.revision += 1 }
        }
    }

    func refreshAccess() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess: access = .granted
        case .notDetermined: access = .notDetermined
        default: access = .denied
        }
    }

    /// Bật hiển thị: xin quyền đọc lịch nếu chưa có. Trả về true nếu đọc được.
    func enable() async -> Bool {
        if PreviewMode.current != nil { return false }
        refreshAccess()
        if access == .notDetermined {
            _ = try? await store.requestFullAccessToEvents()
            refreshAccess()
        }
        isEnabled = access == .granted
        return isEnabled
    }

    var isActive: Bool { isEnabled && access == .granted }

    func events(on day: DayKey, calendar: Calendar) -> [CalendarEvent] {
        guard isActive else { return [] }
        let start = day.startDate(in: calendar)
        let end = day.adding(days: 1, calendar: calendar).startDate(in: calendar)
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).compactMap { e in
            guard let s = e.startDate, let f = e.endDate else { return nil }
            let from = max(s, start), to = min(f, end)
            let startMinute = e.isAllDay ? 0 : calendar.minuteOfDay(from)
            let endMinute = e.isAllDay ? TimeOfDay.minutesPerDay : (to >= end ? TimeOfDay.minutesPerDay : calendar.minuteOfDay(to))
            let key = (e.calendarItemIdentifier) + "|" + day.string
            return CalendarEvent(
                id: UUID.stable(key),
                title: (e.title?.isEmpty == false ? e.title! : "Sự kiện"),
                startMinute: startMinute,
                durationMinutes: max(5, endMinute - startMinute),
                isAllDay: e.isAllDay,
                calendarTitle: e.calendar?.title ?? ""
            )
        }
        .sorted { ($0.startMinute, $0.title) < ($1.startMinute, $1.title) }
    }
}

extension UUID {
    /// UUID cố định từ một chuỗi (để danh sách hiển thị không nhấp nháy khi vẽ lại).
    static func stable(_ s: String) -> UUID {
        let a = Adventure.stableHash("a|" + s), b = Adventure.stableHash("b|" + s)
        var bytes = [UInt8](repeating: 0, count: 16)
        for i in 0..<8 {
            bytes[i] = UInt8(truncatingIfNeeded: a >> (UInt64(i) * 8))
            bytes[8 + i] = UInt8(truncatingIfNeeded: b >> (UInt64(i) * 8))
        }
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}
