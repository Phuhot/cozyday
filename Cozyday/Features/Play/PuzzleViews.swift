import SwiftUI
import UIKit

// Hai game theo lượt: Xếp Khối (kéo thả khối kẹo dẻo) và Gộp Bánh (vuốt gộp món ngọt).
// Không có vòng lặp theo khung hình: giao diện chỉ vẽ lại khi trạng thái đổi (đặt khối, vuốt, đang kéo),
// hiệu ứng ngắn do SwiftUI tự chạy.

/// Cảm xúc của bạn nhỏ cạnh bàn chơi.
enum PuzzlePetFeeling: Equatable {
    case calm, happy, cheer, worried

    var mood: PetMood {
        switch self {
        case .calm: return .idle
        case .happy, .cheer: return .happy
        case .worried: return .low
        }
    }

    var pose: PetPose {
        var p = PetPose()
        switch self {
        case .calm, .worried: break
        case .happy: p.petted = 1
        case .cheer: p.petted = 1; p.hearts = 0.35
        }
        return p
    }
}

// MARK: Bộ điều khiển Xếp Khối

/// Hiệu ứng nổ khi xóa đường (mỗi lần xóa một mã mới).
struct BlockBurst: Identifiable, Equatable {
    let id: Int
    let cells: [BlockCell]
    let colors: [Int]
    let label: String
    var rows: [Int] = []
    var cols: [Int] = []
    var lines: Int = 1
    var streak: Int = 1

    /// Combo nhiều đường hoặc chuỗi dài: rung bàn, chữ to.
    var isBig: Bool { lines >= 2 || streak >= 3 }

    var callout: (title: String, subtitle: String?)? {
        switch lines {
        case 2: return ("Combo ×2", "Giỏi quá!")
        case 3: return ("Combo ×3", "Siêu đỉnh!")
        case 4...: return ("Combo ×\(lines)", "Không tin nổi!")
        default: return streak >= 3 ? ("Liền tay ×\(streak)", nil) : nil
        }
    }
}

/// Lóe sáng ở các ô vừa đặt khối.
struct BlockPlaceFlash: Identifiable, Equatable {
    let id: Int
    let cells: [BlockCell]
}

@MainActor
@Observable
final class BlocksController {
    private(set) var engine: BlockPuzzleEngine
    private(set) var reaction = "Kéo khối vào bàn nhé!"
    private(set) var feeling: PuzzlePetFeeling = .calm
    private(set) var reactionCount = 0
    private(set) var burst: BlockBurst?
    private(set) var placeFlash: BlockPlaceFlash?
    /// Tăng mỗi khi khay nhận bộ 3 khối mới (để khối nảy vào).
    private(set) var refillCount = 0
    /// Khối đang chọn để đặt bằng chạm (hoặc VoiceOver).
    private(set) var selected: Int?
    @ObservationIgnored var autoplay = false
    @ObservationIgnored private var burstID = 0

    init(seed: UInt64) {
        engine = BlockPuzzleEngine(seed: seed)
    }

    var isOver: Bool { engine.isOver }

    func select(_ slot: Int?, running: Bool) {
        guard running, let slot, engine.tray.indices.contains(slot), engine.tray[slot] != nil else {
            selected = nil
            return
        }
        if selected == slot {
            selected = nil
        } else {
            selected = slot
            say(["Chạm vào bàn để đặt khối này."], feeling: feeling)
        }
    }

    @discardableResult
    func place(slot: Int, row: Int, col: Int, running: Bool, feedback: (GameFeedbackEvent) -> Void) -> Bool {
        guard running, let r = engine.place(slot: slot, row: row, col: col) else { return false }
        react(r, feedback: feedback)
        return true
    }

    /// Đặt khối đang chọn sao cho ô giữa của khối nằm ở `cell`.
    @discardableResult
    func placeSelected(at cell: BlockCell, running: Bool, feedback: (GameFeedbackEvent) -> Void) -> Bool {
        guard running, let slot = selected else { return false }
        guard let r = engine.place(slot: slot, anchoredAt: cell) else {
            feedback(GameFeedbackEvent(cue: .miss, haptic: nil))
            return false
        }
        react(r, feedback: feedback)
        return true
    }

