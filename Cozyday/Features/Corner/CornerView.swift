import SwiftUI

/// Tab "Góc nhỏ": thú cưng trong các căn phòng (phòng học, phòng ngủ, bếp, phòng tắm, vườn), cấp độ & giai đoạn lớn,
/// chuyến phiêu lưu trong ngày, lối vào Tủ đồ, Bộ sưu tập và Trang trí.
struct CornerView: View {
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(DayClock.self) private var dayClock
    /// Phòng đang xem — chỉ là tiện ích hiển thị trên máy này, không phải dữ liệu cần sao lưu.
    @AppStorage("corner.room") private var roomRaw = RoomKind.study.rawValue
    @State private var shopTarget: ShopTarget?
    @State private var showWardrobe = false
    @State private var showAvatar = false
    @State private var showCollection = false
    @State private var showAdventure = false
    @State private var showMemories = false
    @State private var editingName = false
    @State private var nameDraft = ""
    @State private var showPlayground = false
    @State private var foodTab: FoodSheet.Tab?
    @State private var cleaning: CleanSession?
    @State private var cuddle = CuddleProgress()
    @State private var cuddleDoneAt: TimeInterval = 0

    /// Một lượt dọn nhà: mã hành động cố định cho cả lượt (thử lại sau lỗi lưu không làm hai lần).
    struct CleanSession: Equatable {
        let id = UUID()
        let spots: [(x: Double, y: Double, kind: Int)]
        var cleared: Set<Int> = []
        var saveFailed = false

        static func == (a: CleanSession, b: CleanSession) -> Bool { a.id == b.id && a.cleared == b.cleared && a.saveFailed == b.saveFailed }
        var isDone: Bool { cleared.count >= spots.count }
    }

    private var room: RoomKind { RoomKind(rawValue: roomRaw) ?? .study }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    RoomPicker(selection: Binding(get: { room }, set: { roomRaw = $0.rawValue }), level: store.wallet.level)

                    roomArea

