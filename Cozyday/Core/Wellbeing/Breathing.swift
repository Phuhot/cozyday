import Foundation

/// Nhịp thở hướng dẫn. Tính pha từ thời gian đã trôi — không cần bộ đếm chạy nền.
struct BreathingPattern: Identifiable, Equatable {
    struct Phase: Equatable {
        enum Kind: Equatable { case inhale, hold, exhale, rest }
        var kind: Kind
        var seconds: Double

        var label: String {
            switch kind {
            case .inhale: return "Hít vào"
            case .hold: return "Giữ hơi"
            case .exhale: return "Thở ra"
            case .rest: return "Nghỉ"
            }
        }
    }

    let id: String
    let name: String
    let detail: String
    let phases: [Phase]

    var cycleSeconds: Double { phases.reduce(0) { $0 + $1.seconds } }

    static let calm = BreathingPattern(id: "calm", name: "Thư giãn 4–6", detail: "Hít 4 giây, thở ra 6 giây.",
                                       phases: [Phase(kind: .inhale, seconds: 4), Phase(kind: .exhale, seconds: 6)])
    static let box = BreathingPattern(id: "box", name: "Thở hộp 4–4–4–4", detail: "Hít, giữ, thở ra, nghỉ — mỗi nhịp 4 giây.",
                                      phases: [Phase(kind: .inhale, seconds: 4), Phase(kind: .hold, seconds: 4),
                                               Phase(kind: .exhale, seconds: 4), Phase(kind: .rest, seconds: 4)])
    static let sleepy = BreathingPattern(id: "478", name: "Dễ ngủ 4–7–8", detail: "Hít 4 giây, giữ 7 giây, thở ra 8 giây.",
                                         phases: [Phase(kind: .inhale, seconds: 4), Phase(kind: .hold, seconds: 7),
                                                  Phase(kind: .exhale, seconds: 8)])
    static let all = [calm, box, sleepy]

    /// Pha hiện tại và tiến độ trong pha (0…1) sau `elapsed` giây.
    func phase(at elapsed: Double) -> (index: Int, phase: Phase, progress: Double) {
        let t = max(0, elapsed).truncatingRemainder(dividingBy: cycleSeconds)
        var acc = 0.0
        for (i, p) in phases.enumerated() {
            if t < acc + p.seconds { return (i, p, (t - acc) / p.seconds) }
            acc += p.seconds
        }
        return (phases.count - 1, phases[phases.count - 1], 1)
    }

    /// Độ "phồng" của vòng tròn 0…1 theo pha (hít lên 1, giữ nguyên, thở ra về 0).
    func expansion(at elapsed: Double) -> Double {
        let (index, p, progress) = phase(at: elapsed)
        switch p.kind {
        case .inhale: return progress
        case .exhale: return 1 - progress
        case .hold:
            // Giữ sau khi hít = đầy; giữ sau khi thở ra = rỗng.
            let previous = phases[(index - 1 + phases.count) % phases.count].kind
            return previous == .exhale ? 0 : 1
        case .rest: return 0
        }
    }
}
