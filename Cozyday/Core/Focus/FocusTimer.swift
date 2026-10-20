import Foundation

enum FocusKind: String, Codable {
    case focus
    case rest

    var label: String { self == .focus ? "Tập trung" : "Nghỉ" }
}

enum FocusStatus: String, Codable {
    /// Đang chạy hoặc tạm dừng.
    case active
    /// Chạy hết thời lượng đã đặt.
    case completed
    /// Người dùng bấm kết thúc sớm.
    case endedEarly
}

/// Bản ghi phiên tập trung/nghỉ. Nguồn sự thật là các mốc thời gian đã lưu — không đếm bằng
/// Timer trong bộ nhớ, nên app bị iOS tạm dừng/đóng hẳn vẫn tính đúng khi mở lại.
struct FocusSessionRecord: Codable, Equatable, Identifiable {
    var id: UUID
    var kind: FocusKind
    var plannedSeconds: Int
    var startedAt: Date
    /// Tổng số giây đã chạy trong các đoạn đã kết thúc (không gồm đoạn đang chạy).
    var accumulatedSeconds: Double
    /// Thời điểm bắt đầu đoạn đang chạy; nil = đang tạm dừng (hoặc đã kết thúc).
    var runningSince: Date?
    var endedAt: Date?
    var status: FocusStatus
    var occurrenceID: UUID?
    /// Số giây tập trung thực (chỉ chốt khi phiên kết thúc).
    var focusedSeconds: Double

    var isActive: Bool { status == .active }
    var isPaused: Bool { status == .active && runningSince == nil }
    var plannedMinutes: Int { plannedSeconds / 60 }

    static func start(kind: FocusKind, minutes: Int, occurrenceID: UUID?, now: Date) -> FocusSessionRecord {
        FocusSessionRecord(
            id: UUID(), kind: kind, plannedSeconds: minutes * 60, startedAt: now,
            accumulatedSeconds: 0, runningSince: now, endedAt: nil, status: .active,
            occurrenceID: occurrenceID, focusedSeconds: 0
        )
    }

    /// Số giây đã chạy (không tính lúc tạm dừng), tối đa bằng thời lượng đặt.
    func elapsed(at now: Date) -> Double {
        let running = runningSince.map { max(0, now.timeIntervalSince($0)) } ?? 0
        return min(Double(plannedSeconds), accumulatedSeconds + running)
    }

    func remaining(at now: Date) -> Double {
        max(0, Double(plannedSeconds) - elapsed(at: now))
    }

    /// Thời điểm sẽ chạy hết nếu không tạm dừng nữa (để lên lịch thông báo).
    var expectedEnd: Date? {
        guard status == .active, let runningSince else { return nil }
        return runningSince.addingTimeInterval(Double(plannedSeconds) - accumulatedSeconds)
    }

    func hasReachedEnd(at now: Date) -> Bool {
        status == .active && remaining(at: now) <= 0.5
    }

    mutating func pause(at now: Date) {
        guard status == .active, let since = runningSince else { return }
        accumulatedSeconds = min(Double(plannedSeconds), accumulatedSeconds + max(0, now.timeIntervalSince(since)))
        runningSince = nil
    }

    mutating func resume(at now: Date) {
        guard status == .active, runningSince == nil else { return }
        runningSince = now
    }

    /// Đối chiếu khi mở lại app: nếu đã hết giờ thì kết thúc đúng một lần, với thời điểm kết thúc
    /// là lúc thực sự hết giờ (không phải lúc mở app). Trả về true nếu vừa chuyển sang completed.
    @discardableResult
    mutating func reconcile(at now: Date) -> Bool {
        guard hasReachedEnd(at: now) else { return false }
        let endMoment = expectedEnd.map { min($0, now) } ?? now
        accumulatedSeconds = Double(plannedSeconds)
        runningSince = nil
        endedAt = endMoment
        status = .completed
        focusedSeconds = kind == .focus ? Double(plannedSeconds) : 0
        return true
    }

    /// Kết thúc sớm: chốt số giây đã chạy, không thưởng.
    mutating func endEarly(at now: Date) {
        guard status == .active else { return }
        if reconcile(at: now) { return }
        let total = elapsed(at: now)
        accumulatedSeconds = total
        runningSince = nil
        endedAt = now
        status = .endedEarly
        focusedSeconds = kind == .focus ? total : 0
    }

    /// Đủ điều kiện nhận thưởng: phiên tập trung chạy hết giờ.
    var isRewardEligible: Bool {
        kind == .focus && status == .completed && plannedMinutes >= RewardConfig.focusMinMinutesForReward
    }
}

enum FocusPresets {
    struct Preset: Equatable, Identifiable {
        let focus: Int
        let rest: Int
        var id: String { "\(focus)/\(rest)" }
        var label: String { "\(focus)/\(rest)" }
    }

    static let all = [Preset(focus: 25, rest: 5), Preset(focus: 50, rest: 10)]
    static let customRange = 5...120
}
