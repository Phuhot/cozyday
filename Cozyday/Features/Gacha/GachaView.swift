import SwiftUI

extension ItemRarity {
    var color: Color {
        switch self {
        case .common: return Palette.sage
        case .rare: return Color.dynamic(light: 0x6E8FC8, dark: 0x9DB6E6)
        case .epic: return Palette.lavender
        case .secret: return Palette.honey
        }
    }
}

extension View {
    /// Chỉ hiện bóng (món bí mật chưa có).
    @ViewBuilder
    func silhouette(_ on: Bool) -> some View {
        if on {
            // Tô kín một màu theo đường viền: không lộ mắt, họa tiết hay màu của món.
            self.hidden().overlay { Palette.ink.opacity(0.82).mask { self } }
        } else {
            self
        }
    }
}

/// Chấm màu độ hiếm ở góc thẻ đồ.
struct RarityDot: View {
    let rarity: ItemRarity

    var body: some View {
        Image(systemName: rarity == .secret ? "sparkle" : "circle.fill")
            .font(.system(size: rarity == .secret ? 13 : 9, weight: .bold))
            .foregroundStyle(rarity.color)
            .padding(3)
            .background(Palette.surface, in: Circle())
            .accessibilityHidden(true)
    }
}

/// Máy gacha "Mây Mây": quay trang phục / hình dạng. Giá, tỉ lệ và bảo hiểm hiện rõ trên màn hình.
struct GachaView: View {
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var spinningSince: Date?
    @State private var results: GachaResults?
    @State private var showRules = false
    @State private var shelf: ItemRarity = .secret

    struct GachaResults: Identifiable {
        let id = UUID()
        let pulls: [GachaPull]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    // Chữ cỡ Trợ năng: số xu lên trên, câu giới thiệu chiếm cả bề ngang.
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            CoinBadge(coins: store.wallet.coins)
                            intro
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        HStack {
                            intro
                            Spacer(minLength: Spacing.s)
                            CoinBadge(coins: store.wallet.coins)
                        }
                    }

                    machine
                        .frame(height: 260)
                        .accessibilityHidden(true)

                    buttons
                    pityCard
                    shelfCard