    private func react(_ r: BlockMoveResult, feedback: (GameFeedbackEvent) -> Void) {
        selected = nil
        burstID += 1
        placeFlash = BlockPlaceFlash(id: burstID, cells: r.placed)
        // Tiếng thạch rơi xuống bàn luôn có; tiếng xóa đường / combo chồng lên.
        feedback(GameFeedbackEvent(cue: .place, haptic: r.lines == 0 ? .tap : nil))
        if r.lines > 0 {
            burst = BlockBurst(id: burstID, cells: r.clearedCells, colors: r.clearedColors, label: "+\(r.points)",
                               rows: r.clearedRows, cols: r.clearedCols, lines: r.lines, streak: r.streak)
        }
        if r.refilled && !r.gameOver {
            refillCount += 1
            feedback(GameFeedbackEvent(cue: .refill, haptic: nil))
        }
        if r.gameOver {
            say(["Hết chỗ rồi! Chơi hay lắm."], feeling: .cheer)
            feedback(GameFeedbackEvent(cue: r.lines > 0 ? GameCue.clear(streak: r.streak) : nil, haptic: nil))
            feedback(GameFeedbackEvent(cue: .gameOver, haptic: .success))
            return
        }
        if r.lines >= 2 {
            say(["Combo \(r.lines) đường! Giỏi quá!", "Xóa \(r.lines) đường một lúc luôn!"], feeling: .cheer)
            feedback(GameFeedbackEvent(cue: r.lines >= 3 ? .combo3 : .combo2, haptic: .success))
        } else if r.lines == 1 && r.streak >= 2 {
            say(["Liền tay \(r.streak) lần rồi!", "Giữ chuỗi nha, \(r.streak) lần liền!"], feeling: .cheer)
            feedback(GameFeedbackEvent(cue: GameCue.clear(streak: r.streak), haptic: .bump))
        } else if r.lines == 1 {
            say(["Gọn ghê!", "Xóa được rồi!", "Đẹp quá!", "Thêm một đường nữa nè!"], feeling: .happy)
            feedback(GameFeedbackEvent(cue: GameCue.clear(streak: 1), haptic: .bump))
        } else {
            if engine.fillRatio >= 0.6 {
                if feeling != .worried { say(["Bàn sắp kín rồi, đặt khéo nha!", "Hơi chật rồi, tìm hàng sắp đầy nha!"], feeling: .worried) }
            } else if feeling == .worried || feeling == .cheer {
                say(["Thoáng hơn rồi!", "Cứ từ từ nha."], feeling: .calm)
            }
        }
    }

    func rejectDrop(feedback: (GameFeedbackEvent) -> Void) {
        feedback(GameFeedbackEvent(cue: .miss, haptic: nil))
    }

    private func say(_ lines: [String], feeling: PuzzlePetFeeling) {
        reactionCount += 1
        reaction = lines[reactionCount % lines.count]
        self.feeling = feeling
    }

    /// Xem trước (Debug): đặt một khối theo người chơi máy.
    func autoplayStep(running: Bool, feedback: (GameFeedbackEvent) -> Void) {
        guard autoplay, running, !engine.isOver, let m = BlockPuzzleBot.bestMove(engine) else { return }
        place(slot: m.slot, row: m.row, col: m.col, running: running, feedback: feedback)
    }
}

// MARK: Bộ điều khiển Gộp Bánh

@MainActor
@Observable
final class MergeController {
    private(set) var engine: SweetMergeEngine
    /// Món vừa bị gộp: vẫn vẽ ở ô gộp (dưới món mới) để thấy nó trượt vào. Xóa ở lượt vuốt sau.
    private(set) var ghosts: [SweetTile] = []
    private(set) var reaction = "Vuốt để hai món giống nhau chạm nhau!"
    private(set) var feeling: PuzzlePetFeeling = .calm
    private(set) var reactionCount = 0
    /// Hiệu ứng của lượt vuốt vừa rồi (hạt bắn ở ô gộp, chữ "Món mới").
    private(set) var fx: MergeFX?
    @ObservationIgnored var autoplay = false
    @ObservationIgnored private var bestLevel: Int
    @ObservationIgnored private var fxID = 0

    init(seed: UInt64) {
        let start = SweetMergeEngine(seed: seed)
        engine = start
        bestLevel = start.highestLevel
    }

    var isOver: Bool { engine.isOver }

    /// Trả về false nếu không món nào di chuyển được về hướng này.
    @discardableResult
    func swipe(_ d: MergeDirection, running: Bool, feedback: (GameFeedbackEvent) -> Void) -> Bool {
        guard running, !engine.isOver else { return false }
        var next = engine
        guard let r = next.move(d) else {
            feedback(GameFeedbackEvent(cue: nil, haptic: .bump))
            return false
        }
        ghosts = r.consumed
        engine = next
        let top = r.topMergeLevel
        let isNewBest = top > bestLevel && top >= 4
        if !r.merges.isEmpty {
            fxID += 1
            fx = MergeFX(id: fxID, merges: r.merges.map { MergeFX.Spot(index: $0.index, level: $0.level) },
                         newBest: isNewBest ? top : nil)
        }
        feedback(GameFeedbackEvent(cue: .whoosh, haptic: nil))
        if r.gameOver {
            say(["Hết đường gộp rồi! Bàn bánh đẹp ghê."], feeling: .cheer)
            if top > 0 { feedback(GameFeedbackEvent(cue: GameCue.merge(level: top), haptic: nil)) }
            feedback(GameFeedbackEvent(cue: .gameOver, haptic: .success))
        } else if isNewBest {
            let name = SweetLadder.name(top)
            say(["Ra \(name) rồi!", "Oa, \(name) nè!"], feeling: .cheer)
            feedback(GameFeedbackEvent(cue: GameCue.merge(level: top), haptic: nil))
            feedback(GameFeedbackEvent(cue: .newBest, haptic: .success))
        } else if top >= 5 || r.merges.count >= 3 {
            say(["Ngon quá!", "Gộp khéo ghê!", "Thơm lừng luôn!"], feeling: .happy)
            feedback(GameFeedbackEvent(cue: GameCue.merge(level: top), haptic: .bump))
        } else if !r.merges.isEmpty {
            feedback(GameFeedbackEvent(cue: GameCue.merge(level: top), haptic: .tap))
            if feeling == .worried && engine.emptyCount > 3 { say(["Thoáng rồi nè."], feeling: .calm) }
        } else {
            if engine.emptyCount <= 2 && feeling != .worried {
                say(["Bàn đầy rồi, tìm hai món giống nhau nha!", "Chật quá, gộp bớt nha!"], feeling: .worried)
            }
        }
        bestLevel = max(bestLevel, engine.highestLevel)
        return true
    }

