import Foundation
import UserNotifications
import Observation

/// Thông báo cục bộ: nhắc việc, kết thúc phiên tập trung, nhắc viết nhật ký.
/// Không có push từ máy chủ. iOS có thể trì hoãn/ẩn thông báo theo Focus và cài đặt người dùng.
@MainActor
@Observable
final class NotificationService {
    enum Permission: Equatable {
        case unknown
        case notDetermined
        case denied
        case authorized
    }

    private(set) var permission: Permission = .unknown
    private let center = UNUserNotificationCenter.current()
    @ObservationIgnored private var syncTask: Task<Void, Never>?

    func refreshPermission() async {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: permission = .authorized
        case .denied: permission = .denied
        case .notDetermined: permission = .notDetermined
        @unknown default: permission = .denied
        }
    }

    /// Chỉ gọi khi người dùng chủ động bật một nhắc nhở. Từ chối vẫn dùng app bình thường.
    @discardableResult
    func requestPermissionIfNeeded() async -> Bool {
        // Khi CI chụp ảnh giao diện: không hiện hộp thoại xin quyền của iOS.
        if PreviewMode.current != nil { return false }
        await refreshPermission()
        if permission == .authorized { return true }
        guard permission == .notDetermined else { return false }
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await refreshPermission()
        return granted
    }

    /// Đồng bộ lại (gộp nhiều thay đổi liên tiếp thành một lần).
    func scheduleSync(store: AppStore) {
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await self?.sync(store: store)
        }
    }

    /// Dựng lại toàn bộ lịch nhắc từ dữ liệu hiện tại (cửa sổ 7 ngày, tối đa 60 nhắc việc).
    func sync(store: AppStore) async {
        await refreshPermission()
        guard permission == .authorized else { return }

        let desired = ReminderPlanner.taskReminders(occurrences: store.occurrences, now: store.now, calendar: store.calendar)
        let pending = await center.pendingNotificationRequests()
        let diff = ReminderPlanner.diff(pendingIDs: Set(pending.map(\.identifier)), desired: desired)
        center.removePendingNotificationRequests(withIdentifiers: diff.remove)
        for request in diff.add {
            add(request, calendar: store.calendar)
        }

        if store.profile.journalReminderEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Một dòng nhật ký?"
            content.body = "Ghi lại tâm trạng hôm nay trong vài giây."
            content.sound = .default
            content.userInfo = ["route": "journal"]
            var comps = DateComponents()
            comps.hour = store.profile.journalReminderMinute / 60
            comps.minute = store.profile.journalReminderMinute % 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            try? await center.add(UNNotificationRequest(identifier: ReminderIDs.journalDaily, content: content, trigger: trigger))
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [ReminderIDs.journalDaily])
        }

        syncFocus(store: store)
    }

    /// Thông báo kết thúc phiên tập trung (hủy khi tạm dừng/kết thúc).
    func syncFocus(store: AppStore) {
        center.removePendingNotificationRequests(withIdentifiers: [ReminderIDs.focusEnd])
        guard permission == .authorized, let session = store.activeFocus,
              let end = session.expectedEnd, end > store.now.addingTimeInterval(1) else { return }
        let content = UNMutableNotificationContent()
        content.title = session.kind == .focus ? "Hết giờ tập trung" : "Hết giờ nghỉ"
        content.body = session.kind == .focus
            ? "\(store.profile.displayPetName) muốn bạn nghỉ một chút."
            : "Sẵn sàng quay lại chưa?"
        content.sound = .default
        content.userInfo = ["route": "focus"]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, end.timeIntervalSince(store.now)), repeats: false)
        center.add(UNNotificationRequest(identifier: ReminderIDs.focusEnd, content: content, trigger: trigger))
    }

    /// Nhắc quay lại khi rời app giữa phiên tập trung. Hủy khi quay lại hoặc khi khóa máy.
    func scheduleFocusNudge(petName: String, strict: Bool, after seconds: TimeInterval) {
        guard permission == .authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "\(petName) vẫn đang tập trung cùng bạn"
        content.body = strict
            ? "Chế độ nghiêm: rời app quá 1 phút thì phiên sẽ dừng và không có thưởng."
            : "Quay lại CozyDay để giữ nhịp phiên này nhé."
        content.sound = .default
        content.userInfo = ["route": "focus"]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        center.add(UNNotificationRequest(identifier: ReminderIDs.focusNudge, content: content, trigger: trigger))
    }

    func cancelFocusNudge() {
        center.removePendingNotificationRequests(withIdentifiers: [ReminderIDs.focusNudge])
        center.removeDeliveredNotifications(withIdentifiers: [ReminderIDs.focusNudge])
    }

    private func add(_ r: ReminderRequest, calendar: Calendar) {
        let content = UNMutableNotificationContent()
        content.title = r.title
        content.body = r.body
        content.sound = .default
        content.threadIdentifier = "tasks"
        content.userInfo = ["route": r.route]
        // Trigger theo giờ đồng hồ (không gắn múi giờ) để đổi múi giờ thì 08:00 vẫn là 08:00.
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: r.fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: r.id, content: content, trigger: trigger))
    }
}
