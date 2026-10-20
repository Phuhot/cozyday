import XCTest
import SwiftData
@testable import Cozyday

/// Thú cưng: tủ đồ (mặc định, mở khóa theo cấp), chuyến phiêu lưu (thưởng một lần), bài thở.
@MainActor
final class PetStoreTests: XCTestCase {
    private var clock: ManualClock!
    private var calendar: Calendar!

    override func setUp() async throws {
        calendar = Calendar.gregorian(timeZone: TimeZone(identifier: "Asia/Ho_Chi_Minh")!)
        clock = ManualClock(calendar.date(from: DateComponents(year: 2026, month: 10, day: 18, hour: 9))!)
    }

    private func makeStore(_ container: ModelContainer? = nil) throws -> (AppStore, ModelContainer) {
        let c = try container ?? PersistenceController.makeContainer(inMemory: true)
        return (try AppStore(container: c, clock: clock, calendar: calendar), c)
    }

    private func completeTasks(_ store: AppStore, count: Int) throws {
        for i in 0..<count {
            var d = TaskDraft()
            d.title = "Việc \(i)"
            d.day = store.today
            d.startMinute = 8 * 60 + i * 30
            d.durationMinutes = 20
            let id = try XCTUnwrap(store.createTask(d))
            try store.setStatus(id: id, to: .done)
        }
    }

    func testWearLookBuysMissingAllOrNothingAndReplacesOutfit() throws {
        let (store, container) = try makeStore()
        try completeTasks(store, count: 10) // cấp 2, 80 xu
        let look = PetLook(id: "t", name: "Thử", species: .cat, fur: .ginger, items: ["hat.sprout", "neck.bowtie"])
        // 30 (ginger) + 0 (sprout) + 20 (bowtie) = 50 xu, vừa đủ.
        try store.buy(itemID: "glasses.round") // 30 xu
        try store.equip(itemID: "glasses.round")
        try store.buy(itemID: "lamp.candle") // 20 xu → còn 30, không đủ mua cả bộ
        XCTAssertThrowsError(try store.wearLook(look))
        XCTAssertFalse(store.ownedIDs.contains("fur.ginger"), "thiếu xu thì không mua món nào")
        XCTAssertEqual(store.wallet.coins, 30)

        clock.advance(seconds: 86_400) // hôm nay đã hết hạn mức 10 việc có thưởng
        try completeTasks(store, count: 3) // +24 xu → 54
        let spent = try store.wearLook(look)
        XCTAssertEqual(spent, 50)
        XCTAssertEqual(store.wallet.coins, 4)
        XCTAssertEqual(store.petAppearance.fur, .ginger)
        XCTAssertEqual(store.petAppearance.hat, "hat.sprout")
        XCTAssertNil(store.petAppearance.glasses, "món không thuộc bộ được tháo ra")
        XCTAssertTrue(store.ownedIDs.contains("glasses.round"))

        // Bộ cần cấp cao hơn → báo lỗi, không đổi gì.
        XCTAssertThrowsError(try store.wearLook(PetLooks.look("look.penguinspace")!))
        let (relaunched, _) = try makeStore(container)
        XCTAssertEqual(relaunched.petAppearance.neck, "neck.bowtie")
        XCTAssertEqual(relaunched.wallet.coins, 4)
    }

    func testRoomItemsNeedRoomLevelAndThemeDefaults() throws {
        let (store, _) = try makeStore()
        XCTAssertEqual(store.equippedItem(in: .bedroomTheme), nil)
        XCTAssertTrue(Catalog.isOwned("bedroomTheme.lilac", owned: store.ownedIDs))
        try store.buy(itemID: "bed.mat") // phòng ngủ mở từ cấp 1, đồ miễn phí
        XCTAssertEqual(store.equippedItem(in: .bed)?.id, "bed.mat")
        XCTAssertThrowsError(try store.buy(itemID: "stove.basic"), "bếp mở ở cấp 2")
    }

    func testWardrobeDefaultsLevelLockAndEquipSurviveRelaunch() throws {
        let (store, container) = try makeStore()
        XCTAssertEqual(store.petAppearance.species, .cat)
        XCTAssertEqual(store.petItemInUse(.fur), "fur.cream")

        try completeTasks(store, count: 10) // 100 XP → cấp 2, 80 xu
        XCTAssertEqual(store.wallet.level, 2)
        XCTAssertThrowsError(try store.buy(itemID: "species.fox")) // cấp 6
        XCTAssertEqual(store.wallet.coins, 80)

        try store.buy(itemID: "fur.ginger")
        try store.equip(itemID: "fur.ginger")
        try store.buy(itemID: "hat.sprout")
        try store.equip(itemID: "hat.sprout")
        XCTAssertEqual(store.petAppearance.fur, .ginger)
        XCTAssertEqual(store.petAppearance.hat, "hat.sprout")

        // Chọn lại món mặc định = bỏ trống vị trí, không ghi gì vào kho
        try store.equip(itemID: "fur.cream")
        XCTAssertEqual(store.petAppearance.fur, .cream)
        XCTAssertFalse(store.ownedIDs.contains("fur.cream"))
        try store.equip(itemID: "fur.ginger")

        let (relaunched, _) = try makeStore(container)
        XCTAssertEqual(relaunched.petAppearance.fur, .ginger)
        XCTAssertEqual(relaunched.petAppearance.hat, "hat.sprout")
        XCTAssertEqual(relaunched.wallet.coins, 80 - 30)

        // Sao lưu có trang phục thú cưng vẫn hợp lệ và khôi phục được
        let data = try BackupCodec.encode(relaunched.makeBackup())
        let restored = try BackupCodec.decodeAndValidate(data)
        XCTAssertTrue(restored.equipped.contains { $0.slot == .fur && $0.itemID == "fur.ginger" })
    }

    func testAdventureNeedsFullEnergyAndRewardsOncePerDay() throws {
        let (store, container) = try makeStore()
        try completeTasks(store, count: 3)
        XCTAssertEqual(store.adventureEnergy(on: store.today), 75)
        XCTAssertThrowsError(try store.claimAdventure(day: store.today))

        XCTAssertNotNil(try store.completeBreathing(day: store.today))
        XCTAssertNil(try store.completeBreathing(day: store.today), "bài thở chỉ thưởng một lần mỗi ngày")
        XCTAssertEqual(store.adventureEnergy(on: store.today), 100)

        let coinsBefore = store.wallet.coins
        XCTAssertNotNil(try store.claimAdventure(day: store.today))
        XCTAssertNil(try store.claimAdventure(day: store.today))
        XCTAssertEqual(store.wallet.coins, coinsBefore + RewardConfig.adventureCoins)

        let (relaunched, _) = try makeStore(container)
        XCTAssertNil(try relaunched.claimAdventure(day: relaunched.today))
        XCTAssertEqual(relaunched.adventureMemories.count, 1)
        XCTAssertEqual(relaunched.adventureMemories.first?.day, relaunched.today)
    }
}
