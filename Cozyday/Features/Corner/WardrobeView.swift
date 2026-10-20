import SwiftUI

/// Tủ đồ: đổi hình dạng, màu lông và trang phục. Chạm một món để mặc thử ngay trên thú cưng
/// (không tốn xu); chỉ khi bấm nút bên dưới mới mua / dùng.
struct WardrobeView: View {
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss

    @State private var slot: ItemSlot = .species
    /// Món đang mặc thử ở vị trí hiện tại. `""` = thử "không dùng gì".
    @State private var trial: String?
    @State private var working = false
    @State private var showGacha = false

    private static let noneID = ""

    var body: some View {
        let current = store.petAppearance
        let preview = previewAppearance(current)
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    PetView(appearance: preview, mood: .happy, name: store.profile.displayPetName,
                            bounceTrigger: trialBounce, interactive: true, haptics: store.profile.hapticsEnabled)
                        .silhouette(trial.flatMap(Catalog.item).map(isHidden) ?? false)
                        .frame(width: 180, height: 180)
                        .frame(maxWidth: .infinity)
                        .padding(.top, Spacing.xl)
                        .background(Palette.roomWall, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))

                    actionArea(current: current)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.s) {
                            ForEach(ItemSlot.pet) { s in
                                ChipToggle(title: s.label, isOn: slot == s) {
                                    slot = s
                                    trial = nil
                                }
                            }
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: Spacing.m)], spacing: Spacing.m) {
                        if !slot.hasDefault {
                            card(nil, current: current)
                        }
                        ForEach(Catalog.items(in: slot)) { item in
                            card(item, current: current)
                        }
                    }
                }
                .padding(Spacing.l)
            }
            .cozyBackground()
            .navigationTitle("Tủ đồ của \(store.profile.displayPetName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Xong") { dismiss() } }
            }
            .overlay(alignment: .top) { ErrorOverlay() }
            .sheet(isPresented: $showGacha) { GachaView() }
            .task {
                // Khi CI chụp ảnh giao diện: mặc thử một món chưa có để thấy nút Mua.
                if PreviewMode.current == .wardrobe {
                    slot = .species
                    trial = "species.bunny"
                }
                if PreviewMode.current == .wardrobeSecret {
                    // Ảnh xem trước: mục Phụ kiện có món bí mật (chỉ hiện bóng) và món chỉ có trong gacha.
                    slot = .back
                    trial = Catalog.items(in: .back).first { $0.isHiddenUntilOwned }?.id
                }
                if PreviewMode.current == .trailerWardrobe {
                    // Trailer: thử lần lượt vài món có thật trong tủ, như người dùng chạm từng ô.
                    let picks: [(ItemSlot, String)] = [(.hat, "hat.chef"), (.outfit, "outfit.apron"), (.glasses, "glasses.heart"),
                                                       (.outfit, "outfit.sailor"), (.hat, "hat.straw"), (.neck, "neck.lei")]
                    try? await Task.sleep(nanoseconds: 900_000_000)
                    for (s, id) in picks where !Task.isCancelled {
                        slot = s
                        try? await Task.sleep(nanoseconds: 350_000_000)
                        trial = id
                        try? await Task.sleep(nanoseconds: 750_000_000)
                    }
                }
            }
        }
    }

    private var trialBounce: Int { (trial ?? "-").hashValue & 0xFFFF }

    /// Món bí mật chưa có: chỉ thấy bóng.
    private func isHidden(_ item: CatalogItem) -> Bool {
        item.isHiddenUntilOwned && !Catalog.isOwned(item.id, owned: store.ownedIDs)
    }

    private func previewAppearance(_ current: PetAppearance) -> PetAppearance {
        guard let trial else { return current }
        if trial == Self.noneID { return current.removing(slot) }
        guard let item = Catalog.item(trial) else { return current }
        return current.trying(item)
    }

    // MARK: Ô vật phẩm

    private func card(_ item: CatalogItem?, current: PetAppearance) -> some View {
        let id = item?.id ?? Self.noneID
        let inUse = (current.itemID(in: slot) ?? Self.noneID) == id
        let selected = (trial ?? current.itemID(in: slot) ?? Self.noneID) == id
        let level = store.wallet.level
        let thumb = item.map { current.trying($0) } ?? current.removing(slot)
        let hidden = item.map(isHidden) ?? false
        return Button {
            trial = id
        } label: {
            VStack(spacing: Spacing.xs) {
                PetArt(mood: .idle, appearance: thumb)
                    .silhouette(hidden)
                    .frame(width: 72, height: 72)
                    .overlay(alignment: .topTrailing) {
                        if let item, item.tier >= .rare { RarityDot(rarity: item.tier) }
                    }
                Text(hidden ? "???" : (item?.name ?? "Không dùng"))
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 30)
                status(item, inUse: inUse, level: level)
                    .font(Typography.caption2.weight(.semibold))
            }
            .padding(Spacing.s)
            .frame(maxWidth: .infinity)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                    .strokeBorder(selected ? Palette.lavender : (inUse ? Palette.sage : Palette.line), lineWidth: selected || inUse ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText(item, inUse: inUse, level: level))
        .accessibilityHint("Mặc thử")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder
    private func status(_ item: CatalogItem?, inUse: Bool, level: Int) -> some View {
        if inUse {
            Text("Đang dùng").foregroundStyle(Palette.sage)
        } else if let item {
            if Catalog.isOwned(item.id, owned: store.ownedIDs) {
                Text("Đã có").foregroundStyle(Palette.inkMuted)
            } else if item.gachaOnly {
                Label("Gacha", systemImage: "gift.fill").foregroundStyle(Palette.lavender)
            } else if level < item.requiredLevel {
                Label("Cấp \(item.requiredLevel)", systemImage: "lock.fill").foregroundStyle(Palette.inkMuted)
            } else {
                Text(item.isFree ? "Miễn phí" : "\(item.price) xu").foregroundStyle(Palette.honeyText)
            }
        } else {
            Text(" ")
        }
    }

    private func accessibilityText(_ item: CatalogItem?, inUse: Bool, level: Int) -> String {
        guard let item else { return inUse ? "Không dùng, đang chọn" : "Không dùng" }
        if inUse { return "\(item.name), đang dùng" }
        if Catalog.isOwned(item.id, owned: store.ownedIDs) { return "\(item.name), đã có" }
        if isHidden(item) { return "Món bí mật, chỉ có trong máy gacha" }
        if item.gachaOnly { return "\(item.name), \(item.tier.label), chỉ có trong máy gacha" }
        if level < item.requiredLevel { return "\(item.name), mở khóa ở cấp \(item.requiredLevel)" }
        return "\(item.name), \(item.isFree ? "miễn phí" : "\(item.price) xu")"
    }

    // MARK: Nút hành động cho món đang thử

    @ViewBuilder
    private func actionArea(current: PetAppearance) -> some View {
        let inUseID = current.itemID(in: slot) ?? Self.noneID
        let chosen = trial ?? inUseID
        VStack(spacing: Spacing.s) {
            if chosen == inUseID {
                Text(trial == nil ? "Chạm một món bên dưới để mặc thử." : "Đây là món đang dùng.")
                    .font(Typography.callout)
                    .foregroundStyle(Palette.inkMuted)
                    .frame(minHeight: HitTarget.min)
            } else if chosen == Self.noneID {
                Button("Tháo \(slot.label.lowercased())") {
                    perform { try store.unequip(slot: slot) }
                }
                .buttonStyle(PrimaryButtonStyle(color: Palette.sage))
            } else if let item = Catalog.item(chosen) {
                let coins = store.wallet.coins
                let level = store.wallet.level
                if Catalog.isOwned(item.id, owned: store.ownedIDs) {
                    Button("Dùng \(item.name)") {
                        perform { try store.equip(itemID: item.id) }
                    }
                    .buttonStyle(PrimaryButtonStyle(color: Palette.sage))
                } else if item.gachaOnly {
                    Button {
                        showGacha = true
                    } label: {
                        Label(isHidden(item) ? "Món bí mật: thử vận may ở máy gacha" : "\(item.tier.label): chỉ có trong máy gacha", systemImage: "gift.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle(color: Palette.lavender))
                } else if level < item.requiredLevel {
                    Label("Mở khóa khi \(store.profile.displayPetName) đạt cấp \(item.requiredLevel) (đang cấp \(level))", systemImage: "lock.fill")
                        .font(Typography.callout)
                        .foregroundStyle(Palette.inkMuted)
                        .multilineTextAlignment(.center)
                        .frame(minHeight: HitTarget.min)
                } else if coins >= item.price {
                    Button(item.isFree ? "Nhận miễn phí \(item.name)" : "Mua \(item.name) · \(item.price) xu") {
                        perform {
                            try store.buy(itemID: item.id)
                            try store.equip(itemID: item.id)
                            ui.showReward(item.isFree ? "Đã nhận \(item.name)" : "Đã mua \(item.name)")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(working)
                } else {
                    Text("Cần thêm \(item.price - coins) xu để mua \(item.name).")
                        .font(Typography.callout)
                        .foregroundStyle(Palette.inkMuted)
                        .frame(minHeight: HitTarget.min)
                }
                Text(item.blurb)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.inkMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func perform(_ action: () throws -> Void) {
        guard !working else { return }
        working = true
        defer { working = false }
        if ui.run(action) { trial = nil }
    }
}