    private func say(_ lines: [String], feeling: PuzzlePetFeeling) {
        reactionCount += 1
        reaction = lines[reactionCount % lines.count]
        self.feeling = feeling
    }

    func autoplayStep(running: Bool, feedback: (GameFeedbackEvent) -> Void) {
        guard autoplay, running, let d = SweetMergeBot.bestMove(engine) else { return }
        swipe(d, running: running, feedback: feedback)
    }

    /// Mô tả bàn cho VoiceOver, theo từng hàng.
    var accessibilityDescription: String {
        let levels = engine.levels
        return (0..<SweetMergeEngine.size).map { r in
            let cells = (0..<SweetMergeEngine.size).map { c -> String in
                let l = levels[r * SweetMergeEngine.size + c]
                return l == 0 ? "trống" : "\(SweetLadder.name(l)) \(SweetLadder.value(l))"
            }
            return "Hàng \(r + 1): " + cells.joined(separator: ", ")
        }.joined(separator: ". ")
    }
}

/// Hiệu ứng một lượt vuốt Gộp Bánh.
struct MergeFX: Identifiable, Equatable {
    struct Spot: Equatable {
        var index: Int
        var level: Int
    }
    let id: Int
    let merges: [Spot]
    /// Bậc món mới lần đầu xuất hiện trong lượt chơi (từ bánh cupcake trở lên).
    let newBest: Int?

    var topLevel: Int { merges.map(\.level).max() ?? 0 }
    /// Gộp bánh lớn hoặc ra món mới: rung bàn.
    var isBig: Bool { newBest != nil || topLevel >= 7 || merges.count >= 3 }
}

// MARK: Dùng chung

/// Bạn nhỏ cạnh bàn chơi + bong bóng lời nói.
struct PuzzlePetBubble: View {
    let appearance: PetAppearance
    let feeling: PuzzlePetFeeling
    let line: String
    let count: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let height: CGFloat = 80

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.s) {
            PetArt(mood: feeling.mood, appearance: appearance, pose: feeling.pose)
                .frame(width: 76, height: 76)
                .id(count)
                .transition(reduceMotion ? .opacity : .scale(scale: 0.85).combined(with: .opacity))
            Text(line)
                .font(Typography.callout.weight(.semibold))
                .foregroundStyle(Palette.bubbleInk)
                .lineLimit(3)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.s)
                .background(Palette.bubble, in: UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 4, bottomTrailingRadius: 16, topTrailingRadius: 16, style: .continuous))
                .padding(.bottom, 20)
                .accessibilityAddTraits(.updatesFrequently)
            Spacer(minLength: 0)
        }
        .frame(height: Self.height)
        .animation(reduceMotion ? nil : Motion.bouncy, value: count)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }
}

/// Đọc khung của một view theo tọa độ màn hình.
private struct GlobalFrameReader: ViewModifier {
    let onChange: (CGRect) -> Void

    func body(content: Content) -> some View {
        content.background(
            GeometryReader { g in
                Color.clear
                    .onAppear { onChange(g.frame(in: .global)) }
                    .onChange(of: g.frame(in: .global)) { _, frame in onChange(frame) }
            }
        )
    }
}

private extension View {
    func readGlobalFrame(_ onChange: @escaping (CGRect) -> Void) -> some View { modifier(GlobalFrameReader(onChange: onChange)) }
}

private func announce(_ text: String) {
    UIAccessibility.post(notification: .announcement, argument: text)
}

// MARK: Vùng chơi Xếp Khối

struct BlocksPlayArea: View {
    let controller: BlocksController
    let host: PlayHostModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var drag: BlockDrag?
    @State private var boardFrame: CGRect = .zero
    @State private var areaFrame: CGRect = .zero
    @State private var shake: CGFloat = 0

    private struct BlockDrag: Equatable {
        var slot: Int
        var location: CGPoint
        var moved: Bool
    }

    private struct Target {
        var piece: BlockPiece
        var row: Int
        var col: Int
        var valid: Bool
    }

