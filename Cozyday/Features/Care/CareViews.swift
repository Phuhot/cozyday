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
                    DustArt.spot(ctx, kind: s.kind, center: CGPoint(x: s.x * size.width, y: s.y * size.height), size: size.width * 0.07)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// Lớp dọn nhà phủ lên căn phòng: chạm hoặc vuốt qua các đốm bụi. Mỗi đốm cũng là một nút cho VoiceOver.
struct CleanModeLayer: View {
    let spots: [(x: Double, y: Double, kind: Int)]
    @Binding var cleared: Set<Int>
    var haptics = true

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack(alignment: .topLeading) {
                Color.white.opacity(0.06)
                ForEach(Array(spots.enumerated()), id: \.offset) { i, s in
                    let d = size.width * 0.13
                    Button { clear(i) } label: {
                        Canvas { ctx, sz in
                            DustArt.spot(ctx, kind: s.kind, center: CGPoint(x: sz.width / 2, y: sz.height / 2), size: sz.width * 0.8)
                        }
                        .frame(width: d, height: d)
                        .opacity(cleared.contains(i) ? 0 : 1)
                        .scaleEffect(cleared.contains(i) ? 1.6 : 1)
                        .animation(Motion.quick, value: cleared)
                    }
                    .buttonStyle(.plain)
                    .disabled(cleared.contains(i))
                    .accessibilityLabel(cleared.contains(i) ? "Đã dọn" : "Đốm bụi \(i + 1)")
                    .accessibilityHint("Chạm để dọn")
                    .position(x: s.x * size.width, y: s.y * size.height)
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                // Vuốt qua đốm nào thì đốm đó sạch.
                for (i, s) in spots.enumerated() where !cleared.contains(i) {
                    let dx = value.location.x - s.x * size.width, dy = value.location.y - s.y * size.height
                    if hypot(dx, dy) < size.width * 0.085 { clear(i) }
                }
            })
        }
        .sensoryFeedback(trigger: cleared.count) { _, _ in haptics ? .impact(weight: .light, intensity: 0.6) : nil }
    }

    private func clear(_ i: Int) {
        guard !cleared.contains(i) else { return }
        cleared.insert(i)
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
