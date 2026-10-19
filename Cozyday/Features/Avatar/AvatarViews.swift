import SwiftUI
import UniformTypeIdentifiers

/// Ảnh đại diện vẽ bằng `AvatarPainter`. `animated`: lấp lánh / rơi / bay nhẹ (tắt khi bật Giảm chuyển động).
struct AvatarArt: View {
    var background: String
    var scene: String
    var effect: String
    var mood: PetMood
    var appearance: PetAppearance
    var caption: String?
    var animated = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if animated && !reduceMotion {
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                canvas(time: timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600) + 1)
            }
        } else {
            canvas(time: 0)
        }
    }

    private func canvas(time: Double) -> some View {
        Canvas { context, size in
            var ctx = context
            ctx.clip(to: Path(CGRect(origin: .zero, size: size)))
            ctx.scaleBy(x: size.width / 100, y: size.height / 100)
            painter(time: time).draw(in: ctx)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    func painter(time: Double = 0) -> AvatarPainter {
        AvatarPainter(background: background, scene: scene, effect: effect, mood: mood,
                      appearance: appearance, caption: caption, time: time)
    }
}

extension AvatarArt {
    /// Ảnh theo một cấu hình (lựa chọn chưa mở khóa → mặc định).
    init(config: AvatarConfig, appearance: PetAppearance, level: Int, caption: String?, animated: Bool = false) {
        self.init(background: config.resolved(.background, level: level), scene: config.resolved(.scene, level: level),
                  effect: config.resolved(.effect, level: level), mood: PetMood(avatarID: config.resolved(.mood, level: level)),
                  appearance: appearance, caption: caption, animated: animated)
    }
}

/// Ảnh đại diện đã lưu của người dùng, cắt tròn hoặc bo góc.
struct UserAvatar: View {
    @Environment(AppStore.self) private var store
    var size: CGFloat
    var circle = true
    var animated = false

    var body: some View {
        let art = AvatarArt(config: store.avatar, appearance: store.avatarAppearance, level: store.wallet.level,
                            caption: nil, animated: animated)
            .frame(width: size, height: size)
        Group {
            if circle {
                art.clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.9), lineWidth: max(2, size / 28)))
            } else {
                art.clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            }
        }
        .shadow(color: Palette.shadow.opacity(0.15), radius: size / 12, y: size / 30)
        .accessibilityElement()
        .accessibilityLabel("Ảnh đại diện: \(store.profile.displayPetName)")
    }
}

/// Ảnh PNG 1024×1024 để chia sẻ / lưu vào Ảnh. Chỉ dựng khi người dùng thật sự chọn chia sẻ.
struct AvatarSnapshot: Transferable {
    let painter: AvatarPainter

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { snapshot in
            try await MainActor.run { try snapshot.pngData() }
        }
        .suggestedFileName("CozyDay-avatar.png")
    }

    @MainActor
    func pngData(side: CGFloat = 1024) throws -> Data {
        let painter = self.painter
        let renderer = ImageRenderer(content:
            Canvas { context, size in
                var ctx = context
                ctx.scaleBy(x: size.width / 100, y: size.height / 100)
                painter.draw(in: ctx)
            }
            .frame(width: side, height: side)
        )
        renderer.scale = 1
        guard let data = renderer.uiImage?.pngData() else { throw StoreError.invalid("Không tạo được ảnh.") }
        return data
    }
}

/// Lối vào trong Góc nhỏ.
struct AvatarEntryCard: View {
    @Environment(AppStore.self) private var store
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                UserAvatar(size: 64, circle: false)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ảnh đại diện")
                        .font(Typography.headline)
                        .foregroundStyle(Palette.ink)
                    Text("Khoe \(store.profile.displayPetName): nền, phong cảnh, hiệu ứng, trang phục")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Spacing.xs)
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(Palette.peach)
                    .accessibilityHidden(true)
            }
            .padding(Spacing.m)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.l, style: .continuous).strokeBorder(Palette.peach.opacity(0.5), lineWidth: 1.5))
            .shadow(color: Palette.shadow.opacity(0.1), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Mở trình tạo ảnh đại diện")
    }
}

/// Thẻ hồ sơ đầu tab Tiến bộ.
struct AvatarProfileCard: View {
    @Environment(AppStore.self) private var store
    let action: () -> Void

