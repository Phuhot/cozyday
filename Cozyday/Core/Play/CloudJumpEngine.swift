import Foundation

/// Một đám mây (bệ) trong Nhảy Mây. `y` là mặt trên; bệ di chuyển dao động ngang quanh `baseX`.
struct JumpPlatform: Identifiable, Equatable {
    let id: Int
    let baseX: Double
    let y: Double
    let width: Double
    let amplitude: Double
    let speed: Double
    let phase: Double

    init(id: Int, x: Double, y: Double, width: Double, amplitude: Double = 0, speed: Double = 0, phase: Double = 0) {
        self.id = id
        self.baseX = x
        self.y = y
        self.width = width
        self.amplitude = amplitude
        self.speed = speed
        self.phase = phase
    }

    var isMoving: Bool { amplitude > 0 }
    func x(at t: Double) -> Double { baseX + amplitude * sin(phase + speed * t) }
}

struct JumpStar: Identifiable, Equatable {
    let id: Int
    let x: Double
    let y: Double
}

enum JumpEvent: Equatable {
    case bounce(platformID: Int)
    case star
    case fell
}

/// Logic Nhảy Mây — thuần, không vẽ. Hệ tọa độ: rộng 100, trục y hướng lên, mặt đất y = 0.
/// Thời gian chỉ trôi khi lớp giao diện gọi `step` (đang chơi), chia nhỏ theo `StepClock`.
///
/// Đảm bảo chơi được: khoảng cách dọc giữa hai bệ liền nhau ≤ `maxGap` (< 80% độ cao nảy),
/// khoảng cách ngang (cộng biên độ bệ di chuyển) ≤ 60% quãng ngang đi được trong lúc nảy tới bệ đó.
/// Hitbox của bạn nhỏ cố định — không phụ thuộc loài hay trang phục.
struct CloudJumpEngine {
    static let worldWidth = 100.0
    static let gravity = 230.0
    static let jumpSpeed = 150.0
    static let maxSpeedX = 90.0
    /// Nửa bề rộng bàn chân khi xét chạm bệ.
    static let footHalfWidth = 4.0
    static let bodyHeight = 12.0
    static let unitsPerMeter = 10.0
    static let maxPlatforms = 40
    static let maxStars = 10
    static let maxGap = 38.0
    static let reactionTime = 0.2
    static let reachSafety = 0.6
    static let pointsPerStar = 3

    /// Độ cao tối đa của một lần nảy.
    static var apex: Double { jumpSpeed * jumpSpeed / (2 * gravity) }

    /// Quãng ngang tối đa đi được khi nảy lên một bệ cao hơn `dy` (trừ thời gian phản xạ).
    static func reach(dy: Double) -> Double {
        let disc = jumpSpeed * jumpSpeed - 2 * gravity * dy
        guard disc >= 0 else { return 0 }
        let t = (jumpSpeed + disc.squareRoot()) / gravity
        return maxSpeedX * max(0, t - reactionTime)
    }

    static func score(heightMeters: Int, stars: Int) -> Int { heightMeters + stars * pointsPerStar }

    let viewHeight: Double
    private(set) var time = 0.0
    private(set) var petX = 50.0
    /// Độ cao bàn chân.
    private(set) var petY = 0.0
    private(set) var velY = CloudJumpEngine.jumpSpeed
    private(set) var targetX = 50.0
    private(set) var facingLeft = false
    /// Mép dưới của vùng nhìn thấy (chỉ đi lên).
    private(set) var cameraY = 0.0
    /// Mặt trên của bệ cao nhất đã đáp — nguồn tính điểm độ cao (nảy tại chỗ không cộng thêm).
    private(set) var bestPlatformY = 0.0
    private(set) var starsCollected = 0
    private(set) var platforms: [JumpPlatform] = []
    private(set) var stars: [JumpStar] = []
    private(set) var isOver = false
    private(set) var landings = 0
    private(set) var generated = 0

    private var rng: SeededRandom
    private var nextID = 1
    private var topY = 0.0
    private var lastX = 50.0
    private let generates: Bool

    /// - Parameter layout: chỉ dùng trong test — dùng đúng các bệ này, không sinh thêm.
    init(seed: UInt64, viewHeight: Double = 170, layout: [JumpPlatform]? = nil) {
        self.viewHeight = viewHeight
        rng = SeededRandom(seed: seed)
        if let layout {
            platforms = layout
            generates = false
        } else {
            platforms = [JumpPlatform(id: 0, x: 50, y: 0, width: 100)]
            generates = true
            generate()
        }
    }

