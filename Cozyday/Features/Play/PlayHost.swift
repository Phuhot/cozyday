import SwiftUI

/// Phản hồi của một sự kiện trong game (âm thanh + rung), do bộ điều khiển game báo lên.
struct GameFeedbackEvent {
    var cue: GameCue?
    var haptic: Haptic?
    enum Haptic { case tap, bump, success, oops }
}

// MARK: Bộ điều khiển từng game

/// Nhảy Mây: giữ engine + hiệu ứng; nhận kéo ngang (kéo tương đối: ngón tay dời bao nhiêu, bạn nhỏ dời bấy nhiêu).
@MainActor
@Observable
final class JumpController {
    private(set) var engine: CloudJumpEngine
    private(set) var effects: [GameEffect] = []
    private(set) var lastBounceAt: TimeInterval = -10
    private(set) var lastHitAt: TimeInterval = -10
    @ObservationIgnored private var dragStart: (finger: Double, pet: Double)?
    @ObservationIgnored private var effectID = 0
    let pointsPerUnit: Double
    /// Chỉ trong bản Debug khi chụp ảnh xem trước: tự chơi.
    @ObservationIgnored var autoplay = false
    @ObservationIgnored private var botStanding = 0.0

    init(seed: UInt64, size: CGSize) {
        pointsPerUnit = max(1, size.width / CloudJumpEngine.worldWidth)
        engine = CloudJumpEngine(seed: seed, viewHeight: Double(size.height / size.width) * CloudJumpEngine.worldWidth)
    }

    func drag(toX x: CGFloat) {
        let fingerX = Double(x) / pointsPerUnit
        if dragStart == nil { dragStart = (fingerX, engine.petX) }
        guard let start = dragStart else { return }
        engine.setTarget(x: start.pet + (fingerX - start.finger) * 1.15)
    }

    func endDrag() {
        dragStart = nil
        engine.setTarget(x: engine.petX)
    }

    /// VoiceOver: vuốt lên/xuống trên vùng chơi để dời sang phải/trái.
    func nudge(_ delta: Double) { engine.setTarget(x: engine.targetX + delta) }

    func advance(_ dt: TimeInterval, feedback: (GameFeedbackEvent) -> Void) {
        if autoplay { drivePreviewBot() }
        for event in engine.step(dt) {
            switch event {
            case .bounce:
                lastBounceAt = engine.time
                feedback(GameFeedbackEvent(cue: .bounce, haptic: nil))
            case .star:
                effectID += 1
                effects.append(GameEffect(id: effectID, kind: .sparkle, x: engine.petX, y: engine.petY + 8, start: engine.time))
                effectID += 1
                effects.append(GameEffect(id: effectID, kind: .plus(CloudJumpEngine.pointsPerStar), x: engine.petX, y: engine.petY + 16, start: engine.time))
                feedback(GameFeedbackEvent(cue: .star, haptic: .tap))
            case .broke:
                effectID += 1
                effects.append(GameEffect(id: effectID, kind: .sparkle, x: engine.petX, y: engine.petY - 1, start: engine.time))
                feedback(GameFeedbackEvent(cue: .flip, haptic: nil))
            case .hit:
                lastHitAt = engine.time
                feedback(GameFeedbackEvent(cue: .bad, haptic: .bump))
            case .fell:
                feedback(GameFeedbackEvent(cue: .fall, haptic: .oops))
            }
        }
        effects.removeAll { engine.time - $0.start > GameEffect.lifetime }
        if effects.count > 12 { effects.removeFirst(effects.count - 12) }
    }

    private func drivePreviewBot() {
        if engine.velY > CloudJumpEngine.jumpSpeed - 5 { botStanding = engine.petY }
        // Bị chặn: lái về mây bên dưới.
        if engine.velY < 0, engine.petY < botStanding + 1,
           let below = engine.platforms.filter({ $0.y <= engine.petY }).max(by: { $0.y < $1.y }) {
            engine.setTarget(x: below.x(at: engine.time))
            return
        }
        if let next = engine.platforms.filter({ $0.y > botStanding + 1 }).min(by: { $0.y < $1.y }) {
            engine.setTarget(x: next.x(at: engine.time))
        }
    }

    var isOver: Bool { engine.isOver }
}

/// Giỏ Quà.
@MainActor
@Observable
final class BasketController {
    private(set) var engine: GiftBasketEngine
    private(set) var effects: [GameEffect] = []
    private(set) var mood: PetSpriteKind = .idle
    @ObservationIgnored private var moodUntil: TimeInterval = 0
    @ObservationIgnored private var dragStart: (finger: Double, basket: Double)?
    @ObservationIgnored private var effectID = 0
    let pointsPerUnit: Double
    @ObservationIgnored var autoplay = false

