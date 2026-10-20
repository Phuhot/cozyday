import AVFoundation

/// Âm nền khi tập trung (mưa, tiếng ồn nâu, sóng biển) và tiếng chuông hết giờ. Tự tổng hợp, không có tệp âm thanh.
/// Phiên âm thanh `.playback` trộn với âm thanh khác: không ngắt nhạc bạn đang nghe, vẫn phát khi khóa máy.
@MainActor
final class FocusAudio {
    private var engine: AVAudioEngine?
    private var chimeNode: AVAudioPlayerNode?
    private var chimeBuffer: AVAudioPCMBuffer?
    private let noise = NoiseGenerator()
    private(set) var playing: FocusAmbient = .off

    /// Bật/đổi/tắt âm nền. Gọi lại nhiều lần với cùng giá trị không sao.
    func setAmbient(_ ambient: FocusAmbient, volume: Double) {
        noise.setVolume(Float(volume))
        if ambient == playing, ambient == .off || engine?.isRunning == true { return }
        noise.setKind(ambient)
        playing = ambient
        if ambient == .off {
            stopIfIdle()
        } else {
            startEngine()
        }
    }

    func playChime() {
        startEngine()
        guard let engine, engine.isRunning, let chimeNode, let chimeBuffer else { return }
        chimeNode.stop()
        chimeNode.scheduleBuffer(chimeBuffer, completionHandler: nil)
        chimeNode.play()
        // Không có âm nền thì tắt bộ phát sau khi chuông ngân xong.
        if playing == .off {
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                self?.stopIfIdle()
            }
        }
    }

    func stopAll() {
        playing = .off
        noise.setKind(.off)
        stopIfIdle()
    }

    private func stopIfIdle() {
        guard playing == .off, let engine else { return }
        if chimeNode?.isPlaying == true { return }
        engine.stop()
        self.engine = nil
        chimeNode = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startEngine() {
        if let engine, engine.isRunning { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) else { return }
        let engine = AVAudioEngine()
        let gen = noise
        let source = AVAudioSourceNode(format: format) { _, _, frameCount, bufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            guard let out = buffers.first?.mData?.assumingMemoryBound(to: Float.self) else { return noErr }
            gen.render(into: out, count: Int(frameCount))
            return noErr
        }
        let chime = AVAudioPlayerNode()
        engine.attach(source)
        engine.attach(chime)
        engine.connect(source, to: engine.mainMixerNode, format: format)
        engine.connect(chime, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
        } catch {
            return
        }
        self.engine = engine
        chimeNode = chime
        if chimeBuffer == nil { chimeBuffer = Self.makeChime(format: format) }
    }

    /// Hai nốt chuông mềm (Mi – La), tắt dần.
    private static func makeChime(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let rate = format.sampleRate
        let length = Int(rate * 2.0)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(length)),
              let data = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = AVAudioFrameCount(length)
        let notes: [(start: Double, freq: Double)] = [(0, 659.25), (0.28, 880)]
        for i in 0..<length {
            let t = Double(i) / rate
            var v = 0.0
            for n in notes where t >= n.start {
                let lt = t - n.start
                let env = min(1, lt * 80) * exp(-lt * 2.6)
                v += env * (sin(2 * .pi * n.freq * lt) + 0.25 * sin(2 * .pi * n.freq * 2 * lt))
            }
            data[i] = Float(v * 0.22)
        }
        return buffer
    }
}

/// Bộ tạo âm chạy trên luồng âm thanh. Chỉ đọc/ghi các biến số nguyên tử đơn giản; đổi loại âm có lúc chuyển mềm.
private final class NoiseGenerator: @unchecked Sendable {
    private let lock = NSLock()
    private var kind: FocusAmbient = .off
    private var volume: Float = 0.5
    // Trạng thái bộ lọc (chỉ luồng âm thanh dùng).
    private var gain: Float = 0
    private var brown: Float = 0
    private var low: Float = 0
    private var phase: Double = 0
    private var dropLeft = 0
    private var dropFreq: Float = 0
    private var dropT: Float = 0
    private var seed: UInt64 = 0x2545_F491_4F6C_DD1D

    func setKind(_ k: FocusAmbient) { lock.lock(); kind = k; lock.unlock() }
    func setVolume(_ v: Float) { lock.lock(); volume = max(0, min(1, v)); lock.unlock() }

    private func white() -> Float {
        seed ^= seed << 13
        seed ^= seed >> 7
        seed ^= seed << 17
        return Float(Int64(bitPattern: seed) >> 11) / Float(1 << 52) // khoảng -1...1
    }

    func render(into out: UnsafeMutablePointer<Float>, count: Int) {
        lock.lock()
        let k = kind
        let vol = volume
        lock.unlock()
        let target: Float = k == .off ? 0 : vol
        let rate: Double = 44_100
        for i in 0..<count {
            // Đổi âm lượng/loại âm từ từ, không có tiếng "bụp".
            gain += (target - gain) * 0.0005
            let w = white()
            brown = (brown + 0.02 * w) / 1.02
            var s: Float
            switch k {
            case .off:
                s = brown * 3
            case .brown:
                s = brown * 3.2
            case .rain:
                low += 0.35 * (w - low)
                s = (w - low) * 0.18 + brown * 1.2
                if dropLeft == 0, white() > 0.9993 {
                    dropLeft = 900
                    dropFreq = 1800 + abs(white()) * 2600
                    dropT = 0
                }
                if dropLeft > 0 {
                    let env = Float(dropLeft) / 900
                    s += sin(2 * .pi * dropFreq * dropT) * env * env * 0.12
                    dropT += 1 / Float(rate)
                    dropLeft -= 1
                }
            case .waves:
                phase += 1 / (rate * 9)
                if phase >= 1 { phase -= 1 }
                let swell = Float(0.5 - 0.5 * cos(2 * .pi * phase))
                low += 0.08 * (w - low)
                s = brown * (0.9 + 2.6 * swell * swell) + low * 0.25 * swell
            }
            out[i] = max(-1, min(1, s * gain * 0.6))
        }
    }
}
