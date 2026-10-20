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
    /// Mây mỏng: nảy được một lần rồi tan.
    let fragile: Bool

    init(id: Int, x: Double, y: Double, width: Double, amplitude: Double = 0, speed: Double = 0, phase: Double = 0, fragile: Bool = false) {
        self.id = id
        self.baseX = x
        self.y = y
        self.width = width
        self.amplitude = amplitude
        self.speed = speed
        self.phase = phase
        self.fragile = fragile
    }

    var isMoving: Bool { amplitude > 0 }
    func x(at t: Double) -> Double { baseX + amplitude * sin(phase + speed * t) }
}

struct JumpStar: Identifiable, Equatable {
    let id: Int
    let x: Double
    let y: Double
}

/// Chướng ngại: mây giông đứng gần đường bay, chim nhỏ bay ngang qua. Chạm vào thì mất đà và rơi xuống
/// (không mất lượt ngay — lái về mây bên dưới là nảy tiếp được).
struct JumpHazard: Identifiable, Equatable {
    enum Kind: Equatable { case storm, bird }

    let id: Int
    let kind: Kind
    let baseX: Double
    let y: Double
    let amplitude: Double
    let speed: Double
    let phase: Double

    var radius: Double { kind == .storm ? 7 : 5 }
    func x(at t: Double) -> Double { baseX + amplitude * sin(phase + speed * t) }
    /// Hướng bay (chim quay đầu theo chiều đang bay).
    func movingLeft(at t: Double) -> Bool { amplitude > 0 && cos(phase + speed * t) < 0 }
}

enum JumpEvent: Equatable {
    case bounce(platformID: Int)
    case broke(platformID: Int)
    case star
    case hit(JumpHazard.Kind)
    case fell
}