    var body: some View {
        GeometryReader { geo in
            let trayHeight = max(88, min(132, geo.size.width * 0.27))
            let side = max(200, min(geo.size.width - Spacing.l * 2,
                                    geo.size.height - 60 - PuzzlePetBubble.height - trayHeight - Spacing.m * 3 - Spacing.s,
                                    520))
            VStack(spacing: Spacing.m) {
                Spacer().frame(height: 60)
                PuzzlePetBubble(appearance: host.appearance, feeling: controller.feeling, line: controller.reaction, count: controller.reactionCount)
                    .padding(.horizontal, Spacing.l)
                board(side: side)
                    .frame(width: side, height: side)
                    .readGlobalFrame { boardFrame = $0 }
                    .modifier(ShakeEffect(shakes: shake, amplitude: (controller.burst?.lines ?? 1) >= 3 ? 10 : 6))
                Spacer(minLength: 0)
                tray(height: trayHeight, boardCell: side / CGFloat(BlockPuzzleEngine.size), width: min(geo.size.width, 560))
                Spacer().frame(height: Spacing.s)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .readGlobalFrame { areaFrame = $0 }
        .overlay(alignment: .topLeading) { floatingPiece }
        .background(
            LinearGradient(colors: [Palette.lavenderSoft, Palette.background], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .onChange(of: host.session.isRunning) { _, running in if !running { drag = nil } }
        .onChange(of: controller.burst?.id) { _, _ in
            // Combo nhiều đường / chuỗi dài: rung bàn (không rung khi bật Giảm chuyển động).
            guard !reduceMotion, controller.burst?.isBig == true else { return }
            withAnimation(.linear(duration: 0.42)) { shake += 1 }
        }
    }

    // MARK: Bàn

    private func board(side: CGFloat) -> some View {
        let engine = controller.engine
        let t = drag.flatMap { $0.moved ? target(for: $0) : nil }
        var ghost: [BlockCell] = []
        var rows: [Int] = []
        var cols: [Int] = []
        if let t {
            ghost = BlockPuzzleEngine.cells(of: BlockPuzzleEngine.shape(t.piece.shape), row: t.row, col: t.col)
            if t.valid {
                let lines = engine.linesCompleted(shape: t.piece.shape, row: t.row, col: t.col)
                rows = lines.rows
                cols = lines.cols
            }
        }
        let painter = BlockBoardPainter(board: engine.board, ghost: ghost, ghostColor: t?.piece.color ?? 0, ghostValid: t?.valid ?? true,
                                        highlightRows: rows, highlightCols: cols)
        return ZStack {
            Canvas { ctx, size in painter.draw(in: ctx, size: size) }
                .accessibilityHidden(true)
            if let flash = controller.placeFlash, !reduceMotion {
                BlockPlaceFlashView(flash: flash)
                    .id(flash.id)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            if let burst = controller.burst {
                BlockBurstView(burst: burst, reduceMotion: reduceMotion)
                    .id(burst.id)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            if voiceOver { accessibleCells(side: side) }
        }
        .contentShape(Rectangle())
        .onTapGesture { p in
            guard controller.selected != nil else { return }
            let cell = side / CGFloat(BlockPuzzleEngine.size)
            let at = BlockCell(row: Int(p.y / cell), col: Int(p.x / cell))
            _ = withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) { host.placeSelectedBlock(at: at) }
        }
        .accessibilityElement(children: voiceOver ? AccessibilityChildBehavior.contain : .ignore)
        .accessibilityLabel("Bàn Xếp Khối")
        .accessibilityValue("\(engine.filledCount) trên 64 ô có kẹo")
    }

    /// VoiceOver: mỗi ô là một nút, đặt khối đang chọn sao cho ô giữa khối nằm ở đó.
    private func accessibleCells(side: CGFloat) -> some View {
        let cell = side / CGFloat(BlockPuzzleEngine.size)
        let engine = controller.engine
        return VStack(spacing: 0) {
            ForEach(0..<BlockPuzzleEngine.size, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<BlockPuzzleEngine.size, id: \.self) { c in
                        let filled = engine.isFilled(BlockCell(row: r, col: c))
                        Rectangle()
                            .fill(Color.white.opacity(0.001))
                            .frame(width: cell, height: cell)
                            .accessibilityElement()
                            .accessibilityLabel("Hàng \(r + 1), cột \(c + 1), \(filled ? "có kẹo" : "trống")")
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint(controller.selected == nil ? "Chọn một khối trong khay trước." : "Đặt khối đã chọn, ô giữa khối nằm ở đây.")
                            .accessibilityAction {
                                let before = controller.engine.score
                                if host.placeSelectedBlock(at: BlockCell(row: r, col: c)) {
                                    announce("Đã đặt. \(controller.engine.score - before) điểm. \(controller.reaction)")
                                } else {
                                    announce(controller.selected == nil ? "Chưa chọn khối." : "Khối không vừa chỗ này.")
                                }
                            }
                    }
                }
            }
        }
    }

    // MARK: Khay

    private func tray(height: CGFloat, boardCell: CGFloat, width: CGFloat) -> some View {
        let slotWidth = (width - Spacing.l * 2 - Spacing.s * 2) / 3
        let cell = min(boardCell * 0.62, slotWidth / 5.4, (height - Spacing.s * 2) / 5)
        return HStack(spacing: Spacing.s) {
            ForEach(0..<BlockPuzzleEngine.traySize, id: \.self) { slot in
                traySlot(slot, cell: cell)
            }
        }
        .padding(.horizontal, Spacing.l)
        .frame(maxWidth: 560)
        .frame(height: height)
    }

    private func traySlot(_ slot: Int, cell: CGFloat) -> some View {
        let engine = controller.engine
        let piece = engine.tray[slot]
        let fits = piece.map { engine.fits(shape: $0.shape) } ?? false
        let dragging = drag?.slot == slot && drag?.moved == true
        let selected = controller.selected == slot
        return ZStack {
            RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                .fill(selected ? Palette.lavenderSoft : Palette.surface.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                    .strokeBorder(selected ? Palette.lavender : Color.clear, lineWidth: 2))
            if let piece {
                let shape = BlockPuzzleEngine.shape(piece.shape)
                Canvas { ctx, _ in
                    PuzzleArt.piece(ctx, shape: shape, color: piece.color, origin: .zero, cell: cell)
                }
                .frame(width: CGFloat(shape.width) * cell, height: CGFloat(shape.height) * cell)
                .opacity(dragging ? 0.15 : (fits ? 1 : 0.4))
                .saturation(fits ? 1 : 0.3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(PopInOnChange(trigger: controller.refillCount, delay: Double(slot) * 0.07, reduceMotion: reduceMotion))
        .contentShape(Rectangle())
        .gesture(trayGesture(slot))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(trayLabel(piece, fits: fits))
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(piece == nil ? "" : "Chọn khối rồi chọn một ô trên bàn để đặt.")
        .accessibilityAction { host.selectBlock(slot) }
    }

    private func trayLabel(_ piece: BlockPiece?, fits: Bool) -> String {
        guard let piece else { return "Ô khay trống" }
        let s = BlockPuzzleEngine.shape(piece.shape)
        return "Khối \(s.name), \(s.cells.count) ô" + (fits ? "" : ", không còn chỗ vừa")
    }

    private func trayGesture(_ slot: Int) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { v in
                guard host.session.isRunning, controller.engine.tray[slot] != nil else { return }
                let wasMoving = drag?.slot == slot && drag?.moved == true
                let moved = wasMoving || hypot(v.translation.width, v.translation.height) > 8
                if moved && !wasMoving { host.cue(.pickup, haptic: .tap) }
                drag = BlockDrag(slot: slot, location: v.location, moved: moved)
            }
            .onEnded { v in
                defer { drag = nil }
                guard let d = drag, d.slot == slot, host.session.isRunning else { return }
                guard d.moved else {
                    host.selectBlock(slot)
                    return
                }
                guard let t = target(for: BlockDrag(slot: slot, location: v.location, moved: true)) else { return }
                if t.valid {
                    _ = withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) {
                        host.placeBlock(slot: slot, row: t.row, col: t.col)
                    }
                } else {
                    host.rejectBlockDrop()
                }
            }
    }

    // MARK: Kéo thả

    /// Khối nổi lên phía trên ngón tay để không bị che.
    private func lift(_ cell: CGFloat) -> CGFloat { cell * 0.8 + 28 }

    private func topLeft(_ location: CGPoint, shape: BlockShape, cell: CGFloat) -> CGPoint {
        CGPoint(x: location.x - CGFloat(shape.width) * cell / 2, y: location.y - CGFloat(shape.height) * cell - lift(cell))
    }

    /// Chỗ khối sẽ rơi vào (hít vào ô gần nhất). nil khi khối còn ở ngoài bàn.
    private func target(for d: BlockDrag) -> Target? {
        guard boardFrame.width > 0, let piece = controller.engine.tray[d.slot] else { return nil }
        let shape = BlockPuzzleEngine.shape(piece.shape)
        let cell = boardFrame.width / CGFloat(BlockPuzzleEngine.size)
        let tl = topLeft(d.location, shape: shape, cell: cell)
        let col = Int(((tl.x - boardFrame.minX) / cell).rounded())
        let row = Int(((tl.y - boardFrame.minY) / cell).rounded())
        let n = BlockPuzzleEngine.size
        guard row > -shape.height, col > -shape.width, row < n, col < n else { return nil }
        return Target(piece: piece, row: row, col: col, valid: controller.engine.canPlace(shape: piece.shape, row: row, col: col))
    }

    @ViewBuilder
    private var floatingPiece: some View {
        if let d = drag, d.moved, boardFrame.width > 0, let piece = controller.engine.tray[d.slot] {
            let shape = BlockPuzzleEngine.shape(piece.shape)
            let cell = boardFrame.width / CGFloat(BlockPuzzleEngine.size)
            let tl = topLeft(d.location, shape: shape, cell: cell)
            Canvas { ctx, _ in
                PuzzleArt.piece(ctx, shape: shape, color: piece.color, origin: .zero, cell: cell)
            }
            .frame(width: CGFloat(shape.width) * cell, height: CGFloat(shape.height) * cell)
            .scaleEffect(reduceMotion ? 1 : 1.06)
            .shadow(color: Palette.shadow.opacity(0.32), radius: 12, y: 10)
            .offset(x: tl.x - areaFrame.minX, y: tl.y - areaFrame.minY)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// Kẹo vỡ ra khi xóa đường: vệt sáng quét qua hàng/cột, kẹo phồng lên rồi tan, hạt kẹo bắn tung,
/// nhãn điểm bay lên và chữ combo to. Chạy một lần khi xuất hiện (mỗi lần xóa là một view mới).
struct BlockBurstView: View {
    let burst: BlockBurst
    let reduceMotion: Bool
    @State private var progress: CGFloat = 0
    @State private var sweep: CGFloat = 0
    @State private var labelProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let cell = geo.size.width / CGFloat(BlockPuzzleEngine.size)
            let center = burstCenter(cell: cell)
            ZStack(alignment: .topLeading) {
                // Vệt sáng quét dọc theo đường vừa xóa.
                ForEach(burst.rows, id: \.self) { r in
                    sweepBar(length: geo.size.width, thickness: cell, vertical: false)
                        .scaleEffect(x: reduceMotion ? 1 : sweep, y: 1, anchor: .leading)
                        .position(x: geo.size.width / 2, y: (CGFloat(r) + 0.5) * cell)
                }
                ForEach(burst.cols, id: \.self) { c in
                    sweepBar(length: geo.size.height, thickness: cell, vertical: true)
                        .scaleEffect(x: 1, y: reduceMotion ? 1 : sweep, anchor: .top)
                        .position(x: (CGFloat(c) + 0.5) * cell, y: geo.size.height / 2)
                }
                ForEach(Array(burst.cells.enumerated()), id: \.offset) { i, c in
                    let colors = PuzzleArt.candyColor(i < burst.colors.count ? burst.colors[i] : 0)
                    RoundedRectangle(cornerRadius: cell * 0.25, style: .continuous)
                        .fill(colors.1)
                        .overlay(RoundedRectangle(cornerRadius: cell * 0.25, style: .continuous).strokeBorder(colors.0, lineWidth: 2))
                        .frame(width: cell * 0.84, height: cell * 0.84)
                        .scaleEffect(reduceMotion ? 1 : 1 + progress * 0.5)
                        .rotationEffect(.degrees(reduceMotion ? 0 : Double(progress) * (i % 2 == 0 ? 35 : -35)))
                        .opacity(Double(1 - progress))
                        .position(x: (CGFloat(c.col) + 0.5) * cell, y: (CGFloat(c.row) + 0.5) * cell)
                }
                if !reduceMotion {
                    ParticleBurstView(burst: particles(cell: cell), lifetime: burst.isBig ? 1.1 : 0.85)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                Text(burst.label)
                    .font(.system(.title2, design: .rounded).weight(.black))
                    .foregroundStyle(rgb(0x8C5BB5))
                    .padding(.horizontal, Spacing.s)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color.white.opacity(0.9), in: Capsule())
                    .fixedSize()
                    .scaleEffect(reduceMotion ? 1 : 0.6 + min(1, labelProgress * 4) * 0.4)
                    .position(x: center.x, y: center.y - (reduceMotion ? 0 : labelProgress * cell * 1.1))
                    .opacity(Double(labelProgress < 0.7 ? 1 : max(0, (1 - labelProgress) / 0.3)))
                    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                if let callout = burst.callout {
                    BigCallout(title: callout.title, subtitle: callout.subtitle,
                               colors: burst.lines >= 3 ? [rgb(0xFFB347), rgb(0xFF6FA5), rgb(0x9C7BFF)] : [rgb(0xFF8FB1), rgb(0xB38CFF)],
                               reduceMotion: reduceMotion)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.42)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.22)) { sweep = 1 }
            withAnimation(.easeOut(duration: reduceMotion ? 0.2 : 0.45).delay(reduceMotion ? 0 : 0.08)) { progress = 1 }
            withAnimation(.easeOut(duration: 1.1)) { labelProgress = 1 }
        }
    }

    private func sweepBar(length: CGFloat, thickness: CGFloat, vertical: Bool) -> some View {
        RoundedRectangle(cornerRadius: thickness * 0.3, style: .continuous)
            .fill(LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.95), Color.white.opacity(0.3)],
                                 startPoint: vertical ? .top : .leading, endPoint: vertical ? .bottom : .trailing))
            .frame(width: vertical ? thickness * 0.9 : length, height: vertical ? length : thickness * 0.9)
            .opacity(Double(1 - progress))
            .blendMode(.plusLighter)
    }

    private func particles(cell: CGFloat) -> ParticleBurst {
        let origins = burst.cells.map { CGPoint(x: (CGFloat($0.col) + 0.5) * cell, y: (CGFloat($0.row) + 0.5) * cell) }
        let colors = burst.cells.indices.map { i in PuzzleArt.candyColor(i < burst.colors.count ? burst.colors[i] : 0).0 }
        return ParticleBurst(id: burst.id, origins: origins, colors: colors + [Color.white],
                             perOrigin: burst.isBig ? 4 : 3, power: burst.isBig ? 1.25 : 0.9, size: max(5, cell * 0.2))
    }

    private func burstCenter(cell: CGFloat) -> CGPoint {
        guard !burst.cells.isEmpty else { return CGPoint(x: cell * 4, y: cell * 4) }
        let x = burst.cells.reduce(0) { $0 + CGFloat($1.col) } / CGFloat(burst.cells.count)
        let y = burst.cells.reduce(0) { $0 + CGFloat($1.row) } / CGFloat(burst.cells.count)
        return CGPoint(x: (x + 0.5) * cell, y: (y + 0.5) * cell)
    }
}

/// Ô vừa đặt lóe sáng trắng rồi tắt: cảm giác khối "dính" xuống bàn.
struct BlockPlaceFlashView: View {
    let flash: BlockPlaceFlash
    @State private var t: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let cell = geo.size.width / CGFloat(BlockPuzzleEngine.size)
            ForEach(Array(flash.cells.enumerated()), id: \.offset) { _, c in
                RoundedRectangle(cornerRadius: cell * 0.24, style: .continuous)
                    .fill(Color.white.opacity(0.75))
                    .frame(width: cell * 0.86, height: cell * 0.86)
                    .scaleEffect(1.18 - t * 0.18)
                    .opacity(Double(1 - t))
                    .position(x: (CGFloat(c.col) + 0.5) * cell, y: (CGFloat(c.row) + 0.5) * cell)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.28)) { t = 1 } }
    }
}

