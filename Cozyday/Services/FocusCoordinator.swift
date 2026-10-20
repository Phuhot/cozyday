import Foundation
import Observation
import UIKit
import UserNotifications

/// Điều phối hẹn giờ Pomodoro ngoài màn hình: tự chốt phiên khi hết giờ (dù đang ở tab khác), tự nối giờ nghỉ / phiên mới,
/// giữ màn hình sáng, âm nền, chuông, nhắc quay lại khi rời app, và chế độ nghiêm.
/// Nguồn sự thật vẫn là phiên đã lưu trong AppStore.
@MainActor
@Observable
final class FocusCoordinator {
    static let settingsKey = "focus.settings"
    static let awayKey = "focus.awayCounts"
    static let leftAtKey = "focus.leftAt"
    static let lockedAtKey = "focus.lockedAt"

    var settings: PomodoroSettings {
        didSet {
            guard settings != oldValue else { return }
            // encoded() tự đưa giá trị về khoảng hợp lệ; các nút chỉnh trong cài đặt cũng giới hạn sẵn.
            defaults.set(settings.encoded(), forKey: Self.settingsKey)
            applyEffects()
        }
    }
    /// Phiên vừa kết thúc (để hiện màn "Xong rồi"); tab và sheet dùng chung.
    var lastFinished: FocusSessionRecord?
    /// Lời báo ngắn sau khi quay lại app (rời app bao lâu, phiên bị dừng vì chế độ nghiêm…).
    var awayNotice: String?
    /// Việc được chọn để gắn với phiên kế tiếp.
    var selectedTaskID: UUID?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private weak var store: AppStore?
    @ObservationIgnored private var ui: UIState?
    @ObservationIgnored private var notifications: NotificationService?
    @ObservationIgnored private let audio = FocusAudio()
    @ObservationIgnored private var tracker = FocusAwayTracker()
    @ObservationIgnored private var endWatch: Task<Void, Never>?
    @ObservationIgnored private var awayCounts: [String: Int]
    @ObservationIgnored private var appActive = true
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    init(defaults: UserDefaults) {
        self.defaults = defaults
        settings = PomodoroSettings.decode(defaults.data(forKey: Self.settingsKey))
        awayCounts = (defaults.dictionary(forKey: Self.awayKey) as? [String: Int]) ?? [:]
        // App bị iOS đóng hẳn lúc bạn ở app khác: vẫn nhớ lúc rời app để chế độ nghiêm tính đúng.
        let left = defaults.object(forKey: Self.leftAtKey) as? Date
        let locked = defaults.object(forKey: Self.lockedAtKey) as? Date
        tracker = FocusAwayTracker(leftAt: left, lockedAt: locked)
    }

    private func saveTracker() {
        defaults.set(tracker.leftAt, forKey: Self.leftAtKey)
        defaults.set(tracker.lockedAt, forKey: Self.lockedAtKey)
    }

