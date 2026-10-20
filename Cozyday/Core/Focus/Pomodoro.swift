import Foundation

/// Âm nền khi tập trung, tự tổng hợp trong app (không có tệp âm thanh, không tải gì về).
enum FocusAmbient: String, Codable, CaseIterable, Identifiable {
    case off
    case rain
    case brown
    case waves

    var id: String { rawValue }

    var label: String {
        switch self {
        case .off: return "Tắt"
        case .rain: return "Mưa nhẹ"
        case .brown: return "Tiếng ồn nâu"
        case .waves: return "Sóng biển"
        }
    }

    var symbol: String {
        switch self {
        case .off: return "speaker.slash"
        case .rain: return "cloud.rain"
        case .brown: return "waveform"
        case .waves: return "water.waves"
        }
    }
}

/// Cài đặt hẹn giờ Pomodoro. Lưu trên máy (UserDefaults), không nằm trong bản sao lưu.
struct PomodoroSettings: Codable, Equatable {
    var focusMinutes = 25
    var shortBreakMinutes = 5
    var longBreakMinutes = 15
    /// Số phiên tập trung trước một lần nghỉ dài.
    var roundsBeforeLongBreak = 4
    var autoStartBreak = true
    var autoStartFocus = false
    /// Mục tiêu số phiên tập trung mỗi ngày.
    var dailyGoal = 6
    /// Chế độ nghiêm: không có nút tạm dừng, muốn dừng sớm phải giữ nút 3 giây,
    /// rời app quá lâu (không phải khóa máy) thì phiên dừng lại, không có thưởng.
    var strictMode = false
    /// Gửi lời nhắc khi rời app giữa phiên tập trung.
    var nudgeWhenLeaving = true
    var keepScreenOn = true
    var endChime = true
    var ambient: FocusAmbient = .off
    /// Âm lượng âm nền, 0...1.
    var ambientVolume = 0.5

    static let focusRange = 5...120
    static let shortBreakRange = 5...15
    static let longBreakRange = 10...30
    static let roundsRange = 2...6
    static let goalRange = 1...12

    /// Đưa mọi giá trị về khoảng hợp lệ (dữ liệu cũ hoặc hỏng không làm app lỗi).
    func normalized() -> PomodoroSettings {
        var s = self
        s.focusMinutes = Self.clampStep(focusMinutes, Self.focusRange)
        s.shortBreakMinutes = Self.clamp(shortBreakMinutes, Self.shortBreakRange)
        s.longBreakMinutes = Self.clampStep(longBreakMinutes, Self.longBreakRange)
        s.roundsBeforeLongBreak = Self.clamp(roundsBeforeLongBreak, Self.roundsRange)
        s.dailyGoal = Self.clamp(dailyGoal, Self.goalRange)
        s.ambientVolume = ambientVolume.isFinite ? min(1, max(0, ambientVolume)) : 0.5
        return s
    }

    private static func clamp(_ v: Int, _ r: ClosedRange<Int>) -> Int { min(r.upperBound, max(r.lowerBound, v)) }
    /// Thời lượng dài đi theo bước 5 phút.
    private static func clampStep(_ v: Int, _ r: ClosedRange<Int>) -> Int { clamp((v / 5) * 5, r) }

    // Đọc từng trường có giá trị mặc định: bản cài đặt cũ thiếu trường mới vẫn đọc được.
    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PomodoroSettings()
        focusMinutes = (try? c.decode(Int.self, forKey: .focusMinutes)) ?? d.focusMinutes
        shortBreakMinutes = (try? c.decode(Int.self, forKey: .shortBreakMinutes)) ?? d.shortBreakMinutes
        longBreakMinutes = (try? c.decode(Int.self, forKey: .longBreakMinutes)) ?? d.longBreakMinutes
        roundsBeforeLongBreak = (try? c.decode(Int.self, forKey: .roundsBeforeLongBreak)) ?? d.roundsBeforeLongBreak
        autoStartBreak = (try? c.decode(Bool.self, forKey: .autoStartBreak)) ?? d.autoStartBreak
        autoStartFocus = (try? c.decode(Bool.self, forKey: .autoStartFocus)) ?? d.autoStartFocus
        dailyGoal = (try? c.decode(Int.self, forKey: .dailyGoal)) ?? d.dailyGoal
        strictMode = (try? c.decode(Bool.self, forKey: .strictMode)) ?? d.strictMode
        nudgeWhenLeaving = (try? c.decode(Bool.self, forKey: .nudgeWhenLeaving)) ?? d.nudgeWhenLeaving
        keepScreenOn = (try? c.decode(Bool.self, forKey: .keepScreenOn)) ?? d.keepScreenOn
        endChime = (try? c.decode(Bool.self, forKey: .endChime)) ?? d.endChime
        ambient = (try? c.decode(FocusAmbient.self, forKey: .ambient)) ?? d.ambient
        ambientVolume = (try? c.decode(Double.self, forKey: .ambientVolume)) ?? d.ambientVolume
    }

    static func decode(_ data: Data?) -> PomodoroSettings {
        guard let data, let s = try? JSONDecoder().decode(PomodoroSettings.self, from: data) else { return PomodoroSettings() }
        return s.normalized()
    }

    func encoded() -> Data? { try? JSONEncoder().encode(normalized()) }
}

