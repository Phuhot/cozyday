import SwiftUI

/// Nút vào Sân chơi trong Góc nhỏ.
struct PlaygroundEntryCard: View {
    @Environment(AppStore.self) private var store
    let action: () -> Void

    var body: some View {
        let today = store.minigameCoins(on: store.today)
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                GameThumbnail(kind: .cloudJump, appearance: store.petAppearance)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sân chơi")
                        .font(Typography.headline)
                        .foregroundStyle(Palette.ink)
                    Text("3 trò chơi ngắn cùng \(store.profile.displayPetName) · \(today)/\(MinigameConfig.dailyCoinCap) xu hôm nay")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Spacing.xs)
                Image(systemName: "gamecontroller.fill")
                    .font(.title2)
                    .foregroundStyle(Palette.lavender)
                    .accessibilityHidden(true)
            }
            .padding(Spacing.m)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.l, style: .continuous).strokeBorder(Palette.lavender.opacity(0.5), lineWidth: 1.5))
            .shadow(color: Palette.shadow.opacity(0.1), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Mở Sân chơi")
    }
}

/// Sân chơi: chọn bạn nhỏ, xem kỷ lục và hạn mức xu hôm nay, vào chơi một trong ba game.
struct PlaygroundView: View {
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    /// Loài chơi ở Sân chơi (chỉ là lựa chọn hiển thị trên máy này; rỗng = loài đang dùng). Không đổi pet ngoài Góc nhỏ.
    @AppStorage("playground.species") private var speciesRaw = ""
    @AppStorage("playground.sound") private var soundOn = true
    @AppStorage("playground.haptics") private var hapticsOn = true
    @AppStorage("playground.memoryLevel") private var levelRaw = MemoryLevel.easy.rawValue
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var active: PlayHostModel?
    @State private var pickingPet = false

    private var level: MemoryLevel { MemoryLevel(rawValue: levelRaw) ?? .easy }

    /// Loài đang chọn nếu bạn sở hữu; nếu không (chưa mua, hoặc dữ liệu đã khôi phục) thì dùng loài hiện tại.
    private var playSpecies: PetSpecies? {
        guard let s = PetSpecies(rawValue: speciesRaw), Catalog.isOwned("species." + s.rawValue, owned: store.ownedIDs) else { return nil }
        return s
    }

    /// Ngoại hình dùng để chơi: trang phục đang mặc, đổi loài nếu đã chọn loài khác.
    private var playAppearance: PetAppearance {
        var look = store.petAppearance
        if let s = playSpecies { look.species = s }
        return look
    }

