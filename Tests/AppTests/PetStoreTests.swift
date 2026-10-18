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

    func testWardrobeDefaultsLevelLockAndEquipSurviveRelaunch() throws {
        let (store, container) = try makeStore()
        XCTAssertEqual(store.petAppearance.species, .cat)
        XCTAssertEqual(store.petItemInUse(.fur), "fur.cream")

        try completeTasks(store, count: 10) // 100 XP → cấp 2, 50 xu
        XCTAssertEqual(store.wallet.level, 2)
        XCTAssertThrowsError(try store.buy(itemID: "species.fox")) // cấp 6
        XCTAssertEqual(store.wallet.coins, 50)

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
        XCTAssertEqual(relaunched.wallet.coins, 50 - 30)

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
