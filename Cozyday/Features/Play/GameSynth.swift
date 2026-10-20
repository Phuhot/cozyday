import AVFoundation

/// Bộ tổng hợp tiếng "giàu" cho game: chuông nhiều họa âm, tiếng nảy, tiếng thạch rơi, tiếng gió và lấp lánh.
/// Vẫn tự tổng hợp lúc mở game, không có tệp âm thanh.
struct GameTone {
    enum Timbre { case bell, pop, thud, noise, shimmer }
    var start: Double
    var duration: Double
    var f0: Double
    var f1: Double
    var gain: Double
    var timbre: Timbre

    init(_ timbre: Timbre, at start: Double, _ duration: Double, _ f0: Double, _ f1: Double? = nil, gain: Double = 0.5) {
        self.timbre = timbre
        self.start = start
        self.duration = duration
        self.f0 = f0
        self.f1 = f1 ?? f0
        self.gain = gain
    }
}

enum GameSynth {
    /// Nốt ngũ cung từ Đô 5: nghe vui, chồng lên nhau không chói.
    static let scale: [Double] = [523.25, 587.33, 659.25, 783.99, 880, 1046.5, 1174.66, 1318.5, 1567.98, 1760, 2093, 2349.3, 2637]

    static func note(_ i: Int) -> Double { scale[min(scale.count - 1, max(0, i))] }

    static func render(_ tones: [GameTone], format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let rate = format.sampleRate
        let total = (tones.map { $0.start + $0.duration }.max() ?? 0.1) + 0.03
        let length = Int(total * rate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(length)),
              let data = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = AVAudioFrameCount(length)
        var mix = [Double](repeating: 0, count: length)
        var seed: UInt64 = 0x9E37_79B9_7F4A_7C15
        func noise() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(Int64(bitPattern: seed) >> 11) / Double(1 << 52)
        }
        for tone in tones {
            let begin = Int(tone.start * rate)
            let n = Int(tone.duration * rate)
            var phase = 0.0
            var low = 0.0
            var lowB = 0.0
            for j in 0..<n where begin + j < length {
                let t = Double(j) / Double(n)
                let secs = Double(j) / rate
                let freq = tone.f0 + (tone.f1 - tone.f0) * t
                phase += 2 * .pi * freq / rate
                let attack = min(1, secs / 0.003)
                var v = 0.0
                switch tone.timbre {
                case .bell:
                    // Họa âm hơi lệch như chuông nhỏ, tắt dần theo hàm mũ.
                    let env = attack * exp(-secs * 5.5 / tone.duration)
                    v = (sin(phase) + 0.45 * sin(2 * phase) + 0.2 * sin(3.01 * phase) + 0.08 * sin(4.2 * phase)) * env * 0.55
                case .pop:
                    let env = attack * pow(1 - t, 3)
                    v = (sin(phase) + 0.3 * sin(2 * phase)) * env
                case .thud:
                    let env = attack * pow(1 - t, 4)
                    v = sin(phase) * env * 1.2
                case .noise:
                    // Lọc thông thấp một cực: f0 là tần số cắt.
                    let a = min(1, 2 * .pi * freq / rate)
                    low += a * (noise() - low)
                    v = low * attack * pow(1 - t, 2) * 1.6
                case .shimmer:
                    // Nhiễu tần cao (lọc thông cao) có hạt lấp lánh.
                    let w = noise()
                    lowB += 0.25 * (w - lowB)
                    let sparkle = 0.6 + 0.4 * sin(secs * 2 * .pi * 23)
                    v = (w - lowB) * attack * pow(1 - t, 2) * sparkle * 0.7
                }
                mix[begin + j] += v * tone.gain
            }
        }
        for i in 0..<length {
            // Nén mềm để nhiều tiếng chồng lên không bị vỡ.
            data[i] = Float(tanh(mix[i] * 0.9) * 0.6)
        }
        return buffer
    }
}