/// Tiến độ Pomodoro trong ngày, tính lại từ các phiên đã lưu (không có bộ đếm riêng để lệch).
struct PomodoroDay: Equatable {
    /// Số phiên tập trung chạy hết giờ trong ngày.
    var completedFocus: Int
    /// Tổng phút tập trung thực (gồm cả phiên dừng sớm).
    var focusedMinutes: Int
    /// Số phiên đã xong trong vòng hiện tại (0 ..< roundsBeforeLongBreak).
    var roundInCycle: Int
    var goal: Int

    var goalReached: Bool { completedFocus >= goal }

    static func compute(sessions: [FocusSessionRecord], day: DayKey, calendar: Calendar, settings: PomodoroSettings) -> PomodoroDay {
        let todays = sessions.filter { s in
            s.kind == .focus && !s.isActive && DayKey(s.endedAt ?? s.startedAt, calendar: calendar) == day
        }
        let completed = todays.filter { $0.status == .completed }.count
        let minutes = Int(todays.reduce(0) { $0 + $1.focusedSeconds } / 60)
        return PomodoroDay(completedFocus: completed, focusedMinutes: minutes,
                           roundInCycle: completed % settings.roundsBeforeLongBreak, goal: settings.dailyGoal)
    }
}

enum PomodoroPlan {
    struct Next: Equatable {
        var kind: FocusKind
        var minutes: Int
        var isLongBreak: Bool
    }

    /// Phiên kế tiếp sau một phiên vừa chạy hết giờ. `completedFocusToday` đã gồm phiên vừa xong.
    static func next(after finished: FocusKind, completedFocusToday: Int, settings: PomodoroSettings) -> Next {
        switch finished {
        case .focus:
            let long = completedFocusToday > 0 && completedFocusToday % settings.roundsBeforeLongBreak == 0
            return Next(kind: .rest, minutes: long ? settings.longBreakMinutes : settings.shortBreakMinutes, isLongBreak: long)
        case .rest:
            return Next(kind: .focus, minutes: settings.focusMinutes, isLongBreak: false)
        }
    }

    /// Chỉ tự chạy tiếp khi phiên vừa hết giờ trong lúc bạn đang nhìn màn hình (trễ dưới 1 phút).
    /// Mở app sau 40 phút thì không tự bật giờ nghỉ đã trôi qua từ lâu.
    static let autoStartWindow: TimeInterval = 60

    static func shouldAutoStart(_ next: Next, endedAt: Date, now: Date, settings: PomodoroSettings) -> Bool {
        guard now.timeIntervalSince(endedAt) <= autoStartWindow else { return false }
        return next.kind == .rest ? settings.autoStartBreak : settings.autoStartFocus
    }
}

/// Theo dõi lúc rời app giữa phiên tập trung. Khóa màn hình không tính là rời app.
struct FocusAwayTracker: Equatable {
    /// Rời app ngắn hơn mức này (vuốt xem thông báo, đổi bài nhạc) thì bỏ qua.
    static let graceSeconds: TimeInterval = 10
    /// Chế độ nghiêm: rời app lâu hơn mức này thì phiên dừng lại.
    static let strictLimitSeconds: TimeInterval = 60
    /// Lời nhắc quay lại gửi sau chừng này giây kể từ lúc rời app (sau khi chắc chắn không phải khóa máy).
    static let nudgeDelay: TimeInterval = 15
    /// Thời gian giữ app chạy nền để chờ tín hiệu khóa máy.
    static let lockCheckSeconds: TimeInterval = 13

    enum Outcome: Equatable {
        /// Không tính (khóa máy, quá ngắn hoặc không có phiên tập trung đang chạy).
        case ignored
        /// Tính là một lần rời app.
        case counted(seconds: TimeInterval)
        /// Chế độ nghiêm: rời quá lâu, phiên phải dừng.
        case broke(seconds: TimeInterval)
    }

    private(set) var leftAt: Date?
    /// Lúc iOS báo khóa máy. Tín hiệu này tới khoảng 10 giây SAU khi khóa (lúc dữ liệu được bảo vệ khóa lại),
    /// nên app giữ chạy nền khoảng 15 giây để kịp nhận.
    private(set) var lockedAt: Date?

    /// Khôi phục trạng thái đã lưu (app bị iOS đóng hẳn trong lúc bạn ở app khác).
    init(leftAt: Date? = nil, lockedAt: Date? = nil) {
        self.leftAt = leftAt
        self.lockedAt = lockedAt
    }

    mutating func didLeave(at now: Date) {
        leftAt = now
    }

    mutating func deviceLocked(at now: Date) {
        lockedAt = now
    }

    /// Khóa máy trong lúc rời app (hoặc ngay trước đó vài giây) thì không tính.
    var lockedWhileAway: Bool {
        guard let leftAt, let lockedAt else { return false }
        return lockedAt >= leftAt.addingTimeInterval(-3)
    }

    /// Gọi khi quay lại app. `focusRunning`: lúc rời app có phiên tập trung đang chạy (không tạm dừng).
    mutating func didReturn(at now: Date, focusRunning: Bool, strict: Bool) -> Outcome {
        defer { leftAt = nil; lockedAt = nil }
        guard let leftAt, focusRunning, !lockedWhileAway else { return .ignored }
        let away = max(0, now.timeIntervalSince(leftAt))
        guard away >= Self.graceSeconds else { return .ignored }
        if strict && away >= Self.strictLimitSeconds { return .broke(seconds: away) }
        return .counted(seconds: away)
    }
}
