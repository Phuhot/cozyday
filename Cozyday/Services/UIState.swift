import Foundation
import Observation

/// Trạng thái giao diện dùng chung: banner lỗi, thông báo thưởng, hiệu ứng mèo.
@MainActor
@Observable
final class UIState {
    var errorMessage: String?
    private(set) var toast: String?
    private(set) var celebrateCounter = 0
    private(set) var lastCelebrationAt: Date?
    var showSettings = false

    @ObservationIgnored private var toastToken = 0

    /// Chạy một thao tác ghi dữ liệu; lỗi → hiện banner. Trả về true nếu thành công.
    @discardableResult
    func run(_ action: () throws -> Void) -> Bool {
        do {
            try action()
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    func showReward(_ text: String) {
        toast = text
        celebrateCounter += 1
        lastCelebrationAt = Date()
        toastToken += 1
        let token = toastToken
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard let self, self.toastToken == token else { return }
            self.toast = nil
        }
    }

    func reward(_ entry: LedgerEntry?) {
        guard let entry, !entry.rewardText.isEmpty else { return }
        showReward(entry.rewardText)
    }

    /// Tâm trạng mèo suy ra từ sự kiện cục bộ (không cần AI).
    func petMood(store: AppStore) -> PetMood {
        if let focus = store.activeFocus {
            return focus.kind == .focus ? .focus : .rest
        }
        if let t = lastCelebrationAt, Date().timeIntervalSince(t) < 30 * 60 { return .happy }
        if let last = store.ledger.last(where: { $0.kind != .purchase }),
           store.now.timeIntervalSince(last.createdAt) < 2 * 3600 {
            return .happy
        }
        let minute = store.calendar.minuteOfDay(store.now)
        if minute >= 22 * 60 || minute < 6 * 60 { return .rest }
        return .idle
    }
}

/// "Hôm nay" theo lịch thiết bị; được làm mới khi mở app, qua nửa đêm hoặc đổi múi giờ.
@MainActor
@Observable
final class DayClock {
    private(set) var today: DayKey
    let calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
        self.today = DayKey(Date(), calendar: calendar)
    }

    /// Trả về true nếu ngày đã đổi.
    @discardableResult
    func refresh() -> Bool {
        let now = DayKey(Date(), calendar: calendar)
        guard now != today else { return false }
        today = now
        return true
    }
}