// MARK: Vùng chơi Gộp Bánh

struct MergePlayArea: View {
    let controller: MergeController
    let host: PlayHostModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var shake: CGFloat = 0

    private static let padHeight: CGFloat = 52

    private struct MergeItem: Identifiable {
        let tile: SweetTile
        let ghost: Bool
        var id: Int { tile.id }
    }

    var body: some View {
        GeometryReader { geo in
            let side = max(200, min(geo.size.width - Spacing.l * 2,
                                    geo.size.height - 60 - PuzzlePetBubble.height - Self.padHeight - Spacing.m * 4,
                                    480))
            VStack(spacing: Spacing.m) {
                Spacer().frame(height: 60)
                PuzzlePetBubble(appearance: host.appearance, feeling: controller.feeling, line: controller.reaction, count: controller.reactionCount)
                    .padding(.horizontal, Spacing.l)
                board(side: side)
                    .frame(width: side, height: side)
                    .modifier(ShakeEffect(shakes: shake, amplitude: 6))
                Spacer(minLength: 0)
                directionPad
                Spacer().frame(height: Spacing.s)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(
            LinearGradient(colors: [rgb(0xFDE6EE), Palette.background], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .onChange(of: controller.fx?.id) { _, _ in
            guard !reduceMotion, controller.fx?.isBig == true else { return }
            withAnimation(.linear(duration: 0.4)) { shake += 1 }
        }
    }

    private func board(side: CGFloat) -> some View {
        let cell = side / CGFloat(SweetMergeEngine.size)
        // Một ForEach chung cho món đang có và món vừa bị gộp: cùng id thì SwiftUI cho trượt mượt tới ô gộp.
        let items = controller.ghosts.map { MergeItem(tile: $0, ghost: true) } + controller.engine.tiles.map { MergeItem(tile: $0, ghost: false) }
        let pop: AnyTransition = AnyTransition.scale(scale: 0.3).combined(with: .opacity).animation(.easeOut(duration: 0.14).delay(0.08))
        let insertion: AnyTransition = reduceMotion ? AnyTransition.opacity : pop
        return ZStack(alignment: .topLeading) {
            Canvas { ctx, size in PuzzleArt.mergeBoard(ctx, size: size) }
            ForEach(items) { item in
                let rect = PuzzleArt.tileRect(item.tile.index, cell: cell)
                SweetTileView(level: item.tile.level, merges: item.tile.merges, reduceMotion: reduceMotion)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .zIndex(item.ghost ? 0 : 1)
                    .transition(.asymmetric(insertion: insertion, removal: .identity))
            }
            if let fx = controller.fx, !reduceMotion {
                MergeFXView(fx: fx, cell: cell)
                    .id(fx.id)
                    .frame(width: side, height: side)
                    .zIndex(2)
            }
        }
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 18).onEnded { v in
            let dx = v.translation.width, dy = v.translation.height
            guard max(abs(dx), abs(dy)) > 24 else { return }
            perform(abs(dx) > abs(dy) ? (dx > 0 ? .right : .left) : (dy > 0 ? .down : .up))
        })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Bàn Gộp Bánh")
        .accessibilityValue(controller.accessibilityDescription)
        .accessibilityHint("Dùng các nút mũi tên bên dưới, hoặc vuốt lên xuống để chọn thao tác gộp.")
        .accessibilityAction(named: Text(MergeDirection.up.label)) { perform(.up) }
        .accessibilityAction(named: Text(MergeDirection.down.label)) { perform(.down) }
        .accessibilityAction(named: Text(MergeDirection.left.label)) { perform(.left) }
        .accessibilityAction(named: Text(MergeDirection.right.label)) { perform(.right) }
    }

    private var directionPad: some View {
        HStack(spacing: Spacing.m) {
            padButton(.left, "arrow.left")
            padButton(.up, "arrow.up")
            padButton(.down, "arrow.down")
            padButton(.right, "arrow.right")
        }
        .frame(height: Self.padHeight)
    }

    private func padButton(_ d: MergeDirection, _ icon: String) -> some View {
        Button {
            perform(d)
        } label: {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(Palette.ink)
                .frame(width: 60, height: Self.padHeight)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!host.session.isRunning)
        .accessibilityLabel(d.label)
    }

    private func perform(_ d: MergeDirection) {
        let before = controller.engine.score
        let moved = withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) { host.swipe(d) }
        guard voiceOver else { return }
        if moved {
            let gained = controller.engine.score - before
            announce(gained > 0 ? "Gộp được \(gained) điểm. \(controller.reaction)" : "Đã dồn bánh.")
        } else {
            announce("Không món nào di chuyển được về phía này.")
        }
    }
}

/// Một món trên bàn Gộp Bánh: nảy nhẹ khi vừa gộp (không nảy khi bật Giảm chuyển động).
struct SweetTileView: View {
    let level: Int
    let merges: Int
    let reduceMotion: Bool