    /// Gắn với kho dữ liệu (gọi một lần khi giao diện chính xuất hiện).
    func attach(store: AppStore, ui: UIState, notifications: NotificationService) {
        guard self.store == nil else { return }
        self.store = store
        self.ui = ui
        self.notifications = notifications
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UIApplication.protectedDataWillBecomeUnavailableNotification,
                                            object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.deviceLocked() }
        })
        storeChanged()
    }

    /// Sau khi xóa toàn bộ dữ liệu: cài đặt và số liệu rời app về mặc định.
    func resetAfterErase() {
        awayCounts = [:]
        lastFinished = nil
        awayNotice = nil
        selectedTaskID = nil
        settings = PomodoroSettings()
        defaults.removeObject(forKey: Self.settingsKey)
        defaults.removeObject(forKey: Self.awayKey)
        tracker = FocusAwayTracker()
        saveTracker()
        storeChanged()
    }

    // MARK: Trạng thái

    var activeSession: FocusSessionRecord? { store?.activeFocus }

    var day: PomodoroDay {
        store?.pomodoroDay(settings: settings) ?? PomodoroDay(completedFocus: 0, focusedMinutes: 0, roundInCycle: 0, goal: settings.dailyGoal)
    }

    func awayCount(for sessionID: UUID) -> Int { awayCounts[sessionID.uuidString] ?? 0 }

    // MARK: Hành động

    func start(kind: FocusKind, minutes: Int) {
        guard let store, let ui else { return }
        lastFinished = nil
        awayNotice = nil
        let linked = kind == .focus ? selectedTaskID : nil
        ui.run { try store.startFocus(kind: kind, minutes: minutes, occurrenceID: linked) }
        storeChanged()
    }

    func startNextFocus() { start(kind: .focus, minutes: settings.focusMinutes) }

    func pause() {
        guard let store, let ui, !settings.strictMode || activeSession?.kind == .rest else { return }
        ui.run { try store.pauseFocus() }
        storeChanged()
    }

    func resume() {
        guard let store, let ui else { return }
        ui.run { try store.resumeFocus() }
        storeChanged()
    }

    func endEarly() {
        guard let store, let ui else { return }
        let id = store.activeFocus?.id
        var reward: LedgerEntry?
        ui.run { reward = try store.endFocusEarly() }
        ui.reward(reward)
        if let id, let s = store.focusSessions.first(where: { $0.id == id }) {
            // Dừng giờ nghỉ sớm = sẵn sàng làm tiếp, không cần màn tổng kết.
            lastFinished = s.kind == .focus ? s : nil
        }
        storeChanged()
    }

    /// Bỏ qua giờ nghỉ đang chạy và vào phiên tập trung mới.
    func skipBreak() {
        guard activeSession?.kind == .rest else { return }
        endEarly()
        startNextFocus()
    }

    /// Ghi nhanh một ý nghĩ chen ngang vào Hộp chờ để xử lý sau, không phải rời màn hẹn giờ.
    func captureThought(_ text: String) -> Bool {
        guard let store, let ui else { return false }
        var draft = TaskDraft()
        draft.title = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120))
        draft.notes = "Ghi lúc đang tập trung"
        guard !draft.trimmedTitle.isEmpty else { return false }
        return ui.run { _ = try store.createTask(draft) }
    }

    /// Chốt phiên đã hết giờ (đúng một lần), báo hiệu và tự nối phiên kế tiếp nếu được bật.
    func reconcile() {
        guard let store, let ui, let active = store.activeFocus, active.hasReachedEnd(at: store.now) else { return }
        // Chế độ nghiêm, đang ở app khác (không phải khóa máy) mà app vẫn chạy nền nhờ âm nền:
        // chưa chốt ở đây, đợi lúc quay lại để xét thời gian rời app trước.
        if !appActive, settings.strictMode, active.kind == .focus, tracker.leftAt != nil, !tracker.lockedWhileAway { return }
        var reward: LedgerEntry?
        ui.run { reward = try store.reconcileFocus() }
        ui.reward(reward)
        guard let done = store.focusSessions.first(where: { $0.id == active.id && !$0.isActive }) else { return }
        didFinish(done)
    }

    private func didFinish(_ done: FocusSessionRecord) {
        guard let store else { return }
        let endedAt = done.endedAt ?? store.now
        let fresh = store.now.timeIntervalSince(endedAt) <= PomodoroPlan.autoStartWindow
        if fresh && appActive {
            if settings.endChime { audio.playChime() }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        let next = PomodoroPlan.next(after: done.kind, completedFocusToday: day.completedFocus, settings: settings)
        if PomodoroPlan.shouldAutoStart(next, endedAt: endedAt, now: store.now, settings: settings) {
            start(kind: next.kind, minutes: next.minutes)
            // Giữ tổng kết phiên vừa xong để hiện gọn trong lúc nghỉ (số lần rời app, đánh dấu việc xong).
            if done.kind == .focus { lastFinished = done }
        } else {
            lastFinished = done.kind == .focus ? done : nil
        }
        storeChanged()
    }

    /// Phiên kế tiếp gợi ý cho màn hình (nghỉ ngắn / nghỉ dài / tập trung).
    func suggestedNext(after kind: FocusKind) -> PomodoroPlan.Next {
        PomodoroPlan.next(after: kind, completedFocusToday: day.completedFocus, settings: settings)
    }

    // MARK: Vòng đời app

    func sceneBecameActive() {
        appActive = true
        guard let store else { return }
        notifications?.cancelFocusNudge()
        let running = store.activeFocus.map { $0.kind == .focus && !$0.isPaused } ?? false
        let leftAt = tracker.leftAt
        let outcome = tracker.didReturn(at: store.now, focusRunning: running, strict: settings.strictMode)
        saveTracker()
        switch outcome {
        case .ignored:
            break
        case .counted(let seconds):
            if let id = store.activeFocus?.id { bumpAway(id) }
            awayNotice = "Bạn đã rời app \(Self.duration(seconds)). Lần rời app được ghi vào tổng kết phiên."
        case .broke(let seconds):
            if let id = store.activeFocus?.id { bumpAway(id) }
            let id = store.activeFocus?.id
            let moment = (leftAt ?? store.now).addingTimeInterval(FocusAwayTracker.strictLimitSeconds)
            var reward: LedgerEntry?
            ui?.run { reward = try store.breakFocus(at: moment) }
            ui?.reward(reward)
            if let id, let s = store.focusSessions.first(where: { $0.id == id }) {
                lastFinished = s
                awayNotice = s.status == .completed
                    ? nil
                    : "Chế độ nghiêm: bạn rời app \(Self.duration(seconds)) nên phiên dừng ở phút \(Int(s.focusedSeconds / 60)). Không có thưởng cho phiên này."
            }
        }
        reconcile()
        storeChanged()
    }

    func sceneEnteredBackground() {
        appActive = false
        guard let store, let session = store.activeFocus, session.kind == .focus, !session.isPaused else {
            applyEffects()
            return
        }
        tracker.didLeave(at: store.now)
        saveTracker()
        // iOS báo khóa máy khoảng 10 giây sau khi khóa: giữ app chạy nền ~13 giây, chỉ gửi lời nhắc nếu
        // tới lúc đó vẫn chưa có tín hiệu khóa máy (tức là bạn đang ở app khác).
        holdBackgroundForLockCheck()
        applyEffects()
    }

    @ObservationIgnored private var backgroundTask = UIBackgroundTaskIdentifier.invalid

    private func holdBackgroundForLockCheck() {
        let app = UIApplication.shared
        if backgroundTask == .invalid {
            backgroundTask = app.beginBackgroundTask(withName: "focus.lockCheck") { [weak self] in
                MainActor.assumeIsolated { self?.endBackgroundHold() }
            }
        }
        lockCheck?.cancel()
        lockCheck = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(FocusAwayTracker.lockCheckSeconds * 1_000_000_000))
            guard !Task.isCancelled, let self else { return }
            if self.tracker.leftAt != nil, !self.tracker.lockedWhileAway, !self.appActive,
               self.settings.nudgeWhenLeaving || self.settings.strictMode, let store = self.store {
                self.notifications?.scheduleFocusNudge(petName: store.profile.displayPetName, strict: self.settings.strictMode,
                                                       after: max(1, FocusAwayTracker.nudgeDelay - FocusAwayTracker.lockCheckSeconds))
            }
            self.endBackgroundHold()
        }
    }

    @ObservationIgnored private var lockCheck: Task<Void, Never>?

    private func endBackgroundHold() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    private func deviceLocked() {
        guard let store else { return }
        tracker.deviceLocked(at: store.now)
        saveTracker()
        // Khóa máy là chuyện bình thường khi tập trung: bỏ lời nhắc quay lại.
        notifications?.cancelFocusNudge()
    }

    /// Gọi sau mọi thay đổi dữ liệu: hẹn lại mốc hết giờ, âm nền, giữ màn hình sáng.
    func storeChanged() {
        scheduleEndWatch()
        applyEffects()
    }

    private func scheduleEndWatch() {
        endWatch?.cancel()
        guard let store, let end = store.activeFocus?.expectedEnd else { return }
        let wait = max(0.2, end.timeIntervalSince(store.now) + 0.3)
        endWatch = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.reconcile()
        }
    }

    private func applyEffects() {
        let session = store?.activeFocus
        let runningFocus = session.map { $0.kind == .focus && !$0.isPaused } ?? false
        UIApplication.shared.isIdleTimerDisabled = appActive && settings.keepScreenOn && session != nil && PreviewMode.current == nil
        if PreviewMode.current != nil { return }
        audio.setAmbient(runningFocus ? settings.ambient : .off, volume: settings.ambientVolume)
    }

    /// Nghe thử âm nền trong màn cài đặt (dừng khi đóng cài đặt nếu không có phiên chạy).
    func preview(_ ambient: FocusAmbient) {
        audio.setAmbient(ambient, volume: settings.ambientVolume)
    }

    func endPreview() { applyEffects() }

    private func bumpAway(_ id: UUID) {
        awayCounts[id.uuidString, default: 0] += 1
        if awayCounts.count > 40 {
            // Chỉ giữ số liệu của các phiên gần đây.
            let recent = Set((store?.focusSessions.suffix(30) ?? []).map(\.id.uuidString))
            awayCounts = awayCounts.filter { recent.contains($0.key) }
        }
        defaults.set(awayCounts, forKey: Self.awayKey)
    }

    static func duration(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        if s < 60 { return "\(s) giây" }
        let m = s / 60
        if m < 60 { return "\(m) phút" }
        return "\(m / 60) giờ \(m % 60) phút"
    }
}
