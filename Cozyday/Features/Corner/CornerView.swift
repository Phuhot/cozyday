import SwiftUI

/// Tab "Góc nhỏ": thú cưng trong phòng, cấp độ & giai đoạn lớn, chuyến phiêu lưu trong ngày,
/// lối vào Tủ đồ (ngoại hình thú cưng) và Trang trí phòng.
struct CornerView: View {
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(DayClock.self) private var dayClock
    @State private var shopSlot: ItemSlot?
    @State private var showShop = false
    @State private var showWardrobe = false
    @State private var showAdventure = false
    @State private var showMemories = false
    @State private var editingName = false
    @State private var nameDraft = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    RoomView(
                        equipped: store.equippedMap,
                        appearance: store.petAppearance,
                        petMood: ui.petMood(store: store),
                        petName: store.profile.displayPetName,
                        bounceTrigger: ui.celebrateCounter,
                        haptics: store.profile.hapticsEnabled,
                        speech: { tap in PetDialogue.line(for: store.petDialogueContext(today: dayClock.today), tap: tap) },
                        onTapSlot: { slot in
                            shopSlot = slot
                            showShop = true
                        }
                    )

                    Text("Chạm vào \(store.profile.displayPetName) để vuốt ve, chạm vào một vị trí trong phòng để chọn đồ.")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.inkMuted)

                    levelCard
                    AdventureCard(showStory: $showAdventure, showMemories: $showMemories)

                    HStack(spacing: Spacing.m) {
                        Button {
                            showWardrobe = true
                        } label: {
                            Label("Tủ đồ", systemImage: "tshirt")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        Button {
                            shopSlot = nil
                            showShop = true
                        } label: {
                            Label("Trang trí phòng", systemImage: "sofa")
                        }
                        .buttonStyle(SoftButtonStyle(tint: Palette.lavender))
                    }
                }
                .padding(Spacing.l)
            }
            .cozyBackground()
            .navigationTitle("Góc nhỏ")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { SettingsButton() }
            }
            .sheet(isPresented: $showShop) {
                ShopView(initialSlot: shopSlot)
            }
            .sheet(isPresented: $showWardrobe) {
                WardrobeView()
            }
            .sheet(isPresented: $showAdventure) {
                AdventureStorySheet(day: dayClock.today)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showMemories) {
                MemoryBookView()
            }
            .task {
                // Chỉ khi CI chụp ảnh giao diện (bản Debug).
                guard let screen = PreviewMode.current else { return }
                try? await Task.sleep(nanoseconds: 600_000_000)
                switch screen {
                case .shop: showShop = true
                case .wardrobe: showWardrobe = true
                case .adventure: showAdventure = true
                case .memories: showMemories = true
                default: break
                }
            }
            .alert("Đổi tên thú cưng", isPresented: $editingName) {
                TextField("Tên", text: $nameDraft)
                Button("Lưu") {
                    let name = nameDraft
                    ui.run { try store.updateProfile { $0.petName = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(30)) } }
                }
                Button("Hủy", role: .cancel) {}
            }
        }
    }

    private var levelCard: some View {
        let wallet = store.wallet
        let stage = PetStage.forLevel(wallet.level)
        return CozyCard {
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack {
                    Text(store.profile.displayPetName)
                        .font(Typography.title)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                    Button {
                        nameDraft = store.profile.petName
                        editingName = true
                    } label: {
                        Image(systemName: "pencil")
                            .frame(width: HitTarget.min, height: HitTarget.min)
                    }
                    .accessibilityLabel("Đổi tên thú cưng")
                    Spacer()
                    Text("Cấp \(wallet.level)")
                        .font(Typography.headline)
                        .foregroundStyle(Palette.lavender)
                    CoinBadge(coins: wallet.coins)
                }
                ProgressView(value: wallet.levelProgress)
                    .tint(Palette.lavender)
                    .accessibilityLabel("Tiến độ lên cấp")
                    .accessibilityValue("\(wallet.xpIntoLevel) trên \(RewardConfig.xpPerLevel) XP")
                Text("\(wallet.xpIntoLevel)/\(RewardConfig.xpPerLevel) XP tới cấp \(wallet.level + 1) · tổng \(wallet.xp) XP")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.inkMuted)
                Label {
                    if let next = stage.next {
                        Text("\(stage.label) — lớn thành \"\(next.label)\" ở cấp \(next.startLevel)")
                    } else {
                        Text(stage.label)
                    }
                } icon: {
                    Image(systemName: "leaf")
                }
                .font(Typography.callout.weight(.semibold))
                .foregroundStyle(Palette.sage)
                Text("\(store.profile.displayPetName) \(ui.petMood(store: store).label). Thú cưng không bao giờ ốm hay giận khi bạn nghỉ vài ngày.")
                    .font(Typography.callout)
                    .foregroundStyle(Palette.ink)
            }
        }
    }
}