    var body: some View {
        Canvas { ctx, size in
            PuzzleArt.sweetTile(ctx, level: level, rect: CGRect(origin: .zero, size: size))
        }
        .phaseAnimator([1.0, 1.24, 0.96, 1.0], trigger: merges) { content, scale in
            content.scaleEffect(reduceMotion ? 1 : scale)
        } animation: { phase in
            phase == 1.24 ? .easeOut(duration: 0.08) : .spring(response: 0.18, dampingFraction: 0.6)
        }
        .accessibilityHidden(true)
    }
}

/// Hiệu ứng một lượt gộp: vòng sáng nở ra ở ô gộp, hạt bánh bắn tung, chữ "Món mới" khi ra bậc chưa từng có.
struct MergeFXView: View {
    let fx: MergeFX
    let cell: CGFloat
    @State private var ring: CGFloat = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(fx.merges.enumerated()), id: \.offset) { _, m in
                let rect = PuzzleArt.tileRect(m.index, cell: cell)
                Circle()
                    .strokeBorder(Color.white.opacity(0.9), lineWidth: 3 + CGFloat(min(m.level, 8)) * 0.4)
                    .frame(width: rect.width, height: rect.width)
                    .scaleEffect(0.6 + ring * (0.7 + CGFloat(min(m.level, 10)) * 0.04))
                    .opacity(Double(1 - ring))
                    .position(x: rect.midX, y: rect.midY)
            }
            ParticleBurstView(burst: particles, lifetime: fx.isBig ? 1.0 : 0.7)
            if let level = fx.newBest {
                VStack(spacing: Spacing.xs) {
                    Canvas { ctx, size in
                        PuzzleArt.sweetTile(ctx, level: level, rect: CGRect(origin: .zero, size: size), showValue: false)
                    }
                    .frame(width: 76, height: 76)
                    BigCallout(title: "Món mới!", subtitle: SweetLadder.name(level).capitalizedFirst,
                               colors: [rgb(0xFFB347), rgb(0xFF6FA5)], reduceMotion: false)
                }
                .modifier(NewSweetPop())
                .position(x: cell * 2, y: cell * 1.6)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { withAnimation(.easeOut(duration: 0.4)) { ring = 1 } }
    }

    private var particles: ParticleBurst {
        let origins = fx.merges.map { m -> CGPoint in
            let r = PuzzleArt.tileRect(m.index, cell: cell)
            return CGPoint(x: r.midX, y: r.midY)
        }
        let colors = fx.merges.map { PuzzleArt.tileBackground($0.level) } + [rgb(0xFFD36E), Color.white]
        let top = fx.topLevel
        return ParticleBurst(id: fx.id, origins: fx.newBest != nil ? origins + origins : origins, colors: colors,
                             perOrigin: min(9, 3 + top / 2), power: fx.isBig ? 1.3 : 0.8, size: max(5, cell * 0.09))
    }
}

/// Hình món mới nảy ra rồi mờ đi sau khoảng 1,3 giây.
private struct NewSweetPop: ViewModifier {
    @State private var scale: CGFloat = 0.2
    @State private var opacity: Double = 1

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { scale = 1 }
                withAnimation(.easeIn(duration: 0.4).delay(1.2)) { opacity = 0 }
            }
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