    var body: some View {
        let todayCoins = store.minigameCoins(on: store.today)
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                header(todayCoins: todayCoins)
                ForEach(MinigameKind.allCases) { kind in
                    gameCard(kind)
                }
                settingsCard
                recentCard
                DisclosureGroup("Cách tính xu Sân chơi") {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        ForEach(MinigameConfig.rulesText, id: \.self) { line in
                            Label(line, systemImage: "circle.fill")
                                .labelStyle(BulletLabelStyle())
                        }
                        Text("Vì app chạy hoàn toàn offline, nếu đổi ngày giờ của máy thì hạn mức theo ngày cũng đổi theo — CozyDay không chống được gian lận kiểu này một cách tuyệt đối.")
                            .font(Typography.caption).foregroundStyle(Palette.inkMuted)
                    }
                    .padding(.top, Spacing.s)
                }
                .font(Typography.callout)
                .tint(Palette.lavender)
            }
            .padding(Spacing.l)
        }
        .cozyBackground()
        .navigationTitle("Sân chơi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { CoinBadge(coins: store.wallet.coins) }
        }
        .sheet(isPresented: $pickingPet) {
            PlayPetPicker(selection: $speciesRaw)
                .presentationDetents([.medium, .large])
        }
        .fullScreenCover(item: $active) { host in
            GameHostView(host: host, onReplay: { replay(host) }, onExit: { active = nil })
                .environment(store)
        }
        .task { await previewHooks() }
    }

    private func header(todayCoins: Int) -> some View {
        let name = store.profile.displayPetName
        return CozyCard {
            VStack(alignment: .leading, spacing: Spacing.m) {
                let pet = PetView(appearance: playAppearance, mood: .happy, name: name).frame(width: 96, height: 96)
                let info = VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Chơi cùng \(name)")
                        .font(Typography.title)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Hình dạng: \(playAppearance.species.name)\(playSpecies == nil ? " (đang dùng)" : "")")
                        .font(Typography.callout).foregroundStyle(Palette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        pickingPet = true
                    } label: {
                        Label("Đổi bạn chơi", systemImage: "arrow.left.arrow.right")
                            .font(Typography.callout.weight(.semibold))
                    }
                    .frame(minHeight: HitTarget.min)
                    .accessibilityHint("Chọn loài khác bạn đã có để chơi. Không đổi thú cưng ngoài Góc nhỏ.")
                }
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: Spacing.s) { pet; info }
                } else {
                    HStack(spacing: Spacing.m) { pet; info }
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text("Xu sân chơi hôm nay").font(Typography.callout.weight(.semibold)).foregroundStyle(Palette.ink)
                        Spacer()
                        Text("\(todayCoins)/\(MinigameConfig.dailyCoinCap)").font(Typography.headline.monospacedDigit()).foregroundStyle(Palette.honey)
                    }
                    ProgressView(value: Double(min(todayCoins, MinigameConfig.dailyCoinCap)), total: Double(MinigameConfig.dailyCoinCap))
                        .tint(Palette.honey)
                    Text(todayCoins >= MinigameConfig.dailyCoinCap
                         ? "Hôm nay đã nhận đủ xu sân chơi — vẫn chơi và lập kỷ lục thoải mái!"
                         : "Sân chơi là giờ nghỉ ngắn. Việc chính, tập trung và chăm sóc bản thân vẫn cho nhiều xu hơn.")
                        .font(Typography.caption).foregroundStyle(Palette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func gameCard(_ kind: MinigameKind) -> some View {
        let best = store.bestResult(kind)
        return CozyCard(padding: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                GameThumbnail(kind: kind, appearance: playAppearance)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
                HStack(alignment: .firstTextBaseline) {
                    Label(kind.name, systemImage: kind.symbol)
                        .font(Typography.headline)
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Text(best.map { "Kỷ lục: \(bestText(kind, $0))" } ?? "Chưa có kỷ lục")
                        .font(Typography.caption.weight(.bold))
                        .foregroundStyle(best == nil ? Palette.inkMuted : Palette.honey)
                }
                Text(kind.blurb)
                    .font(Typography.callout).foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                if kind == .memoryMatch {
                    HStack(spacing: Spacing.s) {
                        ForEach(MemoryLevel.allCases) { l in
                            ChipToggle(title: "\(l.label) · \(l.pairs) cặp", isOn: level == l, tint: Palette.sage) { levelRaw = l.rawValue }
                        }
                    }
                }
                Button {
                    play(kind)
                } label: {
                    Label("Chơi", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle(color: kind == .giftBasket ? Palette.peach : (kind == .memoryMatch ? Palette.sage : Palette.lavender)))
                .accessibilityLabel("Chơi \(kind.name)")
            }
        }
    }

    private func bestText(_ kind: MinigameKind, _ r: MinigameResultRecord) -> String {
        switch kind {
        case .cloudJump: return "\(r.primary) m · \(r.score) điểm"
        case .giftBasket: return "\(r.score) điểm"
        case .memoryMatch: return "\(r.score) điểm"
        }
    }

    private var settingsCard: some View {
        CozyCard(padding: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Toggle(isOn: $soundOn) { Label("Âm thanh trò chơi", systemImage: "speaker.wave.2") }
                Toggle(isOn: $hapticsOn) { Label("Rung khi chơi", systemImage: "iphone.radiowaves.left.and.right") }
                Text(store.profile.hapticsEnabled
                     ? "Tiếng nhỏ, ngắn, không có nhạc nền và không ngắt nhạc bạn đang nghe. Công tắc im lặng của iPhone cũng tắt tiếng game."
                     : "Rung đang tắt trong Cài đặt của CozyDay nên game cũng không rung.")
                    .font(Typography.caption).foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Nhảy Mây và Giỏ Quà cần kéo ngang bằng tay. Với VoiceOver: vuốt lên/xuống trên vùng chơi để di chuyển (chưa được thử trên máy thật). Lật Thẻ dùng được hoàn toàn với VoiceOver.")
                    .font(Typography.caption).foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .tint(Palette.lavender)
        }
    }

    @ViewBuilder
    private var recentCard: some View {
        let recent = store.recentMinigames
        if !recent.isEmpty {
            CozyCard(padding: Spacing.m) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("Lượt gần đây").font(Typography.headline).foregroundStyle(Palette.ink)
                    ForEach(recent) { r in
                        HStack {
                            Image(systemName: r.kind.symbol).foregroundStyle(Palette.lavender).frame(width: 24)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 0) {
                                Text("\(r.kind.name) · \(r.score) điểm").font(Typography.callout.weight(.semibold))
                                Text(DateText.dateTime(r.finishedAt, calendar: store.calendar))
                                    .font(Typography.caption).foregroundStyle(Palette.inkMuted)
                            }
                            Spacer()
                            Text(r.coins > 0 ? "+\(r.coins) xu" : "0 xu")
                                .font(Typography.callout.weight(.bold).monospacedDigit())
                                .foregroundStyle(r.coins > 0 ? Palette.honey : Palette.inkMuted)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    // MARK: Bắt đầu

    private func makeHost(_ kind: MinigameKind) -> PlayHostModel {
        PlayHostModel(kind: kind, level: level, appearance: playAppearance, petName: store.profile.displayPetName,
                      store: store, soundOn: soundOn, hapticsOn: hapticsOn && store.profile.hapticsEnabled)
    }

    private func play(_ kind: MinigameKind) {
        active = makeHost(kind)
    }

    /// Chơi lại: một lượt mới với mã lượt mới (lượt cũ đã lưu, không bị tính lại).
    private func replay(_ old: PlayHostModel) {
        old.teardown()
        let host = makeHost(old.kind)
        host.previewAutoplay = old.previewAutoplay
        active = host
    }

    private func previewHooks() async {
        #if DEBUG
        guard let screen = PreviewMode.current else { return }
        try? await Task.sleep(nanoseconds: 500_000_000)
        switch screen {
        case .pickPet:
            pickingPet = true
        case .tutorial:
            active = makeHost(.cloudJump)
        case .jump, .pause:
            UserDefaults.standard.set("cloudJump,giftBasket,memoryMatch", forKey: "playground.tutorialsSeen")
            let host = makeHost(.cloudJump)
            host.previewAutoplay = true
            active = host
            if screen == .pause {
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                host.pause()
            }
        case .basket:
            UserDefaults.standard.set("cloudJump,giftBasket,memoryMatch", forKey: "playground.tutorialsSeen")
            let host = makeHost(.giftBasket)
            host.previewAutoplay = true
            active = host
        case .memory:
            UserDefaults.standard.set("cloudJump,giftBasket,memoryMatch", forKey: "playground.tutorialsSeen")
            levelRaw = MemoryLevel.medium.rawValue
            let host = makeHost(.memoryMatch)
            host.previewAutoplay = true
            host.previewMemoryPairs = 3
            active = host
        case .result, .resultCapped:
            UserDefaults.standard.set("cloudJump,giftBasket,memoryMatch", forKey: "playground.tutorialsSeen")
            levelRaw = MemoryLevel.easy.rawValue
            let host = makeHost(.memoryMatch)
            host.previewAutoplay = true
            active = host
        default:
            break
        }
        #endif
    }
}

private struct BulletLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            Text("•").foregroundStyle(Palette.lavender)
            configuration.title.foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Chọn loài để chơi trong Sân chơi: loài đã có chọn được; loài chưa có hiện khóa.
struct PlayPetPicker: View {
    @Binding var selection: String
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text("Bạn nhỏ mặc nguyên bộ đồ đang dùng. Đổi ở đây chỉ áp dụng cho Sân chơi — thú cưng ở Góc nhỏ giữ nguyên. Hình dạng không làm game dễ hay khó hơn.")
                        .font(Typography.callout).foregroundStyle(Palette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: Spacing.m)], spacing: Spacing.m) {
                        ForEach(PetSpecies.allCases, id: \.self) { species in
                            cell(species)
                        }
                    }
                }
                .padding(Spacing.l)
            }
            .cozyBackground()
            .navigationTitle("Chọn bạn chơi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Xong") { dismiss() } }
            }
        }
    }

    private func cell(_ species: PetSpecies) -> some View {
        let owned = Catalog.isOwned("species." + species.rawValue, owned: store.ownedIDs)
        let current = store.petAppearance.species == species
        let selected = selection == species.rawValue || (selection.isEmpty && current)
        var look = store.petAppearance
        look.species = species
        return Button {
            selection = current ? "" : species.rawValue
        } label: {
            VStack(spacing: Spacing.xs) {
                PetArt(mood: owned ? .happy : .idle, appearance: look)
                    .frame(width: 72, height: 72)
                    .saturation(owned ? 1 : 0)
                    .opacity(owned ? 1 : 0.45)
                    .overlay(alignment: .topTrailing) {
                        if !owned {
                            Image(systemName: "lock.fill").foregroundStyle(Palette.inkMuted).padding(4)
                        }
                    }
                Text(species.name.prefix(1).uppercased() + species.name.dropFirst())
                    .font(Typography.callout.weight(.semibold))
                    .foregroundStyle(owned ? Palette.ink : Palette.inkMuted)
                Text(owned ? (current ? "Đang dùng" : "Đã có") : "Chưa có")
                    .font(Typography.caption2.weight(.bold))
                    .foregroundStyle(owned ? Palette.sage : Palette.inkMuted)
            }
            .padding(Spacing.s)
            .frame(maxWidth: .infinity)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                .strokeBorder(selected ? Palette.lavender : Palette.line, lineWidth: selected ? 2.5 : 1))
        }
        .buttonStyle(.plain)
        .disabled(!owned)
        .accessibilityLabel("\(species.name), \(owned ? (selected ? "đang chọn" : "đã có") : "chưa có, mua trong Tủ đồ")")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
