import Foundation

/// Bộ sinh số ngẫu nhiên có seed (SplitMix64) — cùng seed cho cùng màn chơi, dùng được trong test.
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

extension UUID {
    /// Seed ổn định suy ra từ mã lượt chơi.
    var seed: UInt64 {
        let b = uuid
        return [b.0, b.1, b.2, b.3, b.4, b.5, b.6, b.7].reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
            ^ [b.8, b.9, b.10, b.11, b.12, b.13, b.14, b.15].reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
    }
}

/// Trạng thái một lượt chơi: ready → countdown → playing ⇄ paused → finished / abandoned.
/// Thời gian dùng đồng hồ đơn điệu (giây) do lớp giao diện truyền vào, nên test điều khiển được.
enum PlayPhase: Equatable {
    case ready
    /// Đếm ngược trước khi chạy (lúc bắt đầu và khi tiếp tục sau tạm dừng).
    case countdown(endsAt: TimeInterval)
    case playing
    case paused
    case finished
    case abandoned

    var isOver: Bool { self == .finished || self == .abandoned }
}

struct PlaySession: Equatable {
    static let countdownSeconds: TimeInterval = 3

    let id: UUID
    private(set) var phase: PlayPhase = .ready

    init(id: UUID = UUID()) { self.id = id }

    /// Chỉ khi đang chơi thì đồng hồ lượt chạy, vật phẩm sinh ra và va chạm được tính.
    var isRunning: Bool { phase == .playing }

    mutating func start(at t: TimeInterval) {
        guard phase == .ready else { return }
        phase = .countdown(endsAt: t + Self.countdownSeconds)
    }

    /// Gọi mỗi khung hình: hết đếm ngược thì chuyển sang chơi.
    mutating func tick(at t: TimeInterval) {
        if case .countdown(let end) = phase, t >= end { phase = .playing }
    }

    func countdownRemaining(at t: TimeInterval) -> Int? {
        guard case .countdown(let end) = phase else { return nil }
        return max(1, Int((end - t).rounded(.up)))
    }

    /// Tạm dừng (nút, vào nền, khóa màn hình). Đang đếm ngược cũng dừng.
    mutating func pause() {
        switch phase {
        case .playing, .countdown: phase = .paused
        default: break
        }
    }

    /// Tiếp tục: luôn qua đếm ngược ngắn, không chạy ngay.
    mutating func resume(at t: TimeInterval) {
        guard phase == .paused else { return }
        phase = .countdown(endsAt: t + Self.countdownSeconds)
    }

    mutating func finish() {
        guard phase == .playing else { return }
        phase = .finished
    }

    mutating func abandon() {
        guard !phase.isOver else { return }
        phase = .abandoned
    }
}

/// Đồng hồ thời gian chạy của lượt (không tính lúc tạm dừng / đếm ngược).
struct RunClock: Equatable {
    private(set) var accumulated: TimeInterval = 0
    private var runningSince: TimeInterval?

    var isRunning: Bool { runningSince != nil }

    mutating func run(at t: TimeInterval) {
        guard runningSince == nil else { return }
        runningSince = t
    }

    mutating func stop(at t: TimeInterval) {
        guard let since = runningSince else { return }
        accumulated += max(0, t - since)
        runningSince = nil
    }

    func elapsed(at t: TimeInterval) -> TimeInterval {
        accumulated + (runningSince.map { max(0, t - $0) } ?? 0)
    }
}

/// Chia một khoảng thời gian khung hình thành các bước nhỏ cố định để va chạm ổn định
/// (máy khựng lâu hơn `maxFrame` chỉ tính `maxFrame`).
enum StepClock {
    static let step: TimeInterval = 1.0 / 120
    static let maxFrame: TimeInterval = 0.1

    static func substeps(for dt: TimeInterval) -> [TimeInterval] {
        guard dt > 0 else { return [] }
        var left = min(dt, maxFrame)
        var steps: [TimeInterval] = []
        while left > 1e-9 {
            let s = min(step, left)
            steps.append(s)
            left -= s
        }
        return steps
    }
}