    init(seed: UInt64, size: CGSize) {
        pointsPerUnit = max(1, size.width / GiftBasketEngine.worldWidth)
        engine = GiftBasketEngine(seed: seed, viewHeight: Double(size.height / size.width) * GiftBasketEngine.worldWidth)
    }

    func drag(toX x: CGFloat) {
        let fingerX = Double(x) / pointsPerUnit
        if dragStart == nil { dragStart = (fingerX, engine.basketX) }
        guard let start = dragStart else { return }
        engine.setTarget(x: start.basket + (fingerX - start.finger) * 1.2)
    }

    func endDrag() {
        dragStart = nil
        engine.setTarget(x: engine.basketX)
    }

    func nudge(_ delta: Double) { engine.setTarget(x: engine.targetX + delta) }

    func advance(_ dt: TimeInterval, feedback: (GameFeedbackEvent) -> Void) {
        if autoplay, let target = engine.items.filter({ $0.kind.isGood }).min(by: { $0.y < $1.y }) {
            engine.setTarget(x: target.x)
        }
        for event in engine.step(dt) {
            switch event {
            case .caught(let kind, let points, let combo):
                effectID += 1
                effects.append(GameEffect(id: effectID, kind: .plus(points), x: engine.basketX, y: GiftBasketEngine.basketY + 8, start: engine.time))
                effectID += 1
                effects.append(GameEffect(id: effectID, kind: .sparkle, x: engine.basketX, y: GiftBasketEngine.basketY + 2, start: engine.time))
                setMood(combo >= 8 ? .cheer : .happy, for: 0.45)
                feedback(GameFeedbackEvent(cue: kind == .gift || kind == .star ? .star : .good, haptic: kind == .gift ? .tap : nil))
            case .hitBad(_, let lost):
                effectID += 1
                effects.append(GameEffect(id: effectID, kind: .minus(lost), x: engine.basketX, y: GiftBasketEngine.basketY + 8, start: engine.time))
                setMood(.surprised, for: 0.6)
                feedback(GameFeedbackEvent(cue: .bad, haptic: .bump))
            case .missed:
                break
            case .finished:
                setMood(.cheer, for: 5)
                feedback(GameFeedbackEvent(cue: .win, haptic: .success))
            }
        }
        if engine.time > moodUntil && mood != .idle { mood = .idle }
        effects.removeAll { engine.time - $0.start > GameEffect.lifetime }
        if effects.count > 12 { effects.removeFirst(effects.count - 12) }
    }

    private func setMood(_ kind: PetSpriteKind, for seconds: TimeInterval) {
        mood = kind
        moodUntil = engine.time + seconds
    }

    var isOver: Bool { engine.isOver }
}

/// Lật Thẻ: bàn chơi + khóa trong lúc úp cặp sai (lệnh úp trễ mang mã, mã cũ bị bỏ qua).
@MainActor
@Observable
final class MemoryController {
    private(set) var board: MemoryBoard
    private(set) var reaction: String
    private(set) var mood: PetSpriteKind = .idle
    private(set) var reactionCount = 0
    @ObservationIgnored private var resolveTask: Task<Void, Never>?
    @ObservationIgnored var autoplay = false
    /// Xem trước: chỉ tự ghép bấy nhiêu cặp rồi dừng.
    @ObservationIgnored var autoplayPairs = Int.max
    private let petName: String

    static let mismatchDelay: UInt64 = 850_000_000

    init(level: MemoryLevel, seed: UInt64, petName: String) {
        board = MemoryBoard(level: level, seed: seed)
        self.petName = petName
        reaction = "Lật hai thẻ giống nhau nhé!"
    }

    /// `running`: chỉ nhận lật thẻ khi lượt đang chạy (không khi tạm dừng/đếm ngược/đã xong).
    func flip(_ index: Int, running: Bool, feedback: (GameFeedbackEvent) -> Void) {
        guard running else { return }
        let result = board.flip(index)
        switch result {
        case .ignored:
            return
        case .opened:
            feedback(GameFeedbackEvent(cue: .flip, haptic: .tap))
        case .matched:
            say(["Đúng rồi!", "Giỏi quá!", "Một cặp nữa nè!", "Trí nhớ siêu ghê!"], mood: .happy)
            feedback(GameFeedbackEvent(cue: .match, haptic: .tap))
        case .completed:
            say(["Hoan hô! Xong cả bàn rồi!"], mood: .cheer)
            feedback(GameFeedbackEvent(cue: .win, haptic: .success))
        case .mismatch(let token):
            say(["Gần đúng rồi, thử lại nha!", "Không sao, nhớ vị trí nè!", "Hai bạn này khác nhau rồi~"], mood: .surprised)
            feedback(GameFeedbackEvent(cue: .miss, haptic: nil))
            resolveTask?.cancel()
            resolveTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: Self.mismatchDelay)
                guard !Task.isCancelled else { return }
                self?.board.resolveMismatch(token: token)
            }
        }
    }

    private func say(_ lines: [String], mood: PetSpriteKind) {
        reactionCount += 1
        reaction = lines[reactionCount % lines.count]
        self.mood = mood
    }

    /// Xem trước (Debug): mở lần lượt từng cặp đúng.
    func autoplayStep(running: Bool, feedback: (GameFeedbackEvent) -> Void) {
        guard autoplay, running, !board.isLocked, !board.isComplete, board.pairsFound < autoplayPairs || !board.openUnmatched.isEmpty else { return }
        let open = board.openUnmatched
        if let first = open.first {
            if let mate = board.cards.indices.first(where: { $0 != first && board.cards[$0].face == board.cards[first].face }) {
                flip(mate, running: running, feedback: feedback)
            }
        } else if let next = board.cards.indices.first(where: { board.cards[$0].state == .down }) {
            flip(next, running: running, feedback: feedback)
        }
    }

    func teardown() {
        resolveTask?.cancel()
        resolveTask = nil
    }

    var isOver: Bool { board.isComplete }
}

