import SwiftUI

/// Hình một món ăn (vẽ bằng code).
struct FoodArtView: View {
    let foodID: String

    var body: some View {
        Canvas { context, size in
            var ctx = context
            let k = min(size.width, size.height) / 100
            ctx.translateBy(x: (size.width - 100 * k) / 2, y: (size.height - 100 * k) / 2)
            ctx.scaleBy(x: k, y: k)
            FoodArt.draw(foodID, in: ctx)
        }
        .accessibilityHidden(true)
    }
}

extension NeedLevel {
    var color: Color {
        switch self {
        case .needsCare: return Palette.peach
        case .normal: return Palette.honey
        case .good: return Palette.sage
        }
    }
}

/// Một dòng nhu cầu: biểu tượng + nhãn + thanh + số và chữ mức (không chỉ dùng màu).
struct NeedRow: View {
    let kind: NeedKind
    let value: Double

    var body: some View {
        let level = NeedLevel(value)
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.s) {
                Image(systemName: kind.symbol)
                    .foregroundStyle(level.color)
                    .frame(width: 22)
                Text(kind.label)
                    .font(Typography.callout.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: Spacing.s)
                Text("\(Int(value.rounded())) · \(level.label)")
                    .font(Typography.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(level == .needsCare ? Palette.danger : Palette.inkMuted)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.surfaceMuted)
                    Capsule().fill(level.color).frame(width: max(8, geo.size.width * value / 100))
                }
            }
            .frame(height: 9)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(kind.label)
        .accessibilityValue("\(Int(value.rounded())) trên 100, \(level.label)")
    }
}

/// Thẻ chăm sóc trong Góc nhỏ: ba nhu cầu, một câu nói về nhu cầu nổi bật nhất, ba nút chăm.
struct NeedsCard: View {
    @Environment(AppStore.self) private var store
    var cuddleFraction: Double = 0
    var onFeed: () -> Void
    var onClean: () -> Void
    var onCuddle: () -> Void

    var body: some View {
        // Chỉ số đổi rất chậm: vẽ lại mỗi phút là đủ.
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            content(store.currentNeeds)
        }
    }

    private func content(_ needs: PetNeeds) -> some View {
        let name = store.profile.displayPetName
        let urgent = needs.mostUrgent
        let seed = store.today.day * 24 + store.calendar.component(.hour, from: store.now)
        let totals = store.careTotalsToday
        return CozyCard {
            VStack(alignment: .leading, spacing: Spacing.m) {
                HStack(alignment: .center, spacing: Spacing.s) {
                    PetArt(mood: urgent == nil ? .happy : .low, appearance: store.petAppearance)
                        .frame(width: 46, height: 46)
                    Text(CareDialogue.line(for: urgent, petName: name, seed: seed))
                        .font(Typography.callout.weight(.semibold))
                        .foregroundStyle(Palette.bubbleInk)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, Spacing.s)
                        .background(Palette.bubble, in: UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 16, bottomTrailingRadius: 16, topTrailingRadius: 16, style: .continuous))
                }
                .accessibilityElement(children: .combine)

                ForEach(NeedKind.allCases) { kind in
                    NeedRow(kind: kind, value: needs[kind])
                }

                if cuddleFraction > 0 && cuddleFraction < 1 {
                    HStack(spacing: Spacing.s) {
                        Image(systemName: "hand.raised.fingers.spread").foregroundStyle(Palette.peach)
                        ProgressView(value: cuddleFraction).tint(Palette.peach)
                        Text("Đang nựng…").font(Typography.caption.weight(.bold)).foregroundStyle(Palette.inkMuted)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Đang nựng, \(Int(cuddleFraction * 100)) phần trăm")
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.s) { buttons(needs) }
                    VStack(spacing: Spacing.s) { buttons(needs) }
                }

                Text("Thưởng chăm sóc hôm nay: \(totals.xp)/\(CareConfig.dailyXPCap) XP · \(totals.coins)/\(CareConfig.dailyCoinCap) xu. Chỉ có thưởng khi \(name) thật sự cần chăm.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func buttons(_ needs: PetNeeds) -> some View {
        Button(action: onFeed) {
            Label("Cho ăn", systemImage: "fork.knife").frame(maxWidth: .infinity)
        }
        .buttonStyle(SoftButtonStyle(tint: NeedLevel(needs.fullness) == .needsCare ? Palette.peach : Palette.lavender))
        let clean = needs.cleanliness >= CareConfig.cleanEnough
        Button(action: onClean) {
            Label(clean ? "Nhà sạch" : "Dọn nhà", systemImage: clean ? "checkmark.seal" : "sparkles").frame(maxWidth: .infinity)
        }
        .buttonStyle(SoftButtonStyle(tint: Palette.sage))
        .disabled(clean)
        .accessibilityHint(clean ? "Nhà đang sạch bong" : "Mở chế độ dọn nhà")
        Button(action: onCuddle) {
            Label("Nựng một chút", systemImage: "heart").frame(maxWidth: .infinity)
        }
        .buttonStyle(SoftButtonStyle(tint: Palette.peach))
        .accessibilityHint("Nựng thú cưng ngay, giống như vuốt ve trên người")
    }
}