                    DisclosureGroup("Tỉ lệ và luật", isExpanded: $showRules) {
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            ForEach(GachaConfig.rulesText, id: \.self) { line in
                                Label(line, systemImage: "circle.fill")
                                    .labelStyle(DotLabelStyle())
                                    .font(Typography.callout)
                                    .foregroundStyle(Palette.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.top, Spacing.s)
                    }
                    .tint(Palette.lavender)
                    .padding(Spacing.m)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
                }
                .padding(Spacing.l)
            }
            .cozyBackground()
            .navigationTitle("Máy gacha Mây Mây")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Xong") { dismiss() } }
            }
            .overlay(alignment: .top) { ErrorOverlay() }
            .task {
                // Ảnh xem trước (Debug): quay 10 lượt để chụp màn kết quả.
                guard PreviewMode.current == .gachaResult else { return }
                try? await Task.sleep(nanoseconds: 800_000_000)
                spin(GachaConfig.tenCount)
            }
            .sheet(item: $results) { r in
                GachaResultView(pulls: r.pulls)
                    .presentationDetents([.large])
            }
        }
    }

    private var intro: some View {
        Text("Mỗi lượt ra một món cho \(store.profile.displayPetName): mũ, kính, áo, phụ kiện hoặc hình dạng mới.")
            .font(Typography.callout)
            .foregroundStyle(Palette.inkMuted)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Máy

    private var machine: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: spinningSince == nil || reduceMotion)) { timeline in
            let t = spinningSince.map { timeline.date.timeIntervalSince($0) } ?? -1
            Canvas { ctx, size in
                GachaMachineArt.draw(ctx, size: size, spin: t)
            }
        }
    }

    private var buttons: some View {
        let coins = store.wallet.coins
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.m)) : AnyLayout(HStackLayout(spacing: Spacing.m))
        return layout {
            Button {
                spin(1)
            } label: {
                VStack(spacing: 2) {
                    Text("Quay 1 lượt").font(Typography.headline)
                    Text("\(GachaConfig.singlePrice) xu").font(Typography.caption.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(color: Palette.peach))
            .disabled(coins < GachaConfig.singlePrice || spinningSince != nil)

            Button {
                spin(GachaConfig.tenCount)
            } label: {
                VStack(spacing: 2) {
                    Text("Quay 10 lượt").font(Typography.headline)
                    Text("\(GachaConfig.tenPrice) xu").font(Typography.caption.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(coins < GachaConfig.tenPrice || spinningSince != nil)
        }
    }

    private var pityCard: some View {
        let pity = store.gachaPity
        let toEpic = max(1, GachaConfig.epicPity - pity.sinceEpic)
        let toSecret = max(1, GachaConfig.secretPity - pity.sinceSecret)
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Label("Còn \(toEpic) lượt chắc chắn có món Quý", systemImage: "sparkles")
                .foregroundStyle(ItemRarity.epic.color)
            Label("Còn \(toSecret) lượt chắc chắn có món Bí mật", systemImage: "sparkle")
                .foregroundStyle(ItemRarity.secret.color)
        }
        .font(Typography.callout.weight(.semibold))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.m)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: Kệ trưng bày

    private var shelfCard: some View {
        let pool = GachaPolicy.pool()
        let items = (pool[shelf] ?? []).sorted { $0.name < $1.name }
        let owned = store.ownedIDs
        let have = items.filter { Catalog.isOwned($0.id, owned: owned) }.count
        return VStack(alignment: .leading, spacing: Spacing.m) {
            Picker("Độ hiếm", selection: $shelf) {
                ForEach(ItemRarity.allCases.reversed(), id: \.self) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            Text("Đã có \(have)/\(items.count) món \(shelf.label.lowercased())")
                .font(Typography.caption.weight(.semibold))
                .foregroundStyle(Palette.inkMuted)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: Spacing.s)], spacing: Spacing.s) {
                ForEach(items) { item in
                    let mine = Catalog.isOwned(item.id, owned: owned)
                    let hidden = item.isHiddenUntilOwned && !mine
                    VStack(spacing: 2) {
                        PetArt(mood: .idle, appearance: store.petAppearance.trying(item))
                            .silhouette(hidden)
                            .opacity(mine || hidden ? 1 : 0.6)
                            .frame(width: 60, height: 60)
                        Text(hidden ? "???" : item.name)
                            .font(Typography.caption2.weight(.semibold))
                            .foregroundStyle(Palette.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(minHeight: 26)
                    }
                    .padding(Spacing.xs)
                    .frame(maxWidth: .infinity)
                    .background(mine ? item.tier.color.opacity(0.14) : Palette.surfaceMuted,
                                in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(hidden ? "Món bí mật chưa có" : "\(item.name), \(mine ? "đã có" : "chưa có")")
                }
            }
        }
        .padding(Spacing.m)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
    }

    // MARK: Quay

    private func spin(_ count: Int) {
        var pulls: [GachaPull] = []
        guard ui.run({ pulls = try store.pullGacha(count: count) }) else { return }
        guard !reduceMotion else {
            results = GachaResults(pulls: pulls)
            return
        }
        spinningSince = Date()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_350_000_000)
            spinningSince = nil
            results = GachaResults(pulls: pulls)
        }
    }
}

private struct DotLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            Text("•").foregroundStyle(Palette.lavender)
            configuration.title
        }
    }
}