// MARK: Lượt chơi

/// Một lượt chơi: trạng thái (ready → countdown → playing ⇄ paused → finished / abandoned), đồng hồ lượt,
/// vòng lặp khung hình, âm thanh, rung; khi xong thì lưu kết quả qua AppStore (một lần, có thể thử lại cùng sessionID).
@MainActor
@Observable
final class PlayHostModel: Identifiable {
    let kind: MinigameKind
    let level: MemoryLevel
    /// Ngoại hình được chụp cố định lúc bắt đầu lượt.
    let appearance: PetAppearance
    let petName: String
    private(set) var session: PlaySession
    private(set) var runClock = RunClock()
    private(set) var now: TimeInterval = 0
    private(set) var jump: JumpController?
    private(set) var basket: BasketController?
    private(set) var memory: MemoryController?
    private(set) var sprites: [PetSpriteKind: Image] = [:]
    private(set) var outcome: MinigameOutcome?
    private(set) var saved: MinigameSave?
    private(set) var saveError: String?
    private(set) var isSaving = false
    private(set) var startedAt: Date?

    private let store: AppStore
    private let loop = GameLoop()
    let sound: GameSound
    let haptics: GameHaptics
    @ObservationIgnored private var lastCountdown: Int?
    @ObservationIgnored var previewAutoplay = false
    @ObservationIgnored var previewMemoryPairs = Int.max
    @ObservationIgnored private var autoplayAccumulator: TimeInterval = 0

    /// = sessionID của lượt.
    nonisolated let id: UUID

    init(kind: MinigameKind, level: MemoryLevel, appearance: PetAppearance, petName: String, store: AppStore,
         soundOn: Bool, hapticsOn: Bool) {
        self.kind = kind
        self.level = level
        self.appearance = appearance
        self.petName = petName
        self.store = store
        let sessionID = UUID()
        id = sessionID
        session = PlaySession(id: sessionID)
        sound = GameSound(enabled: soundOn)
        haptics = GameHaptics(enabled: hapticsOn)
        loop.onFrame = { [weak self] t, dt in self?.frame(t, dt) }
    }

    var isConfigured: Bool { jump != nil || basket != nil || memory != nil }

    /// Tạo bàn chơi theo kích thước vùng chơi và dựng sẵn ảnh bạn nhỏ (một lần).
    func configure(size: CGSize, scale: CGFloat) {
        guard !isConfigured, size.width > 10, size.height > 10 else { return }
        let seed = session.id.seed
        switch kind {
        case .cloudJump:
            let c = JumpController(seed: seed, size: size)
            c.autoplay = previewAutoplay
            jump = c
            sprites = PetSpriteCache.shared.sprites(for: appearance, points: size.width * CloudJumpPainter.petWidth / 100, scale: scale)
        case .giftBasket:
            let c = BasketController(seed: seed, size: size)
            c.autoplay = previewAutoplay
            basket = c
            sprites = PetSpriteCache.shared.sprites(for: appearance, points: size.width * GiftBasketPainter.petWidth / 100, scale: scale)
        case .memoryMatch:
            let c = MemoryController(level: level, seed: seed, petName: petName)
            c.autoplay = previewAutoplay
            c.autoplayPairs = previewMemoryPairs
            memory = c
        }
    }

    // MARK: Điều khiển

    func begin() {
        guard isConfigured, session.phase == .ready else { return }
        sound.prepare()
        startedAt = Date()
        session.start(at: GameLoop.now)
        lastCountdown = nil
        loop.start()
    }

    /// Tạm dừng: nút, vào nền, khóa máy, cuộc gọi. Thời gian lượt ngừng trôi, vòng lặp dừng hẳn.
    func pause() {
        switch session.phase {
        case .playing, .countdown:
            session.pause()
            runClock.stop(at: GameLoop.now)
            loop.stop()
        default:
            break
        }
    }