    var body: some View {
        let wallet = store.wallet
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                UserAvatar(size: 76)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(store.profile.displayUserName.capitalized(with: Locale(identifier: "vi_VN")) + " & " + store.profile.displayPetName)
                        .font(Typography.headline)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(2)
                    Text("Cấp \(wallet.level) · \(PetStage.forLevel(wallet.level).label)")
                        .font(Typography.callout.weight(.semibold))
                        .foregroundStyle(Palette.lavender)
                    Label("Sửa ảnh đại diện", systemImage: "paintbrush.pointed")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.inkMuted)
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.l, style: .continuous).strokeBorder(Palette.line))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Mở trình tạo ảnh đại diện")
    }
}

/// Trình tạo ảnh đại diện: chọn nền, phong cảnh, hiệu ứng, biểu cảm và trang phục (từ đồ đã có).
/// Không tốn xu; vài lựa chọn mở theo cấp. Chỉ ghi khi bấm "Lưu".
struct AvatarStudioView: View {
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss

    enum Tab: String, CaseIterable, Identifiable {
        case background, scene, effect, mood, outfit
        var id: String { rawValue }
        var label: String { part?.label ?? "Trang phục" }
        var part: AvatarPart? { AvatarPart(rawValue: rawValue) }
    }

    @State private var draft: AvatarConfig = .standard
    @State private var loaded = false
    @State private var tab: Tab = .background
    @State private var slot: ItemSlot = .hat

    var body: some View {
        let level = store.wallet.level
        let appearance = draft.appearance(equipped: store.equippedMap, owned: store.ownedIDs, level: level)
        let caption = draft.showName ? "\(store.profile.displayPetName) · Cấp \(level)" : nil
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    AvatarArt(config: draft, appearance: appearance, level: level, caption: caption, animated: true)
                        .frame(maxWidth: 300)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
                        .shadow(color: Palette.shadow.opacity(0.18), radius: 14, y: 6)
                        .frame(maxWidth: .infinity)
                        .accessibilityElement()
                        .accessibilityLabel(summary(appearance: appearance, level: level))

                    HStack(spacing: Spacing.s) {
                        Toggle(isOn: $draft.showName) {
                            Text("Hiện tên & cấp").font(Typography.callout)
                        }
                        .toggleStyle(.button)
                        .tint(Palette.lavender)
                        Spacer(minLength: 0)
                        Button {
                            shuffle(level: level)
                        } label: {
                            Label("Ngẫu nhiên", systemImage: "dice")
                        }
                        .buttonStyle(SoftButtonStyle(tint: Palette.peach))
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.s) {
                            ForEach(Tab.allCases) { t in
                                ChipToggle(title: t.label, isOn: tab == t) { tab = t }
                            }
                        }
                    }

                    if let part = tab.part {
                        optionGrid(part, appearance: appearance, level: level)
                    } else {
                        outfitArea(appearance: appearance, level: level)
                    }

