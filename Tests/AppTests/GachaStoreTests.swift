import XCTest
import SwiftData
@testable import Cozyday

/// Máy gacha, mã quà, hạn mức thưởng việc và xóa toàn bộ dữ liệu trên lớp lưu trữ thật (bộ nhớ trong).
@MainActor
final class GachaStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "CozydayTests.gacha"

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suite)
    }

    private func makeStore() throws -> AppStore {
        try AppStore(container: PersistenceController.makeContainer(inMemory: true), defaults: defaults)
    }

    func testGiftCodeAndGachaPersist() throws {
        let store = try makeStore()
        XCTAssertThrowsError(try store.redeemGiftCode("sai-ma"))
        XCTAssertEqual(try store.redeemGiftCode("T3STER"), 1000)
        let before = store.wallet.coins
        let pulls = try store.pullGacha(count: 10)
        XCTAssertEqual(pulls.count, 10)
        let refund = pulls.reduce(0) { $0 + $1.refund }
        XCTAssertEqual(store.wallet.coins, before - GachaConfig.tenPrice + refund)
        for p in pulls where !p.isDuplicate {
            XCTAssertTrue(store.ownedIDs.contains(p.itemID), "món mới phải vào kho: \(p.itemID)")
        }
        // Nạp lại từ đĩa vẫn đúng.
        try store.reloadAll()
        XCTAssertEqual(store.wallet.coins, before - GachaConfig.tenPrice + refund)
        XCTAssertEqual(store.ledger.filter { $0.kind == .gacha }.count, 10)
    }

    func testGachaRejectsWhenPoor() throws {
        let store = try makeStore()
        let coins = store.wallet.coins
        if coins < GachaConfig.singlePrice {
            XCTAssertThrowsError(try store.pullGacha(count: 1))
            XCTAssertEqual(store.wallet.coins, coins)
        }
    }

    func testTaskRewardCapPerDay() throws {
        let store = try makeStore()
        try store.completeOnboarding(userName: "", petName: "Bông", goals: [], habits: [])
        var rewarded = 0, capped = 0
        for i in 0..<(RewardConfig.taskRewardsPerDay + 2) {
            var draft = TaskDraft()
            draft.title = "Việc \(i)"
            draft.day = store.today
            guard let id = try store.createTask(draft) else { return XCTFail("không tạo được việc") }
            let entry = try store.setStatus(id: id, to: .done)
            if let entry, entry.xp > 0 { rewarded += 1 } else { capped += 1 }
        }
        XCTAssertEqual(rewarded, RewardConfig.taskRewardsPerDay)
        XCTAssertEqual(capped, 2)
    }

    func testEraseAllDataReturnsToOnboarding() throws {
        let store = try makeStore()
        try store.completeOnboarding(userName: "An", petName: "Bông", goals: [], habits: [])
        try store.redeemGiftCode("t3ster")
        try store.saveAvatar(AvatarConfig(background: "mint", scene: "meadow", effect: "hearts", mood: "rest", look: nil, showName: true))
        var draft = TaskDraft()
        draft.title = "Đi bộ"
        draft.day = store.today
        try store.createTask(draft)
        XCTAssertTrue(store.profile.onboardingCompleted)

        try store.eraseAllData()
        XCTAssertFalse(store.profile.onboardingCompleted)
        XCTAssertTrue(store.occurrences.isEmpty)
        XCTAssertTrue(store.ledger.allSatisfy { $0.kind != .gift })
        XCTAssertEqual(store.avatar, .standard)
        XCTAssertNil(defaults.data(forKey: AppStore.avatarKey))
        // Mở lại vẫn là dữ liệu trống.
        try store.reloadAll()
        XCTAssertFalse(store.profile.onboardingCompleted)
    }
}
