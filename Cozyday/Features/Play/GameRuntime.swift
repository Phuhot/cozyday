import SwiftUI
import UIKit
import AVFoundation
import QuartzCore

// Hạ tầng chạy game: vòng lặp khung hình, ảnh dựng sẵn của bạn nhỏ, âm thanh và rung.

/// Vòng lặp theo khung hình màn hình (CADisplayLink trên main run loop) — bật/tắt tường minh,
/// không dùng Timer rải rác. Thời gian lấy từ đồng hồ đơn điệu của hệ thống.
@MainActor
final class GameLoop {
    /// (thời điểm, khoảng thời gian từ khung trước)
    var onFrame: ((TimeInterval, TimeInterval) -> Void)?
    private var link: CADisplayLink?
    private var proxy: Proxy?
    private var last: TimeInterval?

    var isRunning: Bool { link != nil }

    func start(maxFPS: Float = 60) {
        guard link == nil else { return }
        let proxy = Proxy(owner: self)
        let link = CADisplayLink(target: proxy, selector: #selector(Proxy.tick(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: maxFPS, preferred: maxFPS)
        link.add(to: .main, forMode: .common)
        self.link = link
        self.proxy = proxy
        last = nil
    }

    func stop() {
        link?.invalidate()
        link = nil
        proxy = nil
        last = nil
    }

    fileprivate func tick(_ timestamp: TimeInterval) {
        let dt = last.map { max(0, timestamp - $0) } ?? 0
        last = timestamp
        onFrame?(timestamp, dt)
    }

    /// Giữ tham chiếu yếu tới vòng lặp: CADisplayLink giữ mạnh target, nên không tạo vòng giữ nhau.
    private final class Proxy: NSObject {
        weak var owner: GameLoop?
        init(owner: GameLoop) { self.owner = owner }
        @objc func tick(_ link: CADisplayLink) {
            let t = link.timestamp
            MainActor.assumeIsolated { owner?.tick(t) }
        }
    }

    static var now: TimeInterval { CACurrentMediaTime() }
}

/// Ảnh dựng sẵn của bạn nhỏ cho game: mỗi (ngoại hình, tư thế, cỡ) vẽ một lần rồi dùng lại mọi khung hình,
/// thay vì vẽ lại hàng trăm nét mỗi khung. Bộ nhớ đệm có giới hạn (bỏ ảnh dùng lâu nhất).
@MainActor
final class PetSpriteCache {
    static let shared = PetSpriteCache()
    static let limit = 24

    private struct Key: Hashable {
        let look: String
        let kind: PetSpriteKind
        let points: Int
        let scale: Int
    }

    private var images: [Key: Image] = [:]
    private var order: [Key] = []

    var count: Int { images.count }

    func sprites(for appearance: PetAppearance, points: CGFloat, scale: CGFloat) -> [PetSpriteKind: Image] {
        var result: [PetSpriteKind: Image] = [:]
        for kind in PetSpriteKind.allCases {
            if let image = image(appearance, kind: kind, points: points, scale: scale) { result[kind] = image }
        }
        return result
    }

    private func image(_ appearance: PetAppearance, kind: PetSpriteKind, points: CGFloat, scale: CGFloat) -> Image? {
        let key = Key(look: appearance.cacheKey, kind: kind, points: Int(points.rounded()), scale: Int(scale.rounded()))
        if let hit = images[key] {
            order.removeAll { $0 == key }
            order.append(key)
            return hit
        }
        let renderer = ImageRenderer(content:
            PetArt(mood: kind.mood, appearance: appearance, pose: kind.pose).frame(width: points, height: points)
        )
        renderer.scale = max(1, scale)
        guard let ui = renderer.uiImage else { return nil }
        let image = Image(uiImage: ui)
        images[key] = image
        order.append(key)
        while order.count > Self.limit { images[order.removeFirst()] = nil }
        return image
    }
}

extension PetAppearance {
    var cacheKey: String { itemIDs.joined(separator: ",") + "|\(stage.rawValue)" }
}

/// Vẽ bạn nhỏ từ ảnh dựng sẵn (lật ngang khi quay trái).
func spriteDrawer(_ sprites: [PetSpriteKind: Image]) -> PetSpriteDrawer {
    { ctx, rect, kind, facingLeft in
        guard let image = sprites[kind] ?? sprites[.idle] else { return }
        var c = ctx
        if facingLeft {
            c.translateBy(x: rect.midX * 2, y: 0)
            c.scaleBy(x: -1, y: 1)
        }
        c.draw(image, in: rect)
    }
}

// MARK: Âm thanh

enum GameCue: CaseIterable {
    case bounce, star, good, bad, flip, match, miss, win, tick, go, fall
    // Xếp Khối & Gộp Bánh: tiếng giàu hơn (chuông + lấp lánh), cao dần theo chuỗi / bậc món.
    case pickup, place, refill, whoosh, newBest, gameOver
    case clear1, clear2, clear3, clear4, clear5, combo2, combo3
    case merge1, merge2, merge3, merge4

    /// Tiếng xóa đường theo độ dài chuỗi liền tay (1…5, quá 5 giữ nốt cao nhất).
    static func clear(streak: Int) -> GameCue {
        [.clear1, .clear2, .clear3, .clear4, .clear5][min(4, max(0, streak - 1))]
    }