/// Logic Nhảy Mây — thuần, không vẽ. Hệ tọa độ: rộng 100, trục y hướng lên, mặt đất y = 0.
/// Thời gian chỉ trôi khi lớp giao diện gọi `step` (đang chơi), chia nhỏ theo `StepClock`.
///
/// Đảm bảo chơi được: khoảng cách dọc giữa hai bệ liền nhau ≤ `maxGap` (< 80% độ cao nảy),
/// khoảng cách ngang (cộng biên độ bệ di chuyển) ≤ 60% quãng ngang đi được trong lúc nảy tới bệ đó.
/// Hitbox của bạn nhỏ cố định — không phụ thuộc loài hay trang phục.
///
/// Chướng ngại không làm mất khả năng leo: mây giông đặt ngoài hành lang giữa hai bệ liền nhau;
/// chim chỉ bay qua khi bệ bên dưới là mây chắc (đứng nảy tại chỗ chờ chim bay qua được).
/// Mây mỏng không bao giờ đứng ngay dưới một con chim.
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
    static let maxHazards = 8
    /// Bị chướng ngại chặn: mất đà bay lên, rơi nhẹ xuống (kịp lái về mây bên dưới).
    static let knockSpeed = -20.0
    /// Độ cao (đơn vị thế giới) hết vùng khởi động dễ.
    static let warmup = 120.0

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
    private(set) var hazards: [JumpHazard] = []
    private(set) var hits = 0
    private(set) var isOver = false
    private(set) var landings = 0
    private(set) var generated = 0

    private var rng: SeededRandom
    private var nextID = 1
    private var topY = 0.0
    private var lastX = 50.0
    private var lastWidth = 100.0
    private var lastAmplitude = 0.0
    private var lastFragile = false
    /// Bệ trước bệ cuối (tâm, nửa bề rộng gồm biên độ) — chướng ngại cũng tránh khỏi vùng của nó.
    private var prevX = 50.0
    private var prevHalf = 50.0
    private let generates: Bool

    /// - Parameters:
    ///   - layout: chỉ dùng trong test — dùng đúng các bệ này, không sinh thêm.
    ///   - hazards: chỉ dùng trong test — chướng ngại cố định đi kèm `layout`.
    init(seed: UInt64, viewHeight: Double = 170, layout: [JumpPlatform]? = nil, hazards: [JumpHazard] = []) {
        self.viewHeight = viewHeight
        rng = SeededRandom(seed: seed)
        if let layout {
            platforms = layout
            self.hazards = hazards
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

    /// 0 ở mặt đất → 1 ở 160 m (trước đây 400 m — quá dễ quá lâu).
    static func difficulty(at y: Double) -> Double { min(1, max(0, y / 1600)) }

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
                    if p.fragile {
                        platforms.removeAll { $0.id == p.id }
                        events.append(.broke(platformID: p.id))
                    }
                    break
                }
            }
            // Chạm chướng ngại (tâm thân bạn nhỏ): bị hất xuống, chướng ngại bay đi.
            let bodyY = petY + Self.bodyHeight / 2
            for h in hazards {
                let dx = petX - h.x(at: time), dy = bodyY - h.y
                if (dx * dx + dy * dy).squareRoot() < h.radius + Self.footHalfWidth {
                    hazards.removeAll { $0.id == h.id }
                    velY = min(velY, Self.knockSpeed)
                    hits += 1
                    events.append(.hit(h.kind))
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
        hazards.removeAll { $0.y < cameraY - 30 }
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
        let early = topY < Self.warmup
        let dy = Double.random(in: (early ? 18 : lerp(20, 28, d))...(early ? 24 : lerp(28, Self.maxGap, d)), using: &rng)
        let width = (early ? 32 : lerp(26, 14, d)) + Double.random(in: -2...2, using: &rng)
        let moving = !early && Double.random(in: 0..<1, using: &rng) < lerp(0.2, 0.5, d)
        let amplitude = moving ? lerp(8, 18, d) : 0
        let speed = moving ? lerp(1.0, 1.7, d) : 0
        let maxDX = max(4, Self.reach(dy: dy) * Self.reachSafety - amplitude)
        let edge = width / 2 + amplitude + 2
        let lo = max(edge, lastX - maxDX), hi = min(Self.worldWidth - edge, lastX + maxDX)
        let x = lo < hi ? Double.random(in: lo...hi, using: &rng) : min(max(lastX, edge), Self.worldWidth - edge)
        let y = topY + dy
        let phase = moving ? Double.random(in: 0..<(2 * .pi), using: &rng) : 0
        // Mây mỏng: không hai cái liền nhau, không ở vùng khởi động.
        let fragile = !early && !lastFragile && Double.random(in: 0..<1, using: &rng) < lerp(0.08, 0.28, d)

        // Chướng ngại nằm giữa bệ trước (lastX, topY) và bệ mới.
        if !early, hazards.count < Self.maxHazards, Double.random(in: 0..<1, using: &rng) < lerp(0.18, 0.5, d) {
            addHazard(before: (x: prevX, half: prevHalf),
                      from: (x: lastX, y: topY, half: lastWidth / 2 + lastAmplitude, fragile: lastFragile),
                      to: (x: x, y: y, half: width / 2 + amplitude), difficulty: d)
        }

        platforms.append(JumpPlatform(id: nextID, x: x, y: y, width: width, amplitude: amplitude, speed: speed, phase: phase, fragile: fragile))
        nextID += 1
        generated += 1
        topY = y
        prevX = lastX
        prevHalf = lastWidth / 2 + lastAmplitude
        lastX = x
        lastWidth = width
        lastAmplitude = amplitude
        lastFragile = fragile
        if stars.count < Self.maxStars, Double.random(in: 0..<1, using: &rng) < 0.3 {
            let sx = min(max(x + Double.random(in: -10...10, using: &rng), 8), Self.worldWidth - 8)
            stars.append(JumpStar(id: nextID, x: sx, y: y + Double.random(in: 18...32, using: &rng)))
            nextID += 1
        }
    }

    /// Khoảng ngang bạn nhỏ có thể đi qua khi nhảy từ bệ `a` lên bệ `b` (cộng biên an toàn).
    static func corridor(_ a: (x: Double, half: Double), _ b: (x: Double, half: Double), margin: Double) -> ClosedRange<Double> {
        min(a.x - a.half, b.x - b.half) - margin...max(a.x + a.half, b.x + b.half) + margin
    }

    /// Các khoảng ngang trong [lo, hi] không chạm vùng nào trong `blocked`.
    static func freeIntervals(blocked: [ClosedRange<Double>], lo: Double, hi: Double) -> [ClosedRange<Double>] {
        var result: [ClosedRange<Double>] = []
        var cursor = lo
        for b in blocked.sorted(by: { $0.lowerBound < $1.lowerBound }) {
            if b.lowerBound > cursor { result.append(cursor...min(hi, b.lowerBound)) }
            cursor = max(cursor, b.upperBound)
            if cursor >= hi { break }
        }
        if cursor < hi { result.append(cursor...hi) }
        return result.filter { $0.upperBound > $0.lowerBound }
    }

    /// Đặt một chướng ngại giữa bệ `a` và bệ `b`, luôn tránh khỏi khoảng ngang của bệ `a` và bệ trước nó `z`
    /// (đứng nảy tại chỗ trên `a` không bao giờ bị chạm). Mây giông tránh cả hành lang a → b;
    /// chim bay qua lại trong một khoảng có thể cắt ngang đường lên `b` — canh lúc chim bay đi rồi nhảy.
    private mutating func addHazard(before z: (x: Double, half: Double),
                                    from a: (x: Double, y: Double, half: Double, fragile: Bool),
                                    to b: (x: Double, y: Double, half: Double), difficulty d: Double) {
        let midY = a.y + (b.y - a.y) * Double.random(in: 0.45...0.7, using: &rng)
        let wantsBird = d > 0.15 && !a.fragile && Bool.random(using: &rng)
        let birdMargin = 5 + Self.footHalfWidth + 3
        let stormMargin = 7 + Self.footHalfWidth + 3
        let lo = 6.0, hi = Self.worldWidth - 6
        if wantsBird {
            let blocked = [a.x - a.half - birdMargin...a.x + a.half + birdMargin,
                           z.x - z.half - birdMargin...z.x + z.half + birdMargin]
            if let lane = Self.freeIntervals(blocked: blocked, lo: lo, hi: hi)
                .filter({ $0.upperBound - $0.lowerBound >= 24 })
                .max(by: { ($0.upperBound - $0.lowerBound) < ($1.upperBound - $1.lowerBound) }) {
                let half = (lane.upperBound - lane.lowerBound) / 2
                hazards.append(JumpHazard(id: nextID, kind: .bird, baseX: lane.lowerBound + half, y: midY,
                                          amplitude: half, speed: (0.9 + 0.8 * d) * 30 / max(12, half),
                                          phase: Double.random(in: 0..<(2 * .pi), using: &rng)))
                nextID += 1
                return
            }
        }
        // Mây giông: đứng yên ngoài hành lang a → b và ngoài vùng của z.
        let blocked = [Self.corridor((a.x, a.half), (b.x, b.half), margin: stormMargin),
                       z.x - z.half - stormMargin...z.x + z.half + stormMargin]
        let lanes = Self.freeIntervals(blocked: blocked, lo: 8, hi: Self.worldWidth - 8)
        guard let lane = lanes.randomElement(using: &rng) else { return }
        let x = Double.random(in: lane, using: &rng)
        hazards.append(JumpHazard(id: nextID, kind: .storm, baseX: x, y: midY, amplitude: 0, speed: 0, phase: 0))
        nextID += 1
    }
}