extension GameSound {
    /// Tiếng mới của Xếp Khối / Gộp Bánh. nil = dùng tiếng đơn giản cũ.
    static func richTones(_ cue: GameCue) -> [GameTone]? {
        let n = GameSynth.note
        switch cue {
        case .pickup:
            return [GameTone(.pop, at: 0, 0.07, 380, 760, gain: 0.45)]
        case .place:
            return [GameTone(.thud, at: 0, 0.12, 220, 115, gain: 0.85),
                    GameTone(.noise, at: 0, 0.03, 2400, gain: 0.35),
                    GameTone(.pop, at: 0.01, 0.05, 900, 700, gain: 0.12)]
        case .refill:
            return [GameTone(.pop, at: 0, 0.06, 700, 820, gain: 0.3),
                    GameTone(.pop, at: 0.06, 0.06, 880, 1000, gain: 0.3),
                    GameTone(.pop, at: 0.12, 0.07, 1050, 1250, gain: 0.32)]
        case .whoosh:
            return [GameTone(.noise, at: 0, 0.14, 700, 1600, gain: 0.3)]
        case .clear1, .clear2, .clear3, .clear4, .clear5:
            let level = [GameCue.clear1, .clear2, .clear3, .clear4, .clear5].firstIndex(of: cue) ?? 0
            return [GameTone(.pop, at: 0, 0.06, 500, 900, gain: 0.3),
                    GameTone(.bell, at: 0.0, 0.32, n(level), gain: 0.5),
                    GameTone(.bell, at: 0.05, 0.32, n(level + 2), gain: 0.45),
                    GameTone(.bell, at: 0.10, 0.4, n(level + 4), gain: 0.45),
                    GameTone(.shimmer, at: 0.06, 0.35, 0, gain: 0.18)]
        case .combo2:
            return [GameTone(.thud, at: 0, 0.22, 170, 80, gain: 0.8),
                    GameTone(.bell, at: 0.0, 0.45, n(2), gain: 0.45),
                    GameTone(.bell, at: 0.06, 0.45, n(4), gain: 0.45),
                    GameTone(.bell, at: 0.12, 0.45, n(5), gain: 0.45),
                    GameTone(.bell, at: 0.18, 0.6, n(7), gain: 0.5),
                    GameTone(.shimmer, at: 0.1, 0.5, 0, gain: 0.25)]
        case .combo3:
            return [GameTone(.thud, at: 0, 0.28, 160, 70, gain: 0.9),
                    GameTone(.bell, at: 0.0, 0.5, n(4), gain: 0.45),
                    GameTone(.bell, at: 0.05, 0.5, n(5), gain: 0.45),
                    GameTone(.bell, at: 0.10, 0.5, n(7), gain: 0.45),
                    GameTone(.bell, at: 0.15, 0.5, n(9), gain: 0.45),
                    GameTone(.bell, at: 0.22, 0.8, n(10), gain: 0.55),
                    GameTone(.bell, at: 0.22, 0.8, n(7), gain: 0.3),
                    GameTone(.shimmer, at: 0.12, 0.7, 0, gain: 0.3)]
        case .merge1:
            return [GameTone(.pop, at: 0, 0.06, 320, 620, gain: 0.45),
                    GameTone(.bell, at: 0.03, 0.25, n(2), gain: 0.4)]
        case .merge2:
            return [GameTone(.pop, at: 0, 0.06, 360, 700, gain: 0.45),
                    GameTone(.bell, at: 0.03, 0.3, n(4), gain: 0.4),
                    GameTone(.bell, at: 0.08, 0.3, n(6), gain: 0.35)]
        case .merge3:
            return [GameTone(.pop, at: 0, 0.07, 400, 800, gain: 0.45),
                    GameTone(.bell, at: 0.03, 0.35, n(5), gain: 0.42),
                    GameTone(.bell, at: 0.08, 0.35, n(7), gain: 0.4),
                    GameTone(.bell, at: 0.13, 0.4, n(9), gain: 0.4),
                    GameTone(.shimmer, at: 0.08, 0.3, 0, gain: 0.15)]
        case .merge4:
            return [GameTone(.thud, at: 0, 0.18, 190, 100, gain: 0.6),
                    GameTone(.bell, at: 0.03, 0.4, n(7), gain: 0.42),
                    GameTone(.bell, at: 0.08, 0.4, n(8), gain: 0.42),
                    GameTone(.bell, at: 0.13, 0.5, n(10), gain: 0.45),
                    GameTone(.shimmer, at: 0.06, 0.45, 0, gain: 0.22)]
        case .newBest:
            return [GameTone(.bell, at: 0, 0.3, n(0), gain: 0.42),
                    GameTone(.bell, at: 0.09, 0.3, n(2), gain: 0.42),
                    GameTone(.bell, at: 0.18, 0.3, n(4), gain: 0.42),
                    GameTone(.bell, at: 0.27, 0.3, n(5), gain: 0.42),
                    GameTone(.bell, at: 0.36, 0.8, n(5), gain: 0.4),
                    GameTone(.bell, at: 0.36, 0.8, n(7), gain: 0.36),
                    GameTone(.bell, at: 0.36, 0.9, n(9), gain: 0.4),
                    GameTone(.shimmer, at: 0.36, 0.7, 0, gain: 0.3)]
        case .gameOver:
            return [GameTone(.bell, at: 0, 0.4, n(5), gain: 0.4),
                    GameTone(.bell, at: 0.14, 0.4, n(4), gain: 0.4),
                    GameTone(.bell, at: 0.28, 0.4, n(2), gain: 0.4),
                    GameTone(.bell, at: 0.42, 0.7, n(0), gain: 0.42)]
        default:
            return nil
        }
    }
}
