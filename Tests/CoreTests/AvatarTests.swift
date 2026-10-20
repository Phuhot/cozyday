import XCTest
#if canImport(CozyCore)
@testable import CozyCore
#else
@testable import Cozyday
#endif

final class AvatarTests: XCTestCase {
    func testCatalogIDsUniqueAndStandardUnlockedAtLevelOne() {
        for part in AvatarPart.allCases {
            let ids = part.options.map(\.id)
            XCTAssertEqual(Set(ids).count, ids.count, "trùng ID ở \(part)")
            let standard = AvatarConfig.standard.id(part)
            XCTAssertEqual(AvatarCatalog.option(part, standard)?.requiredLevel, 1, "mặc định phải mở sẵn: \(part)")
            XCTAssertGreaterThanOrEqual(part.options.filter { $0.requiredLevel == 1 }.count, 2, "cấp 1 phải có lựa chọn: \(part)")
        }
    }

    func testLockedOrUnknownChoiceFallsBackToStandard() {
        var config = AvatarConfig.standard
        config.background = "galaxy"
        XCTAssertEqual(config.resolved(.background, level: 1), "sky")
        XCTAssertEqual(config.resolved(.background, level: 8), "galaxy")
        config.effect = "unicorn-rain"
        XCTAssertEqual(config.resolved(.effect, level: 50), "sparkles")
    }

    func testLookUsesOnlyOwnedItemsInRightSlot() {
        let equipped: [ItemSlot: String] = [.hat: "hat.beanie"]
        let owned: Set<String> = ["hat.beanie", "hat.sprout"]
        var config = AvatarConfig.standard
        XCTAssertEqual(config.appearance(equipped: equipped, owned: owned, level: 1).hat, "hat.beanie")

        config.setLook(.hat, to: "hat.sprout", current: PetAppearance(equipped: equipped, level: 1))
        XCTAssertEqual(config.appearance(equipped: equipped, owned: owned, level: 1).hat, "hat.sprout")

        // Món chưa có hoặc sai vị trí: bỏ qua, giữ đồ đang mặc.
        config.look?["hat"] = "hat.crown"
        XCTAssertEqual(config.appearance(equipped: equipped, owned: owned, level: 1).hat, "hat.beanie")
        config.look?["hat"] = "glasses.star"
        XCTAssertEqual(config.appearance(equipped: equipped, owned: owned, level: 1).hat, "hat.beanie")

        // "" = tháo món ở vị trí đó.
        config.look?["hat"] = ""
        XCTAssertNil(config.appearance(equipped: equipped, owned: owned, level: 1).hat)

        // Giai đoạn lớn luôn theo cấp thật.
        XCTAssertEqual(config.appearance(equipped: equipped, owned: owned, level: 12).stage, .grown)
    }

    func testSetLookSnapshotsCurrentOutfitFirst() {
        let current = PetAppearance(species: .duck, fur: .honey, hat: "hat.cloud", neck: "neck.scarf")
        var config = AvatarConfig.standard
        config.setLook(.hat, to: nil, current: current)
        XCTAssertEqual(config.look?["hat"], "")
        XCTAssertEqual(config.look?["neck"], "neck.scarf")
        XCTAssertEqual(config.look?["species"], "species.duck")
    }

    func testWellFormedLimits() {
        XCTAssertTrue(AvatarConfig.standard.isWellFormed)
        var bad = AvatarConfig.standard
        bad.background = ""
        XCTAssertFalse(bad.isWellFormed)
        bad = .standard
        bad.look = Dictionary(uniqueKeysWithValues: (0..<40).map { ("k\($0)", "v") })
        XCTAssertFalse(bad.isWellFormed)
    }

    func testBackupWithAvatarRoundTripsAndOldFileStillReads() throws {
        var doc = BackupTests.sampleDocument()
        XCTAssertNil(doc.avatar)
        let old = try BackupCodec.decodeAndValidate(BackupCodec.encode(doc))
        XCTAssertNil(old.avatar)
        doc.avatar = AvatarConfig(background: "mint", scene: "meadow", effect: "hearts", mood: "rest",
                                  look: ["hat": "hat.sprout"], showName: true)
        XCTAssertEqual(try BackupCodec.decodeAndValidate(BackupCodec.encode(doc)), doc)
        doc.avatar?.mood = String(repeating: "x", count: 200)
        XCTAssertThrowsError(try BackupCodec.decodeAndValidate(BackupCodec.encode(doc))) { error in
            XCTAssertEqual(error as? BackupError, .invalidValue("ảnh đại diện"))
        }
    }
}