struct ShopView: View {
    var initialSlot: ItemSlot?
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss
    @State private var slot: ItemSlot = .desk
    @State private var preview: CatalogItem?
    @State private var buying = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    HStack {
                        Picker("Vị trí", selection: $slot) {
                            ForEach(ItemSlot.room) { Text($0.label).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(Palette.lavender)
                        Spacer()
                        CoinBadge(coins: store.wallet.coins)
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: Spacing.m)], spacing: Spacing.m) {
                        ForEach(Catalog.items(in: slot)) { item in
                            itemCard(item)
                        }
                    }

                    if store.equippedItem(in: slot) != nil {
                        Button("Bỏ đồ ở vị trí này") {
                            ui.run { try store.unequip(slot: slot) }
                        }
                        .buttonStyle(SoftButtonStyle(tint: Palette.inkMuted))
                    }
                }
                .padding(Spacing.l)
            }
            .cozyBackground()
            .navigationTitle("Cửa hàng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Xong") { dismiss() } }
            }
            .sheet(item: $preview) { item in
                ItemPreviewSheet(item: item)
                    .presentationDetents([.medium, .large])
            }
            .overlay(alignment: .top) { ErrorOverlay() }
        }
        .onAppear { if let initialSlot, !initialSlot.isPet { slot = initialSlot } }
    }

    private func itemCard(_ item: CatalogItem) -> some View {
        let owned = store.ownedIDs.contains(item.id)
        let equipped = store.equippedItem(in: item.slot)?.id == item.id
        return Button { preview = item } label: {
            VStack(alignment: .leading, spacing: Spacing.s) {
                ItemArt(itemID: item.id)
                    .frame(height: 90)
                    .frame(maxWidth: .infinity)
                    .background(Palette.roomWall, in: RoundedRectangle(cornerRadius: Radius.m))
                Text(item.name)
                    .font(Typography.headline)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(equipped ? "Đang dùng" : owned ? "Đã có" : item.isFree ? "Miễn phí" : "\(item.price) xu")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(equipped ? Palette.sage : owned ? Palette.inkMuted : Palette.honey)
            }
            .padding(Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.l))
            .overlay(RoundedRectangle(cornerRadius: Radius.l).strokeBorder(equipped ? Palette.sage : Palette.line, lineWidth: equipped ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Xem trước")
    }
}

struct ItemPreviewSheet: View {
    let item: CatalogItem
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss
    @State private var working = false

    var body: some View {
        let owned = store.ownedIDs.contains(item.id)
        let equipped = store.equippedItem(in: item.slot)?.id == item.id
        let coins = store.wallet.coins
        VStack(spacing: Spacing.l) {
            ItemArt(itemID: item.id)
                .frame(width: 160, height: 160)
                .background(Palette.roomWall, in: RoundedRectangle(cornerRadius: Radius.l))
            VStack(spacing: Spacing.xs) {
                Text(item.name).font(Typography.title).foregroundStyle(Palette.ink)
                Text(item.blurb).font(Typography.callout).foregroundStyle(Palette.inkMuted).multilineTextAlignment(.center)
                Text("\(item.slot.label) · \(item.isFree ? "Miễn phí" : "\(item.price) xu")")
                    .font(Typography.caption).foregroundStyle(Palette.inkMuted)
            }
            if equipped {
                Label("Đang dùng trong phòng", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Palette.sage)
                    .frame(minHeight: HitTarget.min)
            } else if owned {
                Button("Đặt vào phòng") {
                    ui.run { try store.equip(itemID: item.id) }
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle(color: Palette.sage))
            } else if coins >= item.price {
                Button(item.isFree ? "Nhận miễn phí" : "Mua với \(item.price) xu") {
                    guard !working else { return }
                    working = true
                    let ok = ui.run { try store.buy(itemID: item.id) }
                    working = false
                    if ok {
                        ui.showReward(item.isFree ? "Đã nhận \(item.name)" : "Đã mua \(item.name)")
                        dismiss()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(working)
            } else {
                Text("Cần thêm \(item.price - coins) xu. Hoàn thành việc hoặc phiên tập trung để nhận xu.")
                    .font(Typography.callout)
                    .foregroundStyle(Palette.inkMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cozyBackground()
    }
}
