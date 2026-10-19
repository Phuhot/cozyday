import XCTest
import SwiftData
@testable import Cozyday

/// Ảnh đại diện trên lớp lưu trữ thật: lưu vào UserDefaults riêng của test, mở lại, sao lưu/khôi phục.
@MainActor
final class AvatarStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "CozydayTests.avatar"

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suite)
    }

    private func makeStore(_ container: ModelContainer) throws -> AppStore {
        try AppStore(container: container, defaults: defaults)
    }

    func testSaveReloadAndBackupRestore() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = try makeStore(container)
        XCTAssertEqual(store.avatar, .standard)
        XCTAssertNil(store.avatarCaption)

        let custom = AvatarConfig(background: "mint", scene: "meadow", effect: "hearts", mood: "rest", look: nil, showName: true)
        try store.saveAvatar(custom)
        XCTAssertEqual(try makeStore(container).avatar, custom, "mở lại app vẫn giữ lựa chọn")
        XCTAssertEqual(store.avatarCaption, "\(store.profile.displayPetName) · Cấp \(store.wallet.level)")

        let backup = store.makeBackup()
        XCTAssertEqual(backup.avatar, custom)
        try store.saveAvatar(.standard)
        try store.restore(backup)
        XCTAssertEqual(store.avatar, custom)

        // File sao lưu cũ (không có ảnh đại diện) → ảnh mặc định.
        var old = backup
        old.avatar = nil
        try store.restore(old)
        XCTAssertEqual(store.avatar, .standard)
    }

    func testMalformedStoredValueFallsBackAndBadConfigRejected() throws {
        defaults.set(Data("not json".utf8), forKey: AppStore.avatarKey)
        let store = try makeStore(try PersistenceController.makeContainer(inMemory: true))
        XCTAssertEqual(store.avatar, .standard)
        var bad = AvatarConfig.standard
        bad.scene = ""
        XCTAssertThrowsError(try store.saveAvatar(bad))
        XCTAssertEqual(store.avatar, .standard)
    }

    func testOutfitLookOnlyUsesOwnedItems() throws {
        let store = try makeStore(try PersistenceController.makeContainer(inMemory: true))
        var config = AvatarConfig.standard
        config.setLook(.hat, to: "hat.crown", current: store.petAppearance)
        try store.saveAvatar(config)
        XCTAssertNil(store.avatarAppearance.hat, "chưa có vương miện thì không đội trong ảnh")
    }
}
