import XCTest
#if canImport(CozyCore)
@testable import CozyCore
#else
@testable import Cozyday
#endif

final class RewardAndShopTests: XCTestCase {
    func testTaskRewardOnlyOncePerOccurrence() {
        let occ = makeOneOff()
        var ledger: [LedgerEntry] = []
        // Bấm nhanh 3 lần / bỏ hoàn thành rồi hoàn thành lại
        for _ in 0..<3 {
            if let entry = RewardPolicy.forTaskCompletion(occurrence: occ, existingKeys: Set(ledger.map(\.key)), now: Date()) {
                ledger.append(entry)
            }
        }
        XCTAssertEqual(ledger.count, 1)
        XCTAssertEqual(Wallet(entries: ledger), Wallet(xp: RewardConfig.taskXP, coins: RewardConfig.taskCoins))
    }

    func testFocusRewardNeedsMinimumAndIsCapped() {
        XCTAssertEqual(RewardConfig.focusReward(plannedMinutes: 5).xp, 0)
        XCTAssertEqual(RewardConfig.focusReward(plannedMinutes: 25).xp, 10)
        XCTAssertEqual(RewardConfig.focusReward(plannedMinutes: 25).coins, 10)
        XCTAssertEqual(RewardConfig.focusReward(plannedMinutes: 500).xp, RewardConfig.focusReward(plannedMinutes: 120).xp)
        let id = UUID()
        let first = RewardPolicy.forFocus(sessionID: id, plannedMinutes: 25, existingKeys: [], now: Date())
        XCTAssertNotNil(first)
        XCTAssertNil(RewardPolicy.forFocus(sessionID: id, plannedMinutes: 25, existingKeys: [first!.key], now: Date()))
    }

    func testJournalRewardOncePerDay() {
        let d = day("2026-10-18")
        let first = RewardPolicy.forJournal(day: d, existingKeys: [], now: Date())!
        XCTAssertNil(RewardPolicy.forJournal(day: d, existingKeys: [first.key], now: Date()))
        XCTAssertNotNil(RewardPolicy.forJournal(day: d.adding(days: 1, calendar: cal()), existingKeys: [first.key], now: Date()))
    }

    func testCatalogHasFixedUniqueIDsAndFreeItems() {
        XCTAssertEqual(Set(Catalog.items.map(\.id)).count, Catalog.items.count)
        XCTAssertGreaterThanOrEqual(Catalog.roomItems.count, 100)
        XCTAssertGreaterThanOrEqual(Catalog.petItems.count, 80)
        // Mỗi phòng có tường & sàn mặc định và mỗi vị trí đồ có vị trí trong một phòng.
        for room in RoomKind.allCases {
            XCTAssertEqual(room.slots.first, room.themeSlot)
            XCTAssertNotNil(Catalog.defaultItem(for: room.themeSlot))
        }
        for slot in ItemSlot.allCases {
            XCTAssertTrue(slot.isPet != (slot.roomKind != nil), "slot \(slot) phải thuộc đúng một nơi")
        }
        // Đồ trong phòng chưa mở không thể mua sớm hơn cấp mở phòng.
        for item in Catalog.roomItems {
            guard let room = item.slot.roomKind else { continue }
            XCTAssertGreaterThanOrEqual(item.requiredLevel, room.requiredLevel, item.id)
        }
        XCTAssertGreaterThanOrEqual(Catalog.items.filter(\.isFree).count, 3)
        XCTAssertTrue(Catalog.items.allSatisfy { $0.id.hasPrefix($0.slot.rawValue + ".") }, "ID phải bắt đầu bằng tên vị trí")
        for slot in ItemSlot.allCases where slot.hasDefault {
            XCTAssertNotNil(Catalog.defaultItem(for: slot))
        }
        for slot in ItemSlot.allCases {
            XCTAssertFalse(Catalog.items(in: slot).isEmpty, "slot \(slot) trống")
        }
    }

    func testPetLooksUseRealItemsOnePerSlotAndCoverEverySpecies() {
        XCTAssertEqual(Set(PetLooks.all.map(\.id)).count, PetLooks.all.count)
        for look in PetLooks.all {
            let items = look.itemIDs.map { Catalog.item($0) }
            XCTAssertFalse(items.contains(nil), "\(look.id) có món không tồn tại")
            let slots = items.compactMap { $0?.slot }
            XCTAssertEqual(Set(slots).count, slots.count, "\(look.id) có hai món cùng vị trí")
            XCTAssertTrue(slots.allSatisfy(\.isPet), look.id)
            let a = look.appearance(stage: .grown)
            XCTAssertEqual(Set(a.itemIDs), Set(look.itemIDs), look.id)
        }
        XCTAssertEqual(Set(PetLooks.all.map(\.species)), Set(PetSpecies.allCases))
        // Mọi món thú cưng đều xuất hiện trong ít nhất một bộ hoặc là hình dạng/màu lông.
        let used = Set(PetLooks.all.flatMap(\.itemIDs))
        let unused = Catalog.petItems.filter { ![.species, .fur].contains($0.slot) && !used.contains($0.id) }.map(\.id)
        XCTAssertTrue(unused.count <= 12, "nhiều món chưa có trong bộ nào: \(unused)")
    }