                    ShareLink(item: AvatarSnapshot(painter: AvatarArt(config: draft, appearance: appearance, level: level, caption: caption).painter()),
                              preview: SharePreview("Ảnh đại diện của \(store.profile.displayPetName)")) {
                        Label("Lưu ảnh / chia sẻ", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SoftButtonStyle(tint: Palette.lavender))

                    Text("Ảnh chỉ được tạo trên máy khi bạn bấm chia sẻ — app không tải lên đâu cả. Chọn \"Lưu hình ảnh\" để cất vào app Ảnh.")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.inkMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(Spacing.l)
            }
            .cozyBackground()
            .navigationTitle("Ảnh đại diện")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        if ui.run({ try store.saveAvatar(draft) }) {
                            ui.showReward("Đã lưu ảnh đại diện")
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .overlay(alignment: .top) { ErrorOverlay() }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                draft = store.avatar
                // Ảnh chụp giao diện (Debug): mở thẳng tab trang phục.
                if PreviewMode.current == .avatarOutfit { tab = .outfit }
            }
        }
    }

    // MARK: Nền / phong cảnh / hiệu ứng / biểu cảm

    private func optionGrid(_ part: AvatarPart, appearance: PetAppearance, level: Int) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: Spacing.m)], spacing: Spacing.m) {
            ForEach(part.options) { option in
                let unlocked = option.isUnlocked(level: level)
                let selected = draft.resolved(part, level: level) == option.id
                Button {
                    if unlocked { draft.set(part, option.id) }
                } label: {
                    VStack(spacing: Spacing.xs) {
                        thumbnail(part, option.id, appearance: appearance, level: level)
                            .frame(width: 84, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
                            .overlay {
                                if !unlocked {
                                    RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                                        .fill(Color.black.opacity(0.35))
                                    Image(systemName: "lock.fill").foregroundStyle(.white).font(.title3)
                                }
                            }
                        Text(option.name)
                            .font(Typography.caption.weight(.semibold))
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(unlocked ? (selected ? "Đang chọn" : " ") : "Cấp \(option.requiredLevel)")
                            .font(Typography.caption2.weight(.semibold))
                            .foregroundStyle(selected ? Palette.sage : Palette.inkMuted)
                    }
                    .padding(Spacing.s)
                    .frame(maxWidth: .infinity)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                        .strokeBorder(selected ? Palette.lavender : Palette.line, lineWidth: selected ? 2 : 1))
                }
                .buttonStyle(.plain)
                .disabled(!unlocked)
                .accessibilityLabel(unlocked ? option.name : "\(option.name), mở khóa ở cấp \(option.requiredLevel)")
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    /// Ô xem trước: đổi đúng phần đang chọn, các phần khác giữ nguyên (biểu cảm xem trên nền trơn).
    private func thumbnail(_ part: AvatarPart, _ id: String, appearance: PetAppearance, level: Int) -> some View {
        let bg = draft.resolved(.background, level: level)
        switch part {
        case .background:
            return AvatarArt(background: id, scene: "none", effect: "none", mood: .happy, appearance: appearance)
        case .scene:
            return AvatarArt(background: bg, scene: id, effect: "none", mood: .happy, appearance: appearance)
        case .effect:
            return AvatarArt(background: bg, scene: "none", effect: id, mood: .happy, appearance: appearance)
        case .mood:
            return AvatarArt(background: bg, scene: "none", effect: "none", mood: PetMood(avatarID: id), appearance: appearance)
        }
    }

    // MARK: Trang phục

    private func outfitArea(appearance: PetAppearance, level: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                Text(draft.look == nil ? "Đang mặc theo đồ của \(store.profile.displayPetName)." : "Trang phục riêng cho ảnh.")
                    .font(Typography.callout)
                    .foregroundStyle(Palette.inkMuted)
                Spacer(minLength: 0)
                if draft.look != nil {
                    Button("Theo đồ đang mặc") { draft.look = nil }
                        .font(Typography.callout.weight(.semibold))
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s) {
                    ForEach(ItemSlot.pet) { s in
                        ChipToggle(title: s.label, isOn: slot == s, tint: Palette.peach) { slot = s }
                    }
                }
            }
            let items = Catalog.items(in: slot).filter { Catalog.isOwned($0.id, owned: store.ownedIDs) }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: Spacing.m)], spacing: Spacing.m) {
                if !slot.hasDefault {
                    outfitCard(nil, appearance: appearance)
                }
                ForEach(items) { item in
                    outfitCard(item, appearance: appearance)
                }
            }
            Text("Chỉ hiện đồ \(store.profile.displayPetName) đã có. Muốn thêm đồ mới thì ghé Tủ đồ hoặc Bộ sưu tập trong Góc nhỏ. Đổi đồ ở đây không thay đồ đang mặc trong phòng.")
                .font(Typography.caption)
                .foregroundStyle(Palette.inkMuted)
        }
    }

    private func outfitCard(_ item: CatalogItem?, appearance: PetAppearance) -> some View {
        let id = item?.id
        let selected = appearance.itemID(in: slot) == id
        let thumb = item.map { appearance.trying($0) } ?? appearance.removing(slot)
        return Button {
            draft.setLook(slot, to: id, current: appearance)
        } label: {
            VStack(spacing: Spacing.xs) {
                PetArt(mood: .happy, appearance: thumb)
                    .frame(width: 72, height: 72)
                Text(item?.name ?? "Không dùng")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 30)
            }
            .padding(Spacing.s)
            .frame(maxWidth: .infinity)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                .strokeBorder(selected ? Palette.peach : Palette.line, lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item?.name ?? "Không dùng")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Khác

    private func shuffle(level: Int) {
        for part in [AvatarPart.background, .scene, .effect] {
            let open = part.options.filter { $0.isUnlocked(level: level) && $0.id != "none" }
            if let pick = open.randomElement() { draft.set(part, pick.id) }
        }
    }

    private func summary(appearance: PetAppearance, level: Int) -> String {
        let names = AvatarPart.allCases.compactMap { AvatarCatalog.option($0, draft.resolved($0, level: level))?.name }
        return "Xem trước ảnh đại diện: \(appearance.species.name) \(store.profile.displayPetName). " + names.joined(separator: ", ")
    }
}
