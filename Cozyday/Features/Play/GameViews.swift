import SwiftUI

/// Màn chơi toàn màn hình: vùng chơi + thanh trạng thái + lớp phủ (hướng dẫn, đếm ngược, tạm dừng, kết quả).
struct GameHostView: View {
    let host: PlayHostModel
    var onReplay: () -> Void
    var onExit: () -> Void

    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.displayScale) private var displayScale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Các game đã xem hướng dẫn (lần sau vào chơi ngay).
    @AppStorage("playground.tutorialsSeen") private var tutorialsSeen = ""
    @State private var showTutorial = false
    @State private var confirmExit = false

    var body: some View {
        ZStack {
            GeometryReader { geo in
                ZStack {
                    Palette.background
                    playArea(size: geo.size)
                }
                .onAppear { prepare(size: geo.size) }
                .onChange(of: geo.size) { _, size in
                    // Lần đầu có thể chưa có kích thước thật: chuẩn bị lại khi đã có.
                    if !host.isConfigured { prepare(size: size) }
                }
            }
            // Game hành động vẽ tràn màn hình; Lật thẻ nằm trong vùng an toàn.
            .ignoresSafeArea(.container, edges: host.kind == .memoryMatch ? [] : .all)

            VStack(spacing: 0) {
                hud
                Spacer()
            }

            overlay
        }
        .background(Palette.background.ignoresSafeArea())
        .onChange(of: scenePhase) { _, phase in
            // Vào nền, khóa máy, cuộc gọi, Trung tâm điều khiển: tự tạm dừng. Quay lại không tự chạy.
            if phase != .active { host.pause() }
        }
        .onDisappear { host.teardown() }
        .confirmationDialog("Thoát lượt này?", isPresented: $confirmExit, titleVisibility: .visible) {
            Button("Thoát, không tính lượt này", role: .destructive) {
                host.abandon()
                onExit()
            }
            Button("Chơi tiếp", role: .cancel) {}
        } message: {
            Text("Lượt đang chơi sẽ không được lưu và không có xu. Xu bạn đã có không bị ảnh hưởng.")
        }
    }

    private func prepare(size: CGSize) {
        host.configure(size: size, scale: displayScale)
        guard host.isConfigured, host.session.phase == .ready, !showTutorial else { return }
        if tutorialsSeen.split(separator: ",").contains(Substring(host.kind.rawValue)) && PreviewMode.current != .tutorial {
            host.begin()
        } else {
            showTutorial = true
        }
    }

    // MARK: Vùng chơi

    @ViewBuilder
    private func playArea(size: CGSize) -> some View {
        switch host.kind {
        case .cloudJump:
            if let jump = host.jump { JumpPlayArea(controller: jump, sprites: host.sprites, running: host.session.isRunning, reduceMotion: reduceMotion) }
        case .giftBasket:
            if let basket = host.basket { BasketPlayArea(controller: basket, sprites: host.sprites, running: host.session.isRunning, reduceMotion: reduceMotion) }
        case .memoryMatch:
            if let memory = host.memory { MemoryPlayArea(controller: memory, host: host) }
        }
    }

    // MARK: Thanh trạng thái

    private var hud: some View {
        HStack(spacing: Spacing.s) {
            Button {
                if host.session.phase.isOver || host.session.phase == .ready {
                    onExit()
                } else {
                    host.pause()
                }
            } label: {
                Image(systemName: host.session.phase == .ready ? "xmark" : "pause.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 52, height: 52)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel(host.session.phase == .ready ? "Đóng" : "Tạm dừng")
            .opacity(host.session.phase.isOver ? 0 : 1)
            Spacer()
            Group {
                if host.kind == .memoryMatch {
                    // Lật thẻ không vẽ theo khung hình: đồng hồ cập nhật mỗi nửa giây.
                    TimelineView(.periodic(from: .now, by: 0.5)) { _ in statsRow }
                } else {
                    statsRow
                }
            }
            .padding(.horizontal, Spacing.m)
            .frame(minHeight: 44)
            .background(.ultraThinMaterial, in: Capsule())
            .accessibilityElement(children: .combine)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.top, Spacing.xs)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private var statsRow: some View {
        HStack(spacing: Spacing.m) {
            ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                Label(stat.1, systemImage: stat.0)
                    .font(Typography.headline.monospacedDigit())
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
            }
        }
    }

    private var stats: [(String, String)] {
        switch host.kind {
        case .cloudJump:
            let e = host.jump?.engine
            return [("arrow.up", "\(e?.heightMeters ?? 0) m"), ("star.fill", "\(e?.starsCollected ?? 0)")]
        case .giftBasket:
            let e = host.basket?.engine
            var list = [("timer", "\(Int((e?.remaining ?? 60).rounded(.up)))s"), ("gift.fill", "\(e?.score ?? 0)")]
            if let combo = e?.combo, combo >= 3 { list.append(("flame.fill", "×\(GiftBasketEngine.multiplier(combo: combo))")) }
            return list
        case .memoryMatch:
            return [("hand.tap.fill", "\(host.memory?.board.moves ?? 0) lượt"), ("timer", MemoryTimeText.text(host))]
        }
    }

    // MARK: Lớp phủ

    @ViewBuilder
    private var overlay: some View {
        switch host.session.phase {
        case .ready:
            if showTutorial {
                TutorialCard(kind: host.kind, appearance: host.appearance) {
                    var seen = Set(tutorialsSeen.split(separator: ",").map(String.init))
                    seen.insert(host.kind.rawValue)
                    tutorialsSeen = seen.sorted().joined(separator: ",")
                    showTutorial = false
                    host.begin()
                }
            }
        case .countdown:
            if let n = host.session.countdownRemaining(at: host.now) {
                Text("\(n)")
                    .font(.system(size: 96, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.lavender)
                    .shadow(color: .white, radius: 6)
                    .id(n)
                    .transition(reduceMotion ? .opacity : .scale(scale: 1.6).combined(with: .opacity))
                    .accessibilityLabel("Bắt đầu sau \(n)")
                    .allowsHitTesting(false)
            }
        case .paused:
            PauseCard(onResume: { host.resume() }, onExit: { confirmExit = true })
        case .finished:
            GameResultCard(host: host, onReplay: onReplay, onExit: onExit)
        case .playing, .abandoned:
            EmptyView()
        }
    }
}

enum MemoryTimeText {
    @MainActor
    static func text(_ host: PlayHostModel) -> String {
        let s = Int(host.activeSeconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

// MARK: Vùng chơi hành động

struct JumpPlayArea: View {
    let controller: JumpController
    let sprites: [PetSpriteKind: Image]
    let running: Bool
    let reduceMotion: Bool

    var body: some View {
        let painter = CloudJumpPainter(engine: controller.engine, effects: controller.effects, now: controller.engine.time,
                                       lastBounceAt: controller.lastBounceAt, lastHitAt: controller.lastHitAt, reduceMotion: reduceMotion)
        Canvas { ctx, size in
            painter.draw(in: ctx, size: size, pet: spriteDrawer(sprites))
        }
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { if running { controller.drag(toX: $0.location.x) } }
            .onEnded { _ in controller.endDrag() })
        .accessibilityElement()
        .accessibilityLabel("Vùng chơi Nhảy Mây")
        .accessibilityValue("Độ cao \(controller.engine.heightMeters) mét")
        .accessibilityHint("Kéo ngang để sang trái phải. Với VoiceOver: vuốt lên để sang phải, vuốt xuống để sang trái.")
        .accessibilityAdjustableAction { direction in
            controller.nudge(direction == .increment ? 15 : -15)
        }
    }
}

struct BasketPlayArea: View {
    let controller: BasketController
    let sprites: [PetSpriteKind: Image]
    let running: Bool
    let reduceMotion: Bool

    var body: some View {
        let painter = GiftBasketPainter(engine: controller.engine, effects: controller.effects, now: controller.engine.time,
                                        mood: controller.mood, reduceMotion: reduceMotion)
        Canvas { ctx, size in
            painter.draw(in: ctx, size: size, pet: spriteDrawer(sprites))
        }
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { if running { controller.drag(toX: $0.location.x) } }
            .onEnded { _ in controller.endDrag() })
        .accessibilityElement()
        .accessibilityLabel("Vùng chơi Giỏ Quà")
        .accessibilityValue("\(controller.engine.score) điểm, còn \(Int(controller.engine.remaining)) giây")
        .accessibilityHint("Kéo ngang để di chuyển giỏ. Với VoiceOver: vuốt lên để sang phải, vuốt xuống để sang trái.")
        .accessibilityAdjustableAction { direction in
            controller.nudge(direction == .increment ? 15 : -15)
        }
    }
}

// MARK: Lật thẻ

struct MemoryPlayArea: View {
    let controller: MemoryController
    let host: PlayHostModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let board = controller.board
        let level = board.level
        VStack(spacing: Spacing.m) {
            Spacer().frame(height: 60)
            HStack(alignment: .bottom, spacing: Spacing.s) {
                PetArt(mood: controller.mood.mood, appearance: host.appearance, pose: controller.mood.pose)
                    .frame(width: 84, height: 84)
                    .id(controller.reactionCount)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                Text(controller.reaction)
                    .font(Typography.callout.weight(.semibold))
                    .foregroundStyle(Palette.bubbleInk)
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.s)
                    .background(Palette.bubble, in: UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 4, bottomTrailingRadius: 16, topTrailingRadius: 16, style: .continuous))
                    .padding(.bottom, 24)
                    .accessibilityAddTraits(.updatesFrequently)
                Spacer(minLength: 0)
            }
            .animation(reduceMotion ? nil : Motion.bouncy, value: controller.reactionCount)
            .padding(.horizontal, Spacing.l)

            GeometryReader { geo in
                // Cỡ thẻ vừa cả chiều ngang lẫn chiều dọc (màn nhỏ vẫn thấy đủ bàn, không phải cuộn).
                let gap = Spacing.s
                let cols = CGFloat(level.columns), rows = CGFloat(level.rows)
                let byWidth = (min(geo.size.width, 520) - Spacing.l * 2 - gap * (cols - 1)) / cols
                let byHeight = (geo.size.height - gap * (rows - 1)) / rows * 0.8
                let w = max(40, min(byWidth, byHeight))
                VStack(spacing: gap) {
                    ForEach(0..<level.rows, id: \.self) { r in
                        HStack(spacing: gap) {
                            ForEach(0..<level.columns, id: \.self) { c in
                                let index = r * level.columns + c
                                if index < board.cards.count {
                                    let card = board.cards[index]
                                    MemoryCardView(card: card, faceUp: card.state != .down, matched: card.state == .matched,
                                                   index: card.id, columns: level.columns)
                                        .frame(width: w, height: w / 0.8)
                                        .contentShape(Rectangle())
                                        .onTapGesture { host.flip(card.id) }
                                        .accessibilityAddTraits(.isButton)
                                        .accessibilityAction { host.flip(card.id) }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Spacer().frame(height: Spacing.m)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [Palette.lavenderSoft, Palette.background], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
}

struct MemoryCardView: View {
    let card: MemoryCard
    let faceUp: Bool
    let matched: Bool
    let index: Int
    let columns: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let species = MemoryBoard.faces[card.face % MemoryBoard.faces.count]
        ZStack {
            if faceUp {
                RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                    .fill(matched ? Palette.sageSoft : Palette.surface)
                    .overlay(RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                        .strokeBorder(matched ? Palette.sage : Palette.lavender, lineWidth: 2))
                PetArt(mood: matched ? .happy : .idle, appearance: species.introLook.appearance(stage: .grown))
                    .padding(6)
                if matched {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Palette.sage)
                        .font(.caption.weight(.bold))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(5)
                }
            } else {
                Canvas { ctx, size in GameArt.cardBack(ctx, size: size) }
            }
        }
        .rotation3DEffect(.degrees(reduceMotion ? 0 : (faceUp ? 0 : 180)), axis: (x: 0, y: 1, z: 0))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: faceUp)
        .shadow(color: Palette.shadow.opacity(0.12), radius: 4, y: 2)
        .accessibilityElement(children: .ignore)
        // Thẻ úp không đọc lộ hình; thẻ mở đọc được tên bạn nhỏ.
        .accessibilityLabel(faceUp ? "\(species.name.capitalized)\(matched ? ", đã ghép" : ", đang mở")"
                                   : "Thẻ úp, hàng \(index / columns + 1), cột \(index % columns + 1)")
    }
}

// MARK: Hướng dẫn, tạm dừng

struct TutorialCard: View {
    let kind: MinigameKind
    let appearance: PetAppearance
    let onStart: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            ScrollView {
                VStack(spacing: Spacing.m) {
                    GameThumbnail(kind: kind, appearance: appearance)
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
                    Text(kind.name).font(Typography.title).foregroundStyle(Palette.ink)
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        ForEach(Array(kind.howTo.enumerated()), id: \.offset) { i, line in
                            HStack(alignment: .top, spacing: Spacing.s) {
                                Text("\(i + 1)")
                                    .font(Typography.callout.weight(.heavy))
                                    .foregroundStyle(Palette.onAccent)
                                    .frame(width: 26, height: 26)
                                    .background(Palette.lavender, in: Circle())
                                    .accessibilityHidden(true)
                                Text(line).font(Typography.body).foregroundStyle(Palette.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    if kind != .memoryMatch {
                        Text("Có thể tạm dừng bất cứ lúc nào. Vào nền hay khóa máy cũng tự tạm dừng.")
                            .font(Typography.caption).foregroundStyle(Palette.inkMuted)
                            .multilineTextAlignment(.center)
                    }
                    Button(action: onStart) {
                        Label("Bắt đầu", systemImage: "play.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(Spacing.xl)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
                .padding(Spacing.l)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

struct PauseCard: View {
    let onResume: () -> Void
    let onExit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: Spacing.m) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Palette.lavender)
                    .accessibilityHidden(true)
                Text("Tạm dừng").font(Typography.title).foregroundStyle(Palette.ink)
                Text("Thời gian đang đứng yên. Bấm Tiếp tục để đếm ngược 3 giây rồi chơi tiếp.")
                    .font(Typography.callout).foregroundStyle(Palette.inkMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: onResume) { Label("Tiếp tục", systemImage: "play.fill") }
                    .buttonStyle(PrimaryButtonStyle())
                Button(action: onExit) { Text("Thoát lượt này") }
                    .buttonStyle(SoftButtonStyle(tint: Palette.inkMuted))
            }
            .padding(Spacing.xl)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
            .padding(Spacing.xl)
            .frame(maxWidth: 480)
        }
    }
}

// MARK: Kết quả

struct GameResultCard: View {
    let host: PlayHostModel
    var onReplay: () -> Void
    var onExit: () -> Void
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            ScrollView {
                VStack(spacing: Spacing.m) {
                    PetView(appearance: host.appearance, mood: .happy, name: host.petName,
                            bounceTrigger: host.saved == nil ? 0 : 1)
                        .frame(width: 110, height: 110)
                    Text(title).font(Typography.title).foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                    if host.saved?.isNewBest == true {
                        Label("Kỷ lục mới!", systemImage: "trophy.fill")
                            .font(Typography.headline)
                            .foregroundStyle(Palette.honey)
                            .padding(.horizontal, Spacing.m)
                            .padding(.vertical, Spacing.xs)
                            .background(Palette.honey.opacity(0.15), in: Capsule())
                    }
                    metrics
                    reward
                    HStack(spacing: Spacing.s) {
                        Button(action: onExit) { Text("Về Sân chơi") }
                            .buttonStyle(SoftButtonStyle())
                        Button(action: onReplay) { Label("Chơi lại", systemImage: "arrow.clockwise") }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                    .disabled(host.saved == nil && host.saveError == nil)
                }
                .padding(Spacing.xl)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
                .padding(Spacing.l)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
                .scaleEffect(shown || reduceMotion ? 1 : 0.85)
                .opacity(shown || reduceMotion ? 1 : 0)
                .padding(.top, 60)
            }
        }
        .onAppear { withAnimation(reduceMotion ? nil : Motion.bouncy) { shown = true } }
    }

    private var title: String {
        switch host.kind {
        case .cloudJump: return "\(host.petName) đã leo tới \(host.outcome?.primary ?? 0) m!"
        case .giftBasket: return "Hết giờ! Giỏ đầy quà rồi"
        case .memoryMatch: return "Ghép xong cả bàn!"
        }
    }

    private var metrics: some View {
        let o = host.outcome
        let rows: [(String, String)]
        switch host.kind {
        case .cloudJump:
            rows = [("Độ cao", "\(o?.primary ?? 0) m"), ("Sao nhặt được", "\(o?.secondary ?? 0)"), ("Điểm", "\(o?.score ?? 0)")]
        case .giftBasket:
            rows = [("Điểm", "\(o?.score ?? 0)"), ("Món hứng được", "\(o?.primary ?? 0)"), ("Combo dài nhất", "\(o?.secondary ?? 0)")]
        case .memoryMatch:
            let s = Int(o?.activeSeconds ?? 0)
            rows = [("Lượt lật", "\(o?.primary ?? 0)"), ("Thời gian", String(format: "%d:%02d", s / 60, s % 60)), ("Điểm", "\(o?.score ?? 0)")]
        }
        let best = store.bestResult(host.kind)
        return VStack(spacing: Spacing.xs) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack {
                    Text(row.0).foregroundStyle(Palette.inkMuted)
                    Spacer()
                    Text(row.1).font(Typography.headline.monospacedDigit()).foregroundStyle(Palette.ink)
                }
                .font(Typography.callout)
                .accessibilityElement(children: .combine)
            }
            if let best, host.saved?.isNewBest != true {
                HStack {
                    Text("Kỷ lục").foregroundStyle(Palette.inkMuted)
                    Spacer()
                    Text("\(best.score) điểm").font(Typography.callout.weight(.semibold).monospacedDigit()).foregroundStyle(Palette.inkMuted)
                }
                .font(Typography.callout)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(Spacing.m)
        .background(Palette.surfaceMuted, in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
    }

    @ViewBuilder
    private var reward: some View {
        if let saved = host.saved {
            let record = saved.record
            if record.coins > 0 {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "circle.hexagongrid.fill").foregroundStyle(Palette.honey)
                    Text("+\(record.coins) xu").font(.system(.title, design: .rounded).weight(.heavy)).foregroundStyle(Palette.ink)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Nhận \(record.coins) xu")
            }
            if !record.note.message.isEmpty {
                Text(record.note.message)
                    .font(Typography.callout.weight(.semibold))
                    .foregroundStyle(record.coins > 0 ? Palette.inkMuted : Palette.lavender)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("Xu sân chơi hôm nay: \(store.minigameCoins(on: record.day))/\(MinigameConfig.dailyCoinCap)")
                .font(Typography.caption).foregroundStyle(Palette.inkMuted)
        } else if let error = host.saveError {
            VStack(spacing: Spacing.s) {
                Label("Chưa lưu được kết quả", systemImage: "exclamationmark.triangle.fill")
                    .font(Typography.headline).foregroundStyle(Palette.danger)
                Text(error).font(Typography.caption).foregroundStyle(Palette.inkMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Thử lưu lại") { host.save() }
                    .buttonStyle(PrimaryButtonStyle(color: Palette.sage))
                    .accessibilityHint("Lưu lại đúng lượt này, không bị tính hai lần")
            }
        } else {
            ProgressView("Đang lưu…")
        }
    }
}

// MARK: Hình minh họa thẻ game

/// Cảnh nhỏ minh họa từng game (dùng ở Sân chơi và màn hướng dẫn) — vẽ tĩnh, có chính thú cưng của bạn.
struct GameThumbnail: View {
    let kind: MinigameKind
    let appearance: PetAppearance

    var body: some View {
        Canvas { ctx, size in
            let k = size.width / 100
            switch kind {
            case .cloudJump:
                GameArt.sky(ctx, size: size, altitude: 600, reduceMotion: true)
                GameArt.cloud(ctx, rect: CGRect(x: 8 * k, y: size.height * 0.78, width: 30 * k, height: 7 * k), moving: false)
                GameArt.cloud(ctx, rect: CGRect(x: 58 * k, y: size.height * 0.5, width: 28 * k, height: 7 * k), moving: true)
                GameArt.cloud(ctx, rect: CGRect(x: 20 * k, y: size.height * 0.2, width: 26 * k, height: 7 * k), moving: false)
                GameArt.star(ctx, center: CGPoint(x: 78 * k, y: size.height * 0.22), radius: 5 * k)
                draw(ctx, CGRect(x: 40 * k, y: size.height * 0.62 - 24 * k, width: 24 * k, height: 24 * k), kind: .happy)
            case .giftBasket:
                GameArt.garden(ctx, size: size, groundY: size.height * 0.86)
                GameArt.drop(ctx, kind: .apple, center: CGPoint(x: 22 * k, y: size.height * 0.25), radius: 4.5 * k)
                GameArt.drop(ctx, kind: .gift, center: CGPoint(x: 72 * k, y: size.height * 0.18), radius: 5 * k)
                GameArt.drop(ctx, kind: .rain, center: CGPoint(x: 84 * k, y: size.height * 0.48), radius: 4.5 * k)
                GameArt.drop(ctx, kind: .star, center: CGPoint(x: 38 * k, y: size.height * 0.45), radius: 4.5 * k)
                let w = 26 * k
                draw(ctx, CGRect(x: 50 * k - w / 2, y: size.height * 0.95 - w, width: w, height: w), kind: .happy)
                GameArt.basket(ctx, rect: CGRect(x: 50 * k - 11 * k, y: size.height * 0.95 - w * 0.45, width: 22 * k, height: 8 * k), handle: false)
            case .memoryMatch:
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Palette.lavenderSoft))
                let cw = 17 * k, ch = 21 * k
                for i in 0..<4 {
                    var c = ctx
                    c.translateBy(x: 10 * k + CGFloat(i) * 20 * k, y: size.height / 2 - ch / 2)
                    if i == 1 || i == 2 {
                        c.fill(Path(roundedRect: CGRect(x: 0, y: 0, width: cw, height: ch), cornerRadius: 4 * k), with: .color(.white))
                        var p = c
                        p.translateBy(x: 1 * k, y: 3 * k)
                        p.scaleBy(x: cw * 0.9 / 100, y: cw * 0.9 / 100)
                        PetPainter(mood: .happy, appearance: PetSpecies.duck.introLook.appearance(stage: .grown), pose: PetPose()).draw(in: p)
                    } else {
                        GameArt.cardBack(c, size: CGSize(width: cw, height: ch))
                    }
                }
                draw(ctx, CGRect(x: 78 * k, y: size.height - 24 * k, width: 22 * k, height: 22 * k), kind: .cheer)
            }
        }
        .accessibilityHidden(true)
    }

    private func draw(_ ctx: GraphicsContext, _ rect: CGRect, kind: PetSpriteKind) {
        var c = ctx
        c.translateBy(x: rect.minX, y: rect.minY)
        c.scaleBy(x: rect.width / 100, y: rect.height / 100)
        PetPainter(mood: kind.mood, appearance: appearance, pose: kind.pose).draw(in: c)
    }
}