    /// Tiếng gộp theo bậc món vừa tạo.
    static func merge(level: Int) -> GameCue {
        level >= 8 ? .merge4 : level >= 6 ? .merge3 : level >= 4 ? .merge2 : .merge1
    }
}

/// Âm thanh ngắn tự tổng hợp (không dùng tệp âm thanh ngoài). Phiên âm thanh `.ambient` + trộn với âm thanh khác:
/// không ngắt nhạc bạn đang nghe và tự im khi bật công tắc im lặng. Không có nhạc nền.
@MainActor
final class GameSound {
    let enabled: Bool
    private var engine: AVAudioEngine?
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [GameCue: AVAudioPCMBuffer] = [:]
    private var next = 0
    private var lastPlayed: [GameCue: TimeInterval] = [:]

    init(enabled: Bool) { self.enabled = enabled }

    func prepare() {
        guard enabled, engine == nil else { return }
        let session = AVAudioSession.sharedInstance()
        // Đang có âm nền của hẹn giờ thì giữ nguyên phiên của nó, chỉ phát chồng lên.
        if !FocusAudio.inUse { try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers]) }
        try? session.setActive(true)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) else { return }
        let engine = AVAudioEngine()
        var nodes: [AVAudioPlayerNode] = []
        for _ in 0..<6 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            nodes.append(node)
        }
        engine.mainMixerNode.outputVolume = 0.3
        do {
            try engine.start()
        } catch {
            return
        }
        self.engine = engine
        GameSound.activeCount += 1
        players = nodes
        for cue in GameCue.allCases { buffers[cue] = Self.synthesize(cue, format: format) }
    }

    func play(_ cue: GameCue) {
        guard enabled, let engine, engine.isRunning, let buffer = buffers[cue], !players.isEmpty else { return }
        // Không chồng cùng một tiếng quá dày.
        let now = GameLoop.now
        if let last = lastPlayed[cue], now - last < 0.06 { return }
        lastPlayed[cue] = now
        let node = players[next % players.count]
        next += 1
        node.stop()
        node.scheduleBuffer(buffer, completionHandler: nil)
        node.play()
    }

    /// Dừng hẳn (gọi nhiều lần không sao). Chỉ trả phiên âm thanh nếu chính lượt này đã mở nó,
    /// để lệnh dọn trễ của lượt cũ không tắt tiếng của lượt mới (bấm "Chơi lại").
    func stop() {
        guard let engine else { return }
        players.forEach { $0.stop() }
        engine.stop()
        self.engine = nil
        players = []
        buffers = [:]
        GameSound.activeCount -= 1
        if GameSound.activeCount == 0 && !FocusAudio.inUse {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    /// Số bộ phát đang chạy (thường 0 hoặc 1; có thể 2 trong khoảnh khắc chuyển sang lượt mới).
    private static var activeCount = 0

    /// Tiếng "bíp/bóp" mềm: sóng sin + họa âm nhẹ, đường bao tắt dần.
    static func synthesize(_ cue: GameCue, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        if let tones = richTones(cue) { return GameSynth.render(tones, format: format) }
        let notes: [(Double, Double, Double)]
        switch cue {
        case .bounce: notes = [(420, 640, 0.09)]
        case .star: notes = [(988, 988, 0.06), (1319, 1319, 0.1)]
        case .good: notes = [(660, 880, 0.07)]
        case .bad: notes = [(260, 180, 0.14)]
        case .flip: notes = [(1400, 1200, 0.03)]
        case .match: notes = [(784, 784, 0.07), (1047, 1047, 0.11)]
        case .miss: notes = [(392, 330, 0.12)]
        case .win: notes = [(523, 523, 0.08), (659, 659, 0.08), (784, 784, 0.08), (1047, 1047, 0.18)]
        case .tick: notes = [(880, 880, 0.05)]
        case .go: notes = [(1175, 1175, 0.12)]
        case .fall: notes = [(520, 260, 0.32)]
        default: notes = [(660, 660, 0.05)]
        }
        let rate = format.sampleRate
        let total = notes.reduce(0) { $0 + $1.2 }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(total * rate) + 8),
              let data = buffer.floatChannelData?[0] else { return nil }
        var i = 0
        var phase = 0.0
        for (f0, f1, duration) in notes {
            let n = Int(duration * rate)
            for j in 0..<n {
                let t = Double(j) / Double(n)
                phase += 2 * .pi * (f0 + (f1 - f0) * t) / rate
                let envelope = min(1, Double(j) / (0.005 * rate)) * (1 - t) * (1 - t)
                data[i] = Float((sin(phase) + 0.25 * sin(2 * phase)) * envelope * 0.45)
                i += 1
            }
        }
        buffer.frameLength = AVAudioFrameCount(i)
        return buffer
    }
}

/// Rung nhẹ khi chơi — chỉ khi bật cả rung trong Sân chơi và rung trong Cài đặt.
@MainActor
final class GameHaptics {
    let enabled: Bool
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let notify = UINotificationFeedbackGenerator()

    init(enabled: Bool) {
        self.enabled = enabled
        if enabled {
            light.prepare()
            soft.prepare()
        }
    }

    func tap() { if enabled { light.impactOccurred(intensity: 0.6) } }
    func bump() { if enabled { soft.impactOccurred(intensity: 0.8) } }
    func success() { if enabled { notify.notificationOccurred(.success) } }
    func oops() { if enabled { notify.notificationOccurred(.warning) } }
}