    /// Tiếp tục luôn qua đếm ngược 3 giây.
    func resume() {
        guard session.phase == .paused else { return }
        session.resume(at: GameLoop.now)
        lastCountdown = nil
        loop.start()
    }

    /// Thoát giữa lượt: không có kết quả, không có xu.
    func abandon() {
        session.abandon()
        teardown()
    }

    /// Dọn mọi thứ đang chạy (gọi khi rời màn chơi).
    func teardown() {
        loop.stop()
        memory?.teardown()
        sound.stop()
    }

    var activeSeconds: TimeInterval {
        switch kind {
        case .cloudJump: return jump?.engine.time ?? 0
        case .giftBasket: return basket?.engine.time ?? 0
        case .memoryMatch: return runClock.elapsed(at: GameLoop.now)
        }
    }

    private func frame(_ t: TimeInterval, _ dt: TimeInterval) {
        now = t
        let wasPlaying = session.isRunning
        session.tick(at: t)
        if let n = session.countdownRemaining(at: t), n != lastCountdown {
            lastCountdown = n
            sound.play(.tick)
        }
        if session.isRunning && !wasPlaying {
            runClock.run(at: t)
            sound.play(.go)
            haptics.tap()
            // Lật thẻ không cần vẽ theo khung hình: tắt vòng lặp cho đỡ tốn pin (trừ khi tự chơi xem trước).
            if kind == .memoryMatch && !previewAutoplay { loop.stop() }
            return
        }
        guard session.isRunning else { return }
        switch kind {
        case .cloudJump:
            jump?.advance(dt, feedback: handle)
            if jump?.isOver == true { finish() }
        case .giftBasket:
            basket?.advance(dt, feedback: handle)
            if basket?.isOver == true { finish() }
        case .memoryMatch:
            autoplayAccumulator += dt
            if autoplayAccumulator > 0.4 {
                autoplayAccumulator = 0
                memory?.autoplayStep(running: true, feedback: handle)
                if memory?.isOver == true { finish() }
            }
        }
    }

    func flip(_ index: Int) {
        memory?.flip(index, running: session.isRunning, feedback: handle)
        if memory?.isOver == true { finish() }
    }

    private func handle(_ event: GameFeedbackEvent) {
        if let cue = event.cue { sound.play(cue) }
        switch event.haptic {
        case .tap?: haptics.tap()
        case .bump?: haptics.bump()
        case .success?: haptics.success()
        case .oops?: haptics.oops()
        case nil: break
        }
    }

    // MARK: Kết thúc & lưu

    private func finish() {
        guard session.isRunning else { return }
        let end = GameLoop.now
        session.finish()
        runClock.stop(at: end)
        loop.stop()
        let finishedAt = Date()
        let o: MinigameOutcome
        switch kind {
        case .cloudJump:
            let e = jump?.engine
            o = MinigameOutcome(sessionID: session.id, kind: kind, score: e?.score ?? 0, primary: e?.heightMeters ?? 0,
                                secondary: e?.starsCollected ?? 0, level: nil, activeSeconds: e?.time ?? 0,
                                completed: e?.isOver ?? false, species: appearance.species.rawValue,
                                startedAt: startedAt ?? finishedAt, finishedAt: finishedAt)
        case .giftBasket:
            let e = basket?.engine
            o = MinigameOutcome(sessionID: session.id, kind: kind, score: e?.score ?? 0, primary: e?.caughtGood ?? 0,
                                secondary: e?.bestCombo ?? 0, level: nil, activeSeconds: e?.time ?? 0,
                                completed: e?.isOver ?? false, species: appearance.species.rawValue,
                                startedAt: startedAt ?? finishedAt, finishedAt: finishedAt)
        case .memoryMatch:
            let b = memory?.board
            let seconds = runClock.elapsed(at: end)
            o = MinigameOutcome(sessionID: session.id, kind: kind,
                                score: b.map { MemoryBoard.score(level: level, moves: $0.moves, seconds: seconds) } ?? 0,
                                primary: b?.moves ?? 0, secondary: b?.pairsFound ?? 0, level: level, activeSeconds: seconds,
                                completed: b?.isComplete ?? false, species: appearance.species.rawValue,
                                startedAt: startedAt ?? finishedAt, finishedAt: finishedAt)
        }
        outcome = o
        save()
    }

    /// Lưu kết quả (tự động khi xong lượt). Lỗi tạm thời: thử lại với cùng sessionID — không bao giờ nhận hai lần.
    func save() {
        guard let outcome, saved == nil, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            saved = try store.recordMinigame(outcome)
            saveError = nil
            if (saved?.record.coins ?? 0) > 0 { sound.play(.star) }
        } catch {
            saveError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