                    if let cleaning {
                        cleanBar(cleaning)
                    } else {
                        Text("Chạm để vuốt ve, vuốt qua lại để nựng, giữ rồi kéo để đưa \(store.profile.displayPetName) sang chỗ khác. Chạm một ô trong phòng để chọn đồ.")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.inkMuted)
                    }

                    PlaygroundEntryCard { showPlayground = true }
                    AvatarEntryCard { showAvatar = true }

                    NeedsCard(cuddleFraction: cuddle.fraction,
                              onFeed: { foodTab = .tray },
                              onClean: startCleaning,
                              onCuddle: { finishCare(.cuddle, id: UUID()) })
                        .id("needs")

                    HStack(spacing: Spacing.s) {
                        Button {
                            showWardrobe = true
                        } label: {
                            Label("Tủ đồ", systemImage: "tshirt")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        Button {
                            showCollection = true
                        } label: {
                            Label("Bộ sưu tập", systemImage: "square.grid.3x3")
                        }
                        .buttonStyle(PrimaryButtonStyle(color: Palette.peach))
                    }
                    Button {
                        shopTarget = ShopTarget(room: room.isUnlocked(level: store.wallet.level) ? room : .study, slot: nil)
                    } label: {
                        Label("Trang trí \(room.name.lowercased())", systemImage: "sofa")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SoftButtonStyle(tint: Palette.lavender))

                    levelCard
                    PetWeekCard()
                    AdventureCard(showStory: $showAdventure, showMemories: $showMemories)
                }
                .padding(Spacing.l)
            }
            .scrollDisabled(cleaning != nil)
            .task {
                // Ảnh xem trước (Debug): cuộn tới thẻ chăm sóc.
                guard PreviewMode.current == .care else { return }
                try? await Task.sleep(nanoseconds: 700_000_000)
                proxy.scrollTo("needs", anchor: .center)
            }
            }
            .cozyBackground()
            .navigationTitle("Góc nhỏ")
            .navigationDestination(isPresented: $showPlayground) { PlaygroundView() }
            .sheet(item: $foodTab) { tab in
                FoodSheet(initialTab: tab)
                    .presentationDetents([.large])
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { SettingsButton() }
            }
            .sheet(item: $shopTarget) { target in
                ShopView(initialRoom: target.room, initialSlot: target.slot)
            }
            .sheet(isPresented: $showAvatar) {
                AvatarStudioView()
            }
            .sheet(isPresented: $showWardrobe) {
                WardrobeView()
            }
            .sheet(isPresented: $showCollection) {
                PetCollectionView()
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
                switch screen {
                case .bedroom: roomRaw = RoomKind.bedroom.rawValue
                case .kitchen: roomRaw = RoomKind.kitchen.rawValue
                case .bath: roomRaw = RoomKind.bath.rawValue
                case .garden: roomRaw = RoomKind.garden.rawValue
                default: roomRaw = RoomKind.study.rawValue
                }
                try? await Task.sleep(nanoseconds: 600_000_000)
                switch screen {
                case .food: foodTab = .shop
                case .feed, .careCapped: foodTab = .tray
                case .clean:
                    startCleaning()
                    cleaning?.cleared = [0, 2, 4]
                case .playground, .pickPet, .tutorial, .jump, .basket, .memory, .pause, .result, .resultCapped: showPlayground = true
                default: break
                }
                switch screen {
                case .shop: shopTarget = ShopTarget(room: .bedroom, slot: .bed)
                case .wardrobe: showWardrobe = true
                case .avatar, .avatarOutfit: showAvatar = true
                case .adventure: showAdventure = true
                case .memories: showMemories = true
                case .collection, .look: showCollection = true
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

    @ViewBuilder
    private var roomArea: some View {
        let level = store.wallet.level
        if room.isUnlocked(level: level) {
            RoomView(
                room: room,
                equipped: store.equippedMap,
                appearance: store.petAppearance,
                petMood: ui.petMood(store: store),
                petName: store.profile.displayPetName,
                bounceTrigger: ui.celebrateCounter,
                haptics: store.profile.hapticsEnabled,
                speech: { tap in PetDialogue.line(for: store.petDialogueContext(today: dayClock.today), tap: tap, species: store.petAppearance.species) },
                onTapSlot: { slot in shopTarget = ShopTarget(room: room, slot: slot) },
                onStroke: stroked
            )
            .allowsHitTesting(cleaning == nil)
            .overlay {
                if let session = cleaning {
                    CleanModeLayer(spots: session.spots,
                                   cleared: Binding(get: { cleaning?.cleared ?? [] }, set: { cleaning?.cleared = $0 }),
                                   haptics: store.profile.hapticsEnabled)
                } else {
                    DustLayer(cleanliness: store.currentNeeds.cleanliness)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
            .onChange(of: cleaning?.cleared.count) { _, _ in
                if let session = cleaning, session.isDone, !session.saveFailed { saveCleaning() }
            }
        } else {
            RoomView(room: room, equipped: [:], appearance: store.petAppearance, petMood: .rest,
                     petName: store.profile.displayPetName, bounceTrigger: 0)
                .blur(radius: 3)
                .overlay {
                    VStack(spacing: Spacing.s) {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundStyle(Palette.lavender)
                        Text("\(room.name) mở ở cấp \(room.requiredLevel)")
                            .font(Typography.headline)
                            .foregroundStyle(Palette.ink)
                        Text("Còn \(max(0, (room.requiredLevel - 1) * RewardConfig.xpPerLevel - store.wallet.xp)) XP nữa. Hoàn thành việc, tập trung hoặc viết nhật ký để lên cấp.")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.inkMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Spacing.l)
                    .background(Palette.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
                    .padding(Spacing.xl)
                }
                .accessibilityElement(children: .combine)
        }
    }

    // MARK: Chăm sóc

    private func startCleaning() {
        let level = store.wallet.level
        guard room.isUnlocked(level: level) else { roomRaw = RoomKind.study.rawValue; return }
        let c = store.currentNeeds.cleanliness
        guard c < CareConfig.cleanEnough else {
            ui.errorMessage = CareError.alreadyClean.errorDescription
            return
        }
        let count = CleanPlan.spotCount(cleanliness: c)
        cleaning = CleanSession(spots: CleanPlan.spots(count: count, seed: UInt64.random(in: 1...UInt64.max)))
    }

    private func saveCleaning() {
        guard let session = cleaning else { return }
        if finishCare(.clean, id: session.id) {
            cleaning = nil
        } else {
            cleaning?.saveFailed = true
        }
    }

    /// Lưu một hành động chăm sóc; chỉ báo kết quả khi lưu thành công.
    @discardableResult
    private func finishCare(_ kind: CareActionKind, id: UUID) -> Bool {
        do {
            let record = try store.performCare(kind, actionID: id)
            let name = store.profile.displayPetName
            let line = CareDialogue.done(kind, petName: name, alreadyFine: record.note == .notNeeded)
            let note = CareDialogue.rewardNote(record)
            ui.showReward(note.isEmpty ? line : "\(line)\n\(note)")
            return true
        } catch {
            ui.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    /// Vuốt trên người thú cưng: cộng thời gian vuốt thật; đủ ~3,5 giây là xong một lượt nựng.
    private func stroked() {
        let now = ProcessInfo.processInfo.systemUptime
        // Vừa nựng xong: nghỉ 2 giây trước khi tính lượt mới (tránh popup dồn dập khi vuốt liên tục).
        guard now - cuddleDoneAt > 2 else { return }
        if cuddle.stroke(at: now) {
            cuddle.reset()
            cuddleDoneAt = now
            finishCare(.cuddle, id: UUID())
        }
    }

    private func cleanBar(_ session: CleanSession) -> some View {
        CozyCard(padding: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack {
                    Label("Dọn nhà: \(session.cleared.count)/\(session.spots.count)", systemImage: "sparkles")
                        .font(Typography.headline)
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    ProgressView(value: Double(session.cleared.count), total: Double(max(1, session.spots.count)))
                        .tint(Palette.sage)
                        .frame(maxWidth: 110)
                        .accessibilityHidden(true)
                }
                Text(session.saveFailed ? "Chưa lưu được. Thử lưu lại nhé — không bị tính hai lần."
                     : "Chạm hoặc vuốt qua bụi, lá khô và giấy vụn. Dọn ở đây là dọn cả nhà.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Spacing.s) {
                    if session.saveFailed {
                        Button("Thử lưu lại") { saveCleaning() }
                            .buttonStyle(PrimaryButtonStyle(color: Palette.sage))
                    } else {
                        Button {
                            cleaning?.cleared = Set(session.spots.indices)
                        } label: {
                            Label("Dọn nhanh", systemImage: "wand.and.stars").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle(color: Palette.sage))
                        .accessibilityHint("Dọn hết bụi một lần, nhận kết quả như khi tự tay dọn")
                    }
                    Button("Thôi") { cleaning = nil }
                        .buttonStyle(SoftButtonStyle(tint: Palette.inkMuted))
                        .accessibilityHint("Thoát chế độ dọn, không lưu")
                }
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
                Text("\(store.profile.displayPetName) \(ui.petMood(store: store).label). Thú cưng không bao giờ ốm, bỏ đi hay giận khi bạn bận vài ngày.")
                    .font(Typography.callout)
                    .foregroundStyle(Palette.ink)
            }
        }
    }
}

/// Mở cửa hàng ở một phòng / vị trí cụ thể.
struct ShopTarget: Identifiable {
    var room: RoomKind
    var slot: ItemSlot?
    var id: String { room.rawValue + (slot?.rawValue ?? "") }
}

/// Hàng chọn phòng: phòng chưa mở hiện ổ khóa và cấp cần đạt.
struct RoomPicker: View {
    @Binding var selection: RoomKind
    let level: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                ForEach(RoomKind.allCases) { room in
                    let unlocked = room.isUnlocked(level: level)
                    let isOn = selection == room
                    Button {
                        selection = room
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: unlocked ? room.symbol : "lock.fill")
                            Text(room.name)
                            if !unlocked {
                                Text("Cấp \(room.requiredLevel)").font(Typography.caption2)
                            }
                        }
                        .font(Typography.callout.weight(.semibold))
                        .padding(.horizontal, Spacing.m)
                        .frame(minHeight: HitTarget.min)
                        .foregroundStyle(isOn ? Palette.onAccent : (unlocked ? Palette.ink : Palette.inkMuted))
                        .background(isOn ? Palette.lavender : Palette.surface, in: Capsule())
                        .overlay(Capsule().strokeBorder(isOn ? Color.clear : Palette.line))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(unlocked ? room.name : "\(room.name), mở ở cấp \(room.requiredLevel)")
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
            .padding(.vertical, 2)
        }
    }
}

/// "Tuần này của Bông": 7 cái đầu thú cưng, có màu ở ngày bạn có hoạt động, xám ở ngày nghỉ.
struct PetWeekCard: View {
    @Environment(AppStore.self) private var store
    @Environment(DayClock.self) private var dayClock

    var body: some View {
        let today = dayClock.today
        let days = today.adding(days: -6, calendar: store.calendar).through(today, calendar: store.calendar)
        let active = store.activeDays(in: days)
        let look = store.petAppearance
        CozyCard {
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack {
                    Text("Tuần này của \(store.profile.displayPetName)")
                        .font(Typography.headline)
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Text("\(active.count)/7 ngày")
                        .font(Typography.callout.weight(.semibold))
                        .foregroundStyle(Palette.sage)
                }
                HStack(spacing: 0) {
                    ForEach(days, id: \.self) { day in
                        let on = active.contains(day)
                        VStack(spacing: 2) {
                            PetArt(mood: on ? .happy : .rest, appearance: look)
                                .frame(width: 40, height: 40)
                                .saturation(on ? 1 : 0)
                                .opacity(on ? 1 : 0.4)
                            Text(DateText.weekdayShort(day, calendar: store.calendar))
                                .font(Typography.caption2.weight(.bold))
                                .foregroundStyle(on ? Palette.lavender : Palette.inkMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(DateText.full(day, calendar: store.calendar)): \(on ? "có hoạt động" : "nghỉ")")
                    }
                }
                Text(active.count >= 5 ? "Một tuần thật chăm chỉ! \(store.profile.displayPetName) vui lắm." :
                        "Ngày nghỉ cũng không sao — \(store.profile.displayPetName) vẫn chờ bạn.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.inkMuted)
            }
        }
    }
}

/// Cửa hàng trang trí: chọn phòng → vị trí → món đồ. Phòng chưa mở vẫn xem được đồ nhưng chưa mua được.
struct ShopView: View {
    var initialRoom: RoomKind = .study
    var initialSlot: ItemSlot?
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss
    @State private var room: RoomKind = .study
    @State private var slot: ItemSlot = .desk
    @State private var preview: CatalogItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    HStack {
                        RoomPicker(selection: $room, level: store.wallet.level)
                        CoinBadge(coins: store.wallet.coins)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.s) {
                            ForEach(room.slots) { s in
                                ChipToggle(title: s.label, isOn: slot == s, tint: Palette.peach) { slot = s }
                            }
                        }
                    }

                    if !room.isUnlocked(level: store.wallet.level) {
                        Label("\(room.name) mở ở cấp \(room.requiredLevel). Bạn vẫn xem trước được đồ.", systemImage: "lock.fill")
                            .font(Typography.callout)
                            .foregroundStyle(Palette.inkMuted)
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: slot.isTheme ? 160 : 104), spacing: Spacing.m)], spacing: Spacing.m) {
                        ForEach(Catalog.items(in: slot)) { item in
                            itemCard(item)
                        }
                    }

                    if store.equippedItem(in: slot) != nil, !slot.hasDefault {
                        Button("Bỏ đồ ở vị trí này") {
                            ui.run { try store.unequip(slot: slot) }
                        }
                        .buttonStyle(SoftButtonStyle(tint: Palette.inkMuted))
                    }
                }
                .padding(Spacing.l)
            }
            .cozyBackground()
            .navigationTitle("Trang trí")
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
        .onAppear {
            room = initialSlot?.roomKind ?? initialRoom
            slot = initialSlot ?? room.slots.first(where: { !$0.isTheme }) ?? room.themeSlot
        }
        .onChange(of: room) { _, newRoom in
            if slot.roomKind != newRoom { slot = newRoom.slots.first(where: { !$0.isTheme }) ?? newRoom.themeSlot }
        }
    }

    private func status(_ item: CatalogItem) -> (String, Color) {
        let inUse = (store.equippedItem(in: item.slot)?.id ?? Catalog.defaultItem(for: item.slot)?.id) == item.id
        if inUse { return ("Đang dùng", Palette.sage) }
        if Catalog.isOwned(item.id, owned: store.ownedIDs) { return ("Đã có", Palette.inkMuted) }
        if store.wallet.level < item.requiredLevel { return ("🔒 Cấp \(item.requiredLevel)", Palette.inkMuted) }
        return (item.isFree ? "Miễn phí" : "\(item.price) xu", Palette.honey)
    }

    private func itemCard(_ item: CatalogItem) -> some View {
        let (label, color) = status(item)
        let inUse = label == "Đang dùng"
        let locked = store.wallet.level < item.requiredLevel && !Catalog.isOwned(item.id, owned: store.ownedIDs)
        return Button { preview = item } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ItemArt(itemID: item.id)
                    .aspectRatio(item.slot.isTheme ? RoomLayout.aspect : 1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .padding(item.slot.isTheme ? 0 : Spacing.xs)
                    .background(Palette.roomWall, in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
                    .opacity(locked ? 0.55 : 1)
                Text(item.name)
                    .font(Typography.callout.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(label)
                    .font(Typography.caption.weight(.bold))
                    .foregroundStyle(color)
            }
            .padding(Spacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.l, style: .continuous).strokeBorder(inUse ? Palette.sage : Palette.line, lineWidth: inUse ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.name), \(label)")
        .accessibilityHint("Xem trước")
    }
}

struct ItemPreviewSheet: View {
    let item: CatalogItem
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss
    @State private var working = false

    private var trialEquipped: [ItemSlot: String] {
        var map = store.equippedMap
        map[item.slot] = item.id
        return map
    }

    var body: some View {
        let owned = Catalog.isOwned(item.id, owned: store.ownedIDs)
        let inUse = (store.equippedItem(in: item.slot)?.id ?? Catalog.defaultItem(for: item.slot)?.id) == item.id
        let coins = store.wallet.coins
        let level = store.wallet.level
        let roomLocked = !(item.slot.roomKind?.isUnlocked(level: level) ?? true)
        ScrollView {
            VStack(spacing: Spacing.l) {
                if let room = item.slot.roomKind {
                    // Xem trước ngay trong phòng.
                    RoomView(room: room, equipped: trialEquipped, appearance: store.petAppearance, petMood: .happy,
                             petName: store.profile.displayPetName, bounceTrigger: 0)
                } else {
                    ItemArt(itemID: item.id)
                        .frame(width: 160, height: 160)
                        .background(Palette.roomWall, in: RoundedRectangle(cornerRadius: Radius.l))
                }
                VStack(spacing: Spacing.xs) {
                    Text(item.name).font(Typography.title).foregroundStyle(Palette.ink)
                    Text(item.blurb).font(Typography.callout).foregroundStyle(Palette.inkMuted).multilineTextAlignment(.center)
                    Text("\(item.slot.roomKind?.name ?? "Thú cưng") · \(item.slot.label) · \(item.isFree ? "Miễn phí" : "\(item.price) xu")")
                        .font(Typography.caption).foregroundStyle(Palette.inkMuted)
                }
                if inUse {
                    Label("Đang dùng", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Palette.sage)
                        .frame(minHeight: HitTarget.min)
                } else if owned {
                    Button("Dùng món này") {
                        ui.run { try store.equip(itemID: item.id) }
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle(color: Palette.sage))
                } else if roomLocked || level < item.requiredLevel {
                    Label("Mở khóa ở cấp \(max(item.requiredLevel, item.slot.roomKind?.requiredLevel ?? 1)) (đang cấp \(level))", systemImage: "lock.fill")
                        .font(Typography.callout)
                        .foregroundStyle(Palette.inkMuted)
                        .frame(minHeight: HitTarget.min)
                } else if coins >= item.price {
                    Button(item.isFree ? "Nhận miễn phí" : "Mua với \(item.price) xu") {
                        guard !working else { return }
                        working = true
                        let ok = ui.run {
                            try store.buy(itemID: item.id)
                            try store.equip(itemID: item.id)
                        }
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cozyBackground()
    }
}