// MARK: Bụi trong phòng & chế độ dọn

/// Bụi/lá khô/giấy vụn nhẹ nhàng ở sàn — số lượng theo mức "Nhà sạch", không che nút hay đồ đạc chính.
struct DustLayer: View {
    let cleanliness: Double

    var body: some View {
        let count = CleanPlan.visibleDust(cleanliness: cleanliness)
        if count > 0 {
            Canvas { ctx, size in
                for s in CleanPlan.spots(count: count, seed: 7) {
                    DustArt.dirt(ctx, kind: s.kind, center: CGPoint(x: s.x * size.width, y: s.y * size.height), size: size.width * 0.07)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// Dọn nhà toàn màn hình: cầm chổi lông gà hoặc khăn lau, chà qua lại lên mạng nhện, bụi, lá khô và vết bẩn.
/// Vết bẩn mờ dần theo quãng chà; dùng sai dụng cụ vẫn sạch, chỉ chậm hơn. Mỗi vết cũng là một nút cho VoiceOver.
/// Xong hết → lưu một lần với mã hành động cố định của lượt (`onFinish`); lỗi lưu → thử lại cùng mã.
struct CleanRoomView: View {
    let room: RoomKind
    let equipped: [ItemSlot: String]
    let appearance: PetAppearance
    let petName: String
    var haptics = true
    let actionID: UUID
    @State var work: CleanWork
    /// Lưu kết quả; trả về true nếu đã lưu.
    let onFinish: (UUID) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var tool: CleanTool = .broom
    @State private var finger: CGPoint?
    @State private var last: (x: Double, y: Double)?
    @State private var tilt: Double = -12
    @State private var bursts: [Burst] = []
    @State private var rubTicks = 0
    @State private var lastTick: TimeInterval = 0
    @State private var hint: String?
    @State private var saveFailed = false
    @State private var finished = false
    /// Chỉ cho ảnh chụp giao diện: vị trí dụng cụ (tỉ lệ căn phòng) khi chưa có ngón tay.
    @State private var previewTool: (x: Double, y: Double)?

    struct Burst: Identifiable {
        let id = UUID()
        let point: CGPoint
        let start: Date
    }

    var body: some View {
        VStack(spacing: Spacing.l) {
            header
            roomArea
            Text(hint ?? (finished ? "Sạch bong rồi! \(petName) vui lắm." : "Kéo dụng cụ qua lại trên vết bẩn. Mạng nhện, bụi, lá khô: chổi lông gà. Vết bẩn: khăn lau."))
                .font(Typography.callout)
                .foregroundStyle(hint == nil ? Palette.inkMuted : Palette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 44)
                .animation(Motion.quick, value: hint)
            toolPicker
            if saveFailed {
                Button("Thử lưu lại") { save() }
                    .buttonStyle(PrimaryButtonStyle(color: Palette.sage))
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.l)
        .cozyBackground()
        .sensoryFeedback(trigger: rubTicks) { _, _ in haptics ? .impact(weight: .light, intensity: 0.45) : nil }
        .sensoryFeedback(trigger: work.cleanedCount) { old, new in haptics && new > old ? .impact(weight: .medium, intensity: 0.8) : nil }
        .sensoryFeedback(trigger: finished) { _, done in haptics && done ? .success : nil }
        .onChange(of: work.isDone) { _, done in if done { save() } }
        .onAppear {
            // Ảnh chụp giao diện (Debug): lau dở vài vết, đặt sẵn khăn lau trên một vết bẩn.
            guard PreviewMode.current == .clean else { return }
            for i in 0..<min(2, work.spots.count) where work.spots[i].kind != .stain { work.clear(i) }
            if let i = work.spots.firstIndex(where: { $0.kind == .stain }) {
                tool = .cloth
                let s = work.spots[i]
                previewTool = (s.x, s.y)
                for k in 0..<5 {
                    let a = (x: s.x - 0.04, y: s.y), b = (x: s.x + 0.04, y: s.y)
                    work.rub(from: k % 2 == 0 ? a : b, to: k % 2 == 0 ? b : a, tool: .cloth)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dọn nhà")
                    .font(Typography.title)
                    .foregroundStyle(Palette.ink)
                Text("Đã sạch \(work.cleanedCount)/\(work.spots.count)")
                    .font(Typography.callout.weight(.semibold))
                    .foregroundStyle(Palette.sage)
                    .contentTransition(.numericText())
            }
            Spacer()
            ProgressView(value: work.fraction)
                .tint(Palette.sage)
                .frame(maxWidth: 120)
                .accessibilityLabel("Tiến độ dọn")
                .accessibilityValue("\(Int(work.fraction * 100)) phần trăm")
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .frame(width: HitTarget.min, height: HitTarget.min)
                    .background(Palette.surface, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Thôi, để sau")
            .accessibilityHint("Thoát chế độ dọn, chưa lưu")
        }
    }

    private var roomArea: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack(alignment: .topLeading) {
                RoomView(room: room, equipped: equipped, appearance: appearance, petMood: finished ? .happy : .idle,
                         petName: petName, bounceTrigger: finished ? 1 : 0, haptics: false)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                TimelineView(.animation(minimumInterval: 1.0 / 30, paused: bursts.isEmpty && finger == nil)) { timeline in
                    Canvas { ctx, sz in
                        for s in work.spots where !s.isClean {
                            DustArt.dirt(ctx, kind: s.kind, center: CGPoint(x: s.x * sz.width, y: s.y * sz.height),
                                         size: sz.width * 0.11, remaining: s.remaining)
                        }
                        for b in bursts {
                            let t = timeline.date.timeIntervalSince(b.start)
                            guard t < 0.7 else { continue }
                            GameArt.sparkle(ctx, at: b.point, progress: CGFloat(t / 0.7), color: rgb(0xFFE08A))
                        }
                        if let finger {
                            DustArt.tool(ctx, tool, at: finger, size: sz.width * 0.14, tilt: tilt)
                        } else if let p = previewTool {
                            DustArt.tool(ctx, tool, at: CGPoint(x: p.x * sz.width + sz.width * 0.03, y: p.y * sz.height),
                                         size: sz.width * 0.14, tilt: 10)
                        }
                    }
                }
                .allowsHitTesting(false)
                // Mỗi vết bẩn là một nút cho VoiceOver / Điều khiển bằng giọng nói.
                ForEach(Array(work.spots.enumerated()), id: \.offset) { i, s in
                    if !s.isClean {
                        Color.clear
                            .frame(width: size.width * 0.14, height: size.width * 0.14)
                            .position(x: s.x * size.width, y: s.y * size.height)
                            .accessibilityElement()
                            .accessibilityLabel("\(s.kind.name), cần \(s.kind.tool.name.lowercased())")
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint("Chạm hai lần để lau sạch")
                            .accessibilityAction { work.clear(i) }
                    }
                }
            }
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in scrub(at: value.location, size: size) }
                .onEnded { _ in
                    last = nil
                    withAnimation(Motion.quick) { finger = nil }
                })
            .accessibilityElement(children: .contain)
            .accessibilityAction(named: "Dọn hết") { work.clearAll() }
        }
        .aspectRatio(RoomLayout.aspect, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous).strokeBorder(Palette.line))
        .disabled(finished)
    }

    private var toolPicker: some View {
        HStack(spacing: Spacing.m) {
            ForEach(CleanTool.allCases) { t in
                Button {
                    tool = t
                    hint = nil
                } label: {
                    VStack(spacing: Spacing.xs) {
                        Canvas { ctx, sz in
                            DustArt.tool(ctx, t, at: CGPoint(x: sz.width * 0.5, y: sz.height * (t == .broom ? 0.78 : 0.55)),
                                         size: sz.width * 0.55, tilt: t == .broom ? -20 : 0)
                        }
                        .frame(width: 56, height: 56)
                        Text(t.name)
                            .font(Typography.callout.weight(.semibold))
                            .foregroundStyle(Palette.ink)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.s)
                    .background(tool == t ? Palette.sageSoft : Palette.surface, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                        .strokeBorder(tool == t ? Palette.sage : Palette.line, lineWidth: tool == t ? 2 : 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(t.name)
                .accessibilityAddTraits(tool == t ? .isSelected : [])
            }
        }
    }

    private func scrub(at p: CGPoint, size: CGSize) {
        guard !finished, size.width > 0, size.height > 0 else { return }
        let point = (x: Double(p.x / size.width), y: Double(p.y / size.height))
        if let prev = finger {
            let dx = p.x - prev.x
            if abs(dx) > 0.5 { tilt = max(-30, min(30, tilt * 0.7 + Double(dx) * 1.2)) }
        }
        finger = p
        if let last {
            let before = work.fraction
            let cleared = work.rub(from: last, to: point, tool: tool)
            for i in cleared {
                let s = work.spots[i]
                bursts.append(Burst(point: CGPoint(x: s.x * size.width, y: s.y * size.height), start: Date()))
            }
            bursts.removeAll { Date().timeIntervalSince($0.start) > 0.8 }
            if work.fraction > before {
                let now = ProcessInfo.processInfo.systemUptime
                if now - lastTick > 0.12 { lastTick = now; rubTicks += 1 }
            }
        }
        self.last = point
        // Gợi ý nhẹ khi đang dùng dụng cụ chậm hơn.
        if let near = work.spot(near: point), near.kind.tool != tool {
            hint = "\(near.kind.name) dễ sạch hơn với \(near.kind.tool.name.lowercased()) — đổi dụng cụ ở dưới nhé."
        } else if hint != nil, work.spot(near: point) != nil {
            hint = nil
        }
    }

    private func save() {
        guard work.isDone, !finished else { return }
        if onFinish(actionID) {
            saveFailed = false
            hint = nil
            withAnimation(Motion.gentle) { finished = true }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_300_000_000)
                dismiss()
            }
        } else {
            saveFailed = true
            hint = "Chưa lưu được. Thử lưu lại nhé — không bị tính hai lần."
        }
    }
}

// MARK: Đồ ăn

/// Khay đồ ăn + cửa hàng đồ ăn. Mọi giao dịch qua AppStore; giao diện chỉ hiện kết quả sau khi lưu thành công.
struct FoodSheet: View {
    enum Tab: String, CaseIterable, Identifiable {
        case tray, shop
        var id: String { rawValue }
        var label: String { self == .tray ? "Khay đồ ăn" : "Mua đồ ăn" }
    }

    var initialTab: Tab = .tray
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var tab: Tab = .tray
    /// Mã hành động đang chờ — giữ lại khi lưu lỗi để thử lại không làm hai lần.
    @State private var pendingFeed: (foodID: String, id: UUID)?
    @State private var pendingBuy: (foodID: String, id: UUID)?
    @State private var meal: MealShow?
    @State private var busy = false
    @State private var message: String?

    struct MealShow: Equatable {
        var foodID: String?
        var record: CareActionRecord
        var startedAt: Date
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            tabPicker
                            CoinBadge(coins: store.wallet.coins)
                        }
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            tabPicker
                            CoinBadge(coins: store.wallet.coins)
                        }
                    }
                    if let meal {
                        MealResultCard(show: meal, appearance: store.petAppearance, petName: store.profile.displayPetName)
                    }
                    if let message {
                        Label(message, systemImage: "checkmark.circle.fill")
                            .font(Typography.callout.weight(.semibold))
                            .foregroundStyle(Palette.sage)
                    }
                    if tab == .tray { tray } else { shop }
                    Text("Đồ ăn trong game là đồ ăn tưởng tượng cho thú cưng của CozyDay, không phải hướng dẫn dinh dưỡng cho thú thật.")
                        .font(Typography.caption2)
                        .foregroundStyle(Palette.inkMuted)
                }
                .padding(Spacing.l)
            }
            .cozyBackground()
            .navigationTitle("Đồ ăn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Xong") { dismiss() } }
            }
            .overlay(alignment: .top) { ErrorOverlay() }
        }
        .onAppear {
            tab = initialTab
            #if DEBUG
            // Chụp ảnh xem trước: cho ăn một lần để thấy kết quả đã lưu.
            if PreviewMode.current == .feed || PreviewMode.current == .careCapped {
                perform(.feed, foodID: "food.apple")
            }
            #endif
        }
    }

    private var tabPicker: some View {
        Picker("Mục", selection: $tab) {
            ForEach(Tab.allCases) { Text($0.label).tag($0) }
        }
        .pickerStyle(.segmented)
    }

    // MARK: Khay

    @ViewBuilder
    private var tray: some View {
        let needs = store.currentNeeds
        let owned = FoodCatalog.all.filter { store.foodCount($0.id) > 0 }
        NeedRow(kind: .fullness, value: needs.fullness)
        if needs.fullness < CareConfig.needsCareBelow {
            CozyCard {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("Bữa cơ bản miễn phí").font(Typography.headline).foregroundStyle(Palette.ink)
                    Text("Luôn có khi \(store.profile.displayPetName) đói, kể cả khi hết xu. Đưa no bụng lên \(Int(CareConfig.freeMealTo)). Không tính thưởng.")
                        .font(Typography.callout).foregroundStyle(Palette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        perform(.freeMeal, foodID: nil)
                    } label: {
                        Label("Nấu bữa cơ bản", systemImage: "frying.pan")
                    }
                    .buttonStyle(PrimaryButtonStyle(color: Palette.sage))
                    .disabled(busy)
                }
            }
        }
        if owned.isEmpty {
            EmptyStateView(symbol: "basket", title: "Khay đang trống",
                           message: "Mua đồ ăn ở mục \"Mua đồ ăn\" — món rẻ nhất chỉ \(FoodCatalog.all.map(\.price).min() ?? 3) xu.")
            Button("Đi mua đồ ăn") { tab = .shop }
                .buttonStyle(SoftButtonStyle())
        }
        ForEach(owned) { food in
            foodRow(food, trailing: AnyView(feedButton(food, full: needs.fullness >= CareConfig.fullEnough)),
                    detail: "Còn \(store.foodCount(food.id))")
        }
        if needs.fullness >= CareConfig.fullEnough {
            Text("\(store.profile.displayPetName) no căng rồi — để dành đồ ăn cho lần sau nhé.")
                .font(Typography.callout).foregroundStyle(Palette.inkMuted)
        }
    }

    private func feedButton(_ food: FoodItem, full: Bool) -> some View {
        Button {
            perform(.feed, foodID: food.id)
        } label: {
            Text("Cho ăn").padding(.horizontal, Spacing.xs)
        }
        .buttonStyle(SoftButtonStyle(tint: Palette.peach))
        .disabled(busy || full)
        .accessibilityLabel("Cho ăn \(food.name)")
    }

    // MARK: Cửa hàng

    @ViewBuilder
    private var shop: some View {
        Text("Đồ ăn là vật phẩm dùng một lần, mua lại được. Món rẻ đủ dùng hằng ngày; món đắt chỉ để đổi vị.")
            .font(Typography.callout).foregroundStyle(Palette.inkMuted)
            .fixedSize(horizontal: false, vertical: true)
        ForEach(FoodCatalog.all) { food in
            let affordable = store.wallet.coins >= food.price
            foodRow(food, trailing: AnyView(
                Button {
                    buy(food)
                } label: {
                    Text("Mua · \(food.price) xu").padding(.horizontal, Spacing.xs)
                }
                .buttonStyle(SoftButtonStyle(tint: affordable ? Palette.lavender : Palette.inkMuted))
                .disabled(busy || !affordable)
                .accessibilityLabel("Mua \(food.name), \(food.price) xu")
            ), detail: "Đang có \(store.foodCount(food.id)) · \(food.blurb)")
        }
    }

    private func foodRow(_ food: FoodItem, trailing: AnyView, detail: String) -> some View {
        let info = HStack(spacing: Spacing.m) {
            FoodArtView(foodID: food.id)
                .frame(width: 56, height: 56)
                .padding(Spacing.xs)
                .background(Palette.surfaceMuted, in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name).font(Typography.headline).foregroundStyle(Palette.ink)
                Text(effect(food)).font(Typography.caption.weight(.semibold)).foregroundStyle(Palette.sage)
                Text(detail).font(Typography.caption).foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        return Group {
            // Chữ rất lớn: nút xuống dòng riêng để tên và tác dụng không bị bóp.
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Spacing.s) { info; trailing }
            } else {
                HStack(spacing: Spacing.s) { info; trailing }
            }
        }
        .padding(Spacing.m)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.l, style: .continuous).strokeBorder(Palette.line))
        .accessibilityElement(children: .combine)
    }

    private func effect(_ food: FoodItem) -> String {
        food.happiness > 0 ? "+\(food.fullness) no bụng · +\(food.happiness) vui vẻ" : "+\(food.fullness) no bụng"
    }

    // MARK: Giao dịch

    private func perform(_ kind: CareActionKind, foodID: String?) {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        let key = foodID ?? "free"
        let id = pendingFeed?.foodID == key ? pendingFeed!.id : UUID()
        pendingFeed = (key, id)
        do {
            let record = try store.performCare(kind, foodID: foodID, actionID: id)
            pendingFeed = nil
            message = nil
            meal = MealShow(foodID: foodID ?? "food.riceball", record: record, startedAt: Date())
        } catch {
            // Lỗi lưu tạm thời: giữ mã để lần bấm sau thử lại đúng hành động này (không làm hai lần).
            if !error.isSaveFailure { pendingFeed = nil }
            ui.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func buy(_ food: FoodItem) {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        let id = pendingBuy?.foodID == food.id ? pendingBuy!.id : UUID()
        pendingBuy = (food.id, id)
        do {
            try store.buyFood(food.id, transactionID: id)
            pendingBuy = nil
            message = "Đã mua \(food.name) (-\(food.price) xu)"
        } catch {
            if !error.isSaveFailure { pendingBuy = nil }
            ui.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

/// Kết quả bữa ăn đã lưu: thú cưng ăn món (3 miếng), rồi hiện câu nói và thưởng thực nhận.
/// Hoạt ảnh chỉ để xem — giao dịch đã được lưu trước khi hoạt ảnh chạy.
struct MealResultCard: View {
    let show: FoodSheet.MealShow
    let appearance: PetAppearance
    let petName: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        CozyCard {
            HStack(spacing: Spacing.m) {
                TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { timeline in
                    let t = reduceMotion ? 10 : timeline.date.timeIntervalSince(show.startedAt)
                    let bites = min(3, Int(t / 0.45))
                    ZStack(alignment: .bottomTrailing) {
                        PetArt(mood: .happy, appearance: appearance, pose: pose(t))
                            .frame(width: 92, height: 92)
                        if bites < 3, let food = show.foodID {
                            Canvas { context, size in
                                var ctx = context
                                ctx.scaleBy(x: size.width / 100, y: size.height / 100)
                                FoodArt.draw(food, in: ctx)
                                FoodArt.bites(ctx, count: bites, background: Palette.surface)
                            }
                            .frame(width: 34, height: 34)
                            .offset(x: 4, y: -8)
                        }
                    }
                }
                .frame(width: 100, height: 96)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(CareDialogue.done(show.record.kind, petName: petName, alreadyFine: show.record.note == .notNeeded))
                        .font(Typography.headline).foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(CareDialogue.rewardNote(show.record))
                        .font(Typography.callout.weight(.semibold))
                        .foregroundStyle(show.record.isRewarded ? Palette.lavender : Palette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("No bụng: \(show.record.before) → \(show.record.after)")
                        .font(Typography.caption.monospacedDigit()).foregroundStyle(Palette.inkMuted)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func pose(_ t: TimeInterval) -> PetPose {
        var p = PetPose()
        p.petted = 1
        if t < 1.4 {
            p.tilt = sin(t * 2 * .pi / 0.45) * 4
            p.hop = CGFloat(abs(sin(t * 2 * .pi / 0.45))) * 2
        } else if t < 2.8 {
            p.hearts = CGFloat((t - 1.4) / 1.4)
        }
        return p
    }
}