    var heightMeters: Int { Int(bestPlatformY / Self.unitsPerMeter) }
    var score: Int { Self.score(heightMeters: heightMeters, stars: starsCollected) }
    var difficulty: Double { Self.difficulty(at: bestPlatformY) }

    static func difficulty(at y: Double) -> Double { min(1, max(0, y / 4000)) }

    /// Ngón tay kéo ngang: đặt điểm đến, bạn nhỏ chạy theo với tốc độ tối đa cố định.
    mutating func setTarget(x: Double) {
        targetX = min(max(x, Self.footHalfWidth), Self.worldWidth - Self.footHalfWidth)
    }

    @discardableResult
    mutating func step(_ dt: TimeInterval) -> [JumpEvent] {
        guard !isOver else { return [] }
        var events: [JumpEvent] = []
        for s in StepClock.substeps(for: dt) {
            time += s
            let dx = targetX - petX
            let move = max(-Self.maxSpeedX * s, min(Self.maxSpeedX * s, dx))
            petX = min(max(petX + move, Self.footHalfWidth), Self.worldWidth - Self.footHalfWidth)
            if abs(move) > 0.05 { facingLeft = move < 0 }

            let previous = petY
            velY -= Self.gravity * s
            petY += velY * s
            // Chỉ đáp khi đang rơi và bàn chân đi qua mặt trên của bệ trong bước này.
            if velY < 0 {
                for p in platforms where previous >= p.y && petY <= p.y && abs(petX - p.x(at: time)) <= p.width / 2 + Self.footHalfWidth {
                    petY = p.y
                    velY = Self.jumpSpeed
                    landings += 1
                    bestPlatformY = max(bestPlatformY, p.y)
                    events.append(.bounce(platformID: p.id))
                    break
                }
            }
            for star in stars where abs(star.x - petX) <= 7 && star.y >= petY - 3 && star.y <= petY + Self.bodyHeight + 2 {
                stars.removeAll { $0.id == star.id }
                starsCollected += 1
                events.append(.star)
            }
            cameraY = max(cameraY, petY - viewHeight * 0.4)
            if petY < cameraY - 14 {
                isOver = true
                events.append(.fell)
                break
            }
        }
        platforms.removeAll { $0.y < cameraY - 30 }
        stars.removeAll { $0.y < cameraY - 30 }
        if generates { generate() }
        return events
    }

    private mutating func generate() {
        while topY < cameraY + viewHeight + 60 && platforms.count < Self.maxPlatforms {
            addPlatform()
        }
    }

    private mutating func addPlatform() {
        func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
        let d = Self.difficulty(at: topY)
        let early = topY < 300
        let dy = Double.random(in: (early ? 18 : lerp(18, 26, d))...(early ? 24 : lerp(26, Self.maxGap, d)), using: &rng)
        let width = (early ? 32 : lerp(28, 16, d)) + Double.random(in: -2...2, using: &rng)
        let moving = !early && Double.random(in: 0..<1, using: &rng) < lerp(0.12, 0.4, d)
        let amplitude = moving ? lerp(8, 16, d) : 0
        let speed = moving ? lerp(0.9, 1.5, d) : 0
        let maxDX = max(4, Self.reach(dy: dy) * Self.reachSafety - amplitude)
        let edge = width / 2 + amplitude + 2
        let lo = max(edge, lastX - maxDX), hi = min(Self.worldWidth - edge, lastX + maxDX)
        let x = lo < hi ? Double.random(in: lo...hi, using: &rng) : min(max(lastX, edge), Self.worldWidth - edge)
        let y = topY + dy
        let phase = moving ? Double.random(in: 0..<(2 * .pi), using: &rng) : 0
        platforms.append(JumpPlatform(id: nextID, x: x, y: y, width: width, amplitude: amplitude, speed: speed, phase: phase))
        nextID += 1
        generated += 1
        topY = y
        lastX = x
        if stars.count < Self.maxStars, Double.random(in: 0..<1, using: &rng) < 0.3 {
            let sx = min(max(x + Double.random(in: -10...10, using: &rng), 8), Self.worldWidth - 8)
            stars.append(JumpStar(id: nextID, x: sx, y: y + Double.random(in: 18...32, using: &rng)))
            nextID += 1
        }
    }
}