/// Kết quả quay: lật từng viên nang theo thứ tự, món mới có nhãn "Mới!", món trùng ghi số xu hoàn lại.
struct GachaResultView: View {
    let pulls: [GachaPull]
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    if pulls.count == 1, let p = pulls.first {
                        bigCard(p)
                    } else {
                        let best = pulls.map(\.tier).max() ?? .common
                        Text(best >= .epic ? "Có món \(best.label.lowercased()) nè!" : "Mở hết 10 viên nang!")
                            .font(Typography.title)
                            .foregroundStyle(best.color)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: Spacing.s)], spacing: Spacing.s) {
                            ForEach(Array(pulls.enumerated()), id: \.offset) { i, p in
                                smallCard(p, shown: i < revealed)
                            }
                        }
                    }
                    let refund = pulls.reduce(0) { $0 + $1.refund }
                    if refund > 0 {
                        Label("Món trùng đổi thành \(refund) xu", systemImage: "arrow.uturn.left.circle")
                            .font(Typography.callout.weight(.semibold))
                            .foregroundStyle(Palette.honey)
                    }
                }
                .padding(Spacing.l)
            }
            .cozyBackground()
            .navigationTitle("Kết quả")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Xong") { dismiss() } }
            }
            .task {
                guard !reduceMotion else { revealed = pulls.count; return }
                for i in 0..<pulls.count {
                    try? await Task.sleep(nanoseconds: 180_000_000)
                    withAnimation(Motion.bouncy) { revealed = i + 1 }
                }
            }
        }
    }

    private func bigCard(_ p: GachaPull) -> some View {
        let item = Catalog.item(p.itemID)
        return VStack(spacing: Spacing.m) {
            Text(p.tier.label)
                .font(Typography.headline)
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.xs)
                .background(p.tier.color.opacity(0.2), in: Capsule())
                .foregroundStyle(p.tier.color)
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [p.tier.color.opacity(0.35), .clear], center: .center, startRadius: 10, endRadius: 140))
                    .frame(width: 260, height: 260)
                if let item {
                    PetArt(mood: .happy, appearance: store.petAppearance.trying(item))
                        .frame(width: 200, height: 200)
                }
            }
            .scaleEffect(revealed > 0 ? 1 : 0.4)
            .opacity(revealed > 0 ? 1 : 0)
            Text(item?.name ?? p.itemID)
                .font(Typography.largeTitle)
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text(p.isDuplicate ? "Đã có rồi, đổi thành \(p.refund) xu." : (item?.blurb ?? ""))
                .font(Typography.callout)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
            if !p.isDuplicate, let item {
                Button("Mặc ngay") {
                    if ui.run({ try store.equip(itemID: item.id) }) {
                        ui.showReward("\(store.profile.displayPetName) đang mặc \(item.name)")
                        dismiss()
                    }
                }
                .buttonStyle(PrimaryButtonStyle(color: Palette.sage))
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func smallCard(_ p: GachaPull, shown: Bool) -> some View {
        let item = Catalog.item(p.itemID)
        return VStack(spacing: 2) {
            ZStack {
                if shown, let item {
                    PetArt(mood: .happy, appearance: store.petAppearance.trying(item))
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Canvas { ctx, size in
                        GachaMachineArt.capsule(ctx, center: CGPoint(x: size.width / 2, y: size.height / 2),
                                                radius: size.width * 0.32, color: p.tier.color)
                    }
                }
            }
            .frame(width: 72, height: 72)
            Text(shown ? (item?.name ?? "") : " ")
                .font(Typography.caption2.weight(.semibold))
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(minHeight: 26)
            Text(shown ? (p.isDuplicate ? "+\(p.refund) xu" : "Mới!") : " ")
                .font(Typography.caption2.weight(.bold))
                .foregroundStyle(p.isDuplicate ? Palette.honey : p.tier.color)
        }
        .padding(Spacing.xs)
        .frame(maxWidth: .infinity)
        .background(p.tier.color.opacity(shown ? 0.16 : 0.08), in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(shown ? "\(p.tier.label): \(item?.name ?? ""), \(p.isDuplicate ? "trùng, \(p.refund) xu" : "mới")" : "Viên nang chưa mở")
    }
}
