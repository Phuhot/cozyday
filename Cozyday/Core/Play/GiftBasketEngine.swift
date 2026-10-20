import Foundation

enum DropKind: Int, CaseIterable, Equatable {
    case apple, cherry, star, gift
    case mud, rain

    var isGood: Bool { self != .mud && self != .rain }

    /// Điểm gốc của món tốt; món xấu trừ `badPenalty`.
    var points: Int {
        switch self {
        case .apple, .cherry: return 1
        case .star: return 2
        case .gift: return 5
        case .mud, .rain: return 0
        }
    }

    var radius: Double { self == .gift ? 5.5 : 4.5 }

    var name: String {
        switch self {
        case .apple: return "táo"
        case .cherry: return "anh đào"
        case .star: return "ngôi sao"
        case .gift: return "hộp quà"
        case .mud: return "cục bùn"
        case .rain: return "mây mưa"
        }
    }
}

struct DropItem: Identifiable, Equatable {
    let id: Int
    let kind: DropKind
    let x: Double
    var y: Double
    let speed: Double
    /// Đã xử lý (hứng được hoặc rơi mất) — mỗi món chỉ được tính một lần.
    var resolved = false
}

enum BasketEvent: Equatable {
    case caught(DropKind, points: Int, combo: Int)
    case hitBad(DropKind, lost: Int)
    case missed(DropKind)
    case finished
}

/// Logic Giỏ Quà — thuần, không vẽ. Rộng 100, y hướng lên, giỏ ở đáy. Lượt dài đúng 60 giây thời gian chạy.
struct GiftBasketEngine {
    static let duration = MinigameConfig.basketDuration
    static let worldWidth = 100.0
    /// Miệng giỏ: món đi qua độ cao này trong tầm giỏ thì được hứng.
    static let basketY = 15.0
    static let basketHalfWidth = 11.0
    static let maxSpeedX = 220.0
    static let maxItems = 16
    static let badPenalty = 3

    static func multiplier(combo: Int) -> Int { 1 + min(2, max(0, combo - 1) / 8) }

    let viewHeight: Double
    private(set) var time = 0.0
    private(set) var score = 0
    private(set) var combo = 0
    private(set) var bestCombo = 0
    private(set) var caughtGood = 0
    private(set) var caughtBad = 0
    private(set) var missedGood = 0
    private(set) var spawned = 0
    private(set) var basketX = 50.0
    private(set) var targetX = 50.0
    private(set) var items: [DropItem] = []
    private(set) var isOver = false

    private var rng: SeededRandom
    private var nextSpawn = 0.6
    private var nextID = 1
    private let spawns: Bool

    /// - Parameter spawns: false chỉ dùng trong test (tự thêm món bằng `inject`).
    init(seed: UInt64, viewHeight: Double = 170, spawns: Bool = true) {
        self.viewHeight = viewHeight
        self.spawns = spawns
        rng = SeededRandom(seed: seed)
    }

    var remaining: Double { max(0, Self.duration - time) }
    var progress: Double { min(1, time / Self.duration) }

    mutating func setTarget(x: Double) {
        targetX = min(max(x, Self.basketHalfWidth), Self.worldWidth - Self.basketHalfWidth)
    }

    /// Chỉ dùng trong test.
    mutating func inject(_ kind: DropKind, x: Double, y: Double, speed: Double) {
        items.append(DropItem(id: nextID, kind: kind, x: x, y: y, speed: speed))
        nextID += 1
    }

    @discardableResult
    mutating func step(_ dt: TimeInterval) -> [BasketEvent] {
        guard !isOver else { return [] }
        var events: [BasketEvent] = []
        for raw in StepClock.substeps(for: dt) {
            let s = min(raw, Self.duration - time)
            if s > 0 {
                time += s
                let dx = targetX - basketX
                basketX += max(-Self.maxSpeedX * s, min(Self.maxSpeedX * s, dx))
                if spawns {
                    while time >= nextSpawn {
                        if items.count < Self.maxItems { spawn() }
                        nextSpawn += interval(at: nextSpawn)
                    }
                }
                for i in items.indices where !items[i].resolved {
                    let previous = items[i].y
                    items[i].y -= items[i].speed * s
                    let item = items[i]
                    if previous > Self.basketY && item.y <= Self.basketY
                        && abs(item.x - basketX) <= Self.basketHalfWidth + item.kind.radius * 0.6 {
                        items[i].resolved = true
                        events.append(apply(item.kind))
                    } else if item.y < -8 {
                        items[i].resolved = true
                        if item.kind.isGood {
                            missedGood += 1
                            events.append(.missed(item.kind))
                        }
                    }
                }
                items.removeAll { $0.resolved }
            }
            if time >= Self.duration {
                // Hết giờ: chốt kết quả, không nhận thêm điểm.
                isOver = true
                events.append(.finished)
                break
            }
        }
        return events
    }

    private mutating func apply(_ kind: DropKind) -> BasketEvent {
        if kind.isGood {
            combo += 1
            bestCombo = max(bestCombo, combo)
            caughtGood += 1
            let points = kind.points * Self.multiplier(combo: combo)
            score += points
            return .caught(kind, points: points, combo: combo)
        }
        caughtBad += 1
        combo = 0
        let lost = min(score, Self.badPenalty)
        score -= lost
        return .hitBad(kind, lost: lost)
    }

    private func interval(at t: Double) -> Double {
        let k = min(1, t / Self.duration)
        return 0.85 + (0.42 - 0.85) * k
    }

    private mutating func spawn() {
        let k = min(1, time / Self.duration)
        let roll = Double.random(in: 0..<1, using: &rng)
        let bad = 0.12 + (0.26 - 0.12) * k
        let kind: DropKind
        if roll < bad { kind = Bool.random(using: &rng) ? .mud : .rain }
        else if roll < bad + 0.06 { kind = .gift }
        else if roll < bad + 0.2 { kind = .star }
        else { kind = Bool.random(using: &rng) ? .apple : .cherry }
        let speed = (42 + (85 - 42) * k) * Double.random(in: 0.9...1.15, using: &rng)
        let x = Double.random(in: 8...92, using: &rng)
        items.append(DropItem(id: nextID, kind: kind, x: x, y: viewHeight + 8, speed: speed))
        nextID += 1
        spawned += 1
    }
}