    func testNewSpeciesShapesAreInCatalogWithRarityAndLooks() {
        let shapes: [PetSpecies] = [.ghost, .slime, .mushroom, .shark, .owl, .dragon, .unicorn]
        for s in shapes {
            let item = Catalog.item("species." + s.rawValue)
            XCTAssertNotNil(item, s.rawValue)
            XCTAssertEqual(item?.slot, .species)
            XCTAssertGreaterThan(item?.price ?? 0, 0, "không được miễn phí: \(s)")
            XCTAssertFalse(s.name.isEmpty)
            XCTAssertTrue(PetLooks.all.contains { $0.species == s }, "thiếu bộ phối đồ cho \(s)")
            XCTAssertEqual(PetAppearance(equipped: [.species: "species." + s.rawValue], level: 1).species, s)
        }
        // Rồng con và kỳ lân chỉ có trong gacha; các loài còn lại mua được.
        XCTAssertEqual(Catalog.item("species.dragon")?.gachaOnly, true)
        XCTAssertEqual(Catalog.item("species.dragon")?.rarity, .epic)
        XCTAssertEqual(Catalog.item("species.unicorn")?.gachaOnly, true)
        XCTAssertEqual(Catalog.item("species.unicorn")?.rarity, .secret)
        XCTAssertEqual(Catalog.item("species.ghost")?.rarity, .rare)
        for s in shapes where s != .dragon && s != .unicorn {
            XCTAssertEqual(Catalog.item("species." + s.rawValue)?.gachaOnly, false, s.rawValue)
        }
        let reward = LedgerEntry(id: UUID(), key: "task:x", kind: .taskCompleted, xp: 10_000, coins: 10_000, createdAt: Date(), refID: nil, memo: "")
        XCTAssertEqual(PurchasePolicy.decide(itemID: "species.unicorn", owned: [], ledger: [reward], now: Date()), .gachaOnly)
    }

    func testLookCostAndProgress() {
        let look = PetLook(id: "t", name: "t", species: .bunny, fur: .cream, items: ["hat.bow", "neck.bell"])
        XCTAssertEqual(look.cost(owned: []), 60 + 20 + 30)
        XCTAssertEqual(look.cost(owned: ["species.bunny"]), 50)
        XCTAssertEqual(look.requiredLevel, 2)
        let progress = CollectionProgress(owned: ["hat.bow", "desk.pine"])
        XCTAssertEqual(progress.ownedPetItems, 1)
        XCTAssertEqual(progress.ownedRoomItems, 1)
    }

    func testPurchaseRules() {
        let reward = LedgerEntry(id: UUID(), key: "task:x", kind: .taskCompleted, xp: 10, coins: 30, createdAt: Date(), refID: nil, memo: "")
        var ledger = [reward]
        var owned: Set<String> = []

        // Thiếu xu
        XCTAssertEqual(
            PurchasePolicy.decide(itemID: "lamp.desk", owned: owned, ledger: ledger, now: Date()),
            .insufficientCoins(needed: 45, available: 30)
        )
        // Mua được
        guard case .approved(let entry) = PurchasePolicy.decide(itemID: "lamp.candle", owned: owned, ledger: ledger, now: Date()) else {
            return XCTFail("phải mua được")
        }
        ledger.append(entry)
        owned.insert("lamp.candle")
        XCTAssertEqual(Wallet(entries: ledger).coins, 10)
        // Bấm mua lần nữa (kể cả khi inventory chưa kịp cập nhật) → không trừ lần 2
        XCTAssertEqual(PurchasePolicy.decide(itemID: "lamp.candle", owned: [], ledger: ledger, now: Date()), .alreadyOwned)
        XCTAssertEqual(PurchasePolicy.decide(itemID: "lamp.candle", owned: owned, ledger: ledger, now: Date()), .alreadyOwned)
        XCTAssertEqual(Wallet(entries: ledger).coins, 10)
        // Đồ miễn phí
        guard case .approved(let free) = PurchasePolicy.decide(itemID: "desk.pine", owned: owned, ledger: ledger, now: Date()) else {
            return XCTFail("đồ miễn phí phải nhận được")
        }
        XCTAssertEqual(free.coins, 0)
        XCTAssertEqual(PurchasePolicy.decide(itemID: "nope", owned: owned, ledger: ledger, now: Date()), .unknownItem)
    }

    func testLevelProgress() {
        let w = Wallet(xp: 250, coins: 0)
        XCTAssertEqual(w.level, 3)
        XCTAssertEqual(w.xpIntoLevel, 50)
    }
}
