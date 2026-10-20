import SwiftUI

/// Bộ sưu tập: lưới các bộ phối sẵn và các loài thú cưng. Chạm một ô để xem thử, mua đủ bộ và mặc ngay.
struct PetCollectionView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var selected: PetLook?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.s), count: 3)

    var body: some View {
        let owned = store.ownedIDs
        let progress = CollectionProgress(owned: owned)
        let stage = PetStage.forLevel(store.wallet.level)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    HStack(spacing: Spacing.s) {
                        stat("\(progress.completeLooks)/\(progress.totalLooks)", "bộ phối", Palette.peach)
                        stat("\(progress.ownedPetItems)/\(progress.totalPetItems)", "đồ thú cưng", Palette.lavender)
                        stat("\(progress.ownedRoomItems)/\(progress.totalRoomItems)", "đồ trang trí", Palette.sage)
                    }

                    Text("Các loài")
                        .font(Typography.title)
                        .foregroundStyle(Palette.ink)
                    LazyVGrid(columns: columns, spacing: Spacing.s) {
                        ForEach(PetSpecies.allCases, id: \.self) { species in
                            let intro = species.introLook
                            let current = store.petAppearance.species == species
                            cell(withCurrentOutfit(species), appearance: intro.appearance(stage: stage), owned: owned,
                                 ownedText: current ? "Đang dùng" : (Catalog.isOwned("species." + species.rawValue, owned: owned) ? "Đã có" : nil))
                        }
                    }

                    Text("Phối sẵn")
                        .font(Typography.title)
                        .foregroundStyle(Palette.ink)
                    Text("Chạm để mặc thử. Thiếu món nào có thể mua cả bộ một lần.")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.inkMuted)
                    LazyVGrid(columns: columns, spacing: Spacing.s) {
                        ForEach(PetLooks.all) { look in
                            cell(look, appearance: look.appearance(stage: stage), owned: owned, ownedText: nil)
                        }
                    }
                }
                .padding(Spacing.l)
            }
            .cozyBackground()
            .navigationTitle("Bộ sưu tập")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Xong") { dismiss() } }
            }
            .sheet(item: $selected) { look in
                LookDetailSheet(look: look)
                    .presentationDetents([.medium, .large])
            }
            .overlay(alignment: .top) { ErrorOverlay() }
            .task {
                if PreviewMode.current == .look {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    selected = PetLooks.look("look.capyguitar")
                }
            }
        }
    }

    private func stat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 0) {
            Text(value)
                .font(Typography.headline.monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(Typography.caption2)
                .foregroundStyle(Palette.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// Loài này với màu lông tự nhiên, giữ nguyên mũ/kính/cổ/áo/phụ kiện đang mặc.
    private func withCurrentOutfit(_ species: PetSpecies) -> PetLook {
        let current = store.petAppearance
        let items = [ItemSlot.hat, .glasses, .neck, .outfit, .back].compactMap { current.itemID(in: $0) }
        return PetLook(id: "species." + species.rawValue, name: species.introLook.name, species: species,
                       fur: species.naturalFur, items: items)
    }

    private func cellStatus(_ look: PetLook, wearing: Bool, missing: [CatalogItem], locked: Bool,
                            owned: Set<String>, ownedText: String?) -> (String, Color) {
        if wearing { return ("Đang mặc", Palette.sage) }
        if let ownedText { return (ownedText, Palette.inkMuted) }
        if missing.isEmpty { return ("Đủ đồ", Palette.sage) }
        if locked { return ("Cấp \(look.requiredLevel)", Palette.inkMuted) }
        return ("\(look.cost(owned: owned)) xu", Palette.honey)
    }

    private func cell(_ look: PetLook, appearance: PetAppearance, owned: Set<String>, ownedText: String?) -> some View {
        let wearing = store.petAppearance.itemIDs == appearance.itemIDs
        let missing = look.missing(owned: owned)
        let locked = look.requiredLevel > store.wallet.level && !missing.isEmpty
        let (status, color) = cellStatus(look, wearing: wearing, missing: missing, locked: locked, owned: owned, ownedText: ownedText)
        return Button { selected = look } label: {
            VStack(spacing: 2) {
                PetArt(mood: look.name.count % 3 == 0 ? .happy : .idle, appearance: appearance)
                    .frame(width: 96, height: 96)
                    .opacity(locked ? 0.55 : 1)
                    .overlay(alignment: .topTrailing) {
                        if locked {
                            Image(systemName: "lock.fill").font(.caption).foregroundStyle(Palette.inkMuted).padding(6)
                        }
                    }
                Text(look.name)
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(status)
                    .font(Typography.caption2.weight(.bold))
                    .foregroundStyle(color)
            }
            .padding(.vertical, Spacing.s)
            .padding(.horizontal, Spacing.xs)
            .frame(maxWidth: .infinity)
            .background(Palette.roomWall, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.l, style: .continuous).strokeBorder(wearing ? Palette.sage : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(look.name), \(status)")
        .accessibilityHint("Xem thử")
    }
}

/// Xem thử một bộ: thú cưng chuyển động, danh sách món, nút mua cả bộ / mặc.
struct LookDetailSheet: View {
    let look: PetLook
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss
    @State private var working = false

    var body: some View {
        let owned = store.ownedIDs
        let missing = look.missing(owned: owned)
        let cost = look.cost(owned: owned)
        let level = store.wallet.level
        let appearance = look.appearance(stage: PetStage.forLevel(level))
        ScrollView {
            VStack(spacing: Spacing.l) {
                PetView(appearance: appearance, mood: .happy, name: store.profile.displayPetName,
                        interactive: true, haptics: store.profile.hapticsEnabled)
                    .frame(width: 190, height: 190)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.l)
                    .background(Palette.roomWall, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
                Text(look.name)
                    .font(Typography.title)
                    .foregroundStyle(Palette.ink)
                LookItemChips(items: look.itemIDs.compactMap(Catalog.item).filter { !$0.isDefault || $0.slot == .species }, owned: owned)

                if missing.isEmpty {
                    Button("Mặc bộ này") { wear() }
                        .buttonStyle(PrimaryButtonStyle(color: Palette.sage))
                        .disabled(working)
                } else if look.requiredLevel > level {
                    Label("Mở khóa đủ bộ ở cấp \(look.requiredLevel) (đang cấp \(level))", systemImage: "lock.fill")
                        .font(Typography.callout)
                        .foregroundStyle(Palette.inkMuted)
                } else if cost > store.wallet.coins {
                    Text("Còn thiếu \(missing.count) món · cần \(cost) xu (bạn có \(store.wallet.coins) xu).")
                        .font(Typography.callout)
                        .foregroundStyle(Palette.inkMuted)
                        .multilineTextAlignment(.center)
                } else {
                    Button(cost == 0 ? "Nhận \(missing.count) món & mặc" : "Mua \(missing.count) món còn thiếu · \(cost) xu") { wear() }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(working)
                }
                Text("Mặc bộ này sẽ thay mọi món đang dùng của thú cưng. Đồ cũ vẫn còn trong Tủ đồ.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.inkMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.xl)
        }
        .cozyBackground()
    }

    private func wear() {
        guard !working else { return }
        working = true
        var spent = 0
        let ok = ui.run { spent = try store.wearLook(look) }
        working = false
        if ok {
            ui.showReward(spent > 0 ? "Đã mua & mặc \(look.name)" : "Đã mặc \(look.name)")
            dismiss()
        }
    }
}

/// Các món trong bộ, dạng chip; món chưa có hiện giá.
private struct LookItemChips: View {
    let items: [CatalogItem]
    let owned: Set<String>

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: Spacing.s)], spacing: Spacing.s) {
            ForEach(items) { item in
                let has = Catalog.isOwned(item.id, owned: owned)
                HStack(spacing: Spacing.xs) {
                    Image(systemName: has ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(has ? Palette.sage : Palette.inkMuted)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.name).font(Typography.caption.weight(.semibold)).foregroundStyle(Palette.ink).lineLimit(1)
                        Text(has ? item.slot.label : "\(item.slot.label) · \(item.price) xu")
                            .font(Typography.caption2).foregroundStyle(Palette.inkMuted)
                    }
                    Spacer(minLength: 0)
                }
                .padding(Spacing.s)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
                .accessibilityElement(children: .combine)
            }
        }
    }
}
