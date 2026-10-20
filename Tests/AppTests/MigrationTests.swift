import XCTest
import SwiftData
@testable import Cozyday

/// Mở kho dữ liệu tạo bởi bản cũ (lược đồ V1) bằng bản mới (V2): dữ liệu không mất, xu/đồ không reset.
@MainActor
final class MigrationTests: XCTestCase {
    func testV1StoreOpensWithV2KeepingData() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("cozy-migration-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("Cozyday.store")
        let taskID = UUID()

        // 1. Bản cũ ghi dữ liệu bằng lược đồ V1
        do {
            let v1 = Schema(versionedSchema: CozySchemaV1.self)
            let container = try ModelContainer(for: v1, configurations: [ModelConfiguration(schema: v1, url: url, cloudKitDatabase: .none)])
            let context = ModelContext(container)
            let profile = CozySchemaV1.ProfileModel(
                userName: "An", petName: "Mochi", goalsRaw: "study", activeStartMinute: 420, activeEndMinute: 1320,
                hapticsEnabled: true, journalReminderEnabled: false, journalReminderMinute: 1260,
                onboardingCompleted: true, createdAt: Date(), dataVersion: 1
            )
            context.insert(profile)
            let occ = CozySchemaV1.TaskOccurrenceModel(id: taskID)
            occ.occurrenceKey = "o:\(taskID.uuidString.lowercased())"
            occ.dayRaw = "2026-10-18"
            occ.startMinute = 9 * 60
            occ.title = "Việc từ bản cũ"
            occ.statusRaw = "done"
            occ.completedAt = Date()
            context.insert(occ)
            let entry = CozySchemaV1.LedgerEntryModel(id: UUID())
            entry.key = "task:\(taskID.uuidString.lowercased())"
            entry.kindRaw = "taskCompleted"
            entry.xp = 10
            entry.coins = 5
            context.insert(entry)
            context.insert(CozySchemaV1.OwnedItemModel(itemID: "desk.pine", acquiredAt: Date(), transactionID: nil))
            context.insert(CozySchemaV1.EquippedSlotModel(slotRaw: "desk", itemID: "desk.pine"))
            try context.save()
        }

        // 2. Bản mới mở cùng file (qua migration plan V1 → V2)
        let container = try PersistenceController.makeContainer(url: url)
        let store = try AppStore(container: container)
        XCTAssertEqual(store.profile.petName, "Mochi")
        XCTAssertTrue(store.profile.onboardingCompleted)
        let task = try XCTUnwrap(store.occurrence(taskID))
        XCTAssertEqual(task.title, "Việc từ bản cũ")
        XCTAssertEqual(task.status, .done)
        XCTAssertEqual(task.checklist, [])
        XCTAssertEqual(store.wallet.coins, 5)
        XCTAssertEqual(store.equippedMap[.desk], "desk.pine")
        XCTAssertNil(try store.setStatus(id: taskID, to: .done), "không thưởng lại sau migration")

        // 3. Dùng tính năng mới (việc con) rồi mở lại
        var draft = TaskDraft(occurrence: task, template: nil)
        draft.subtasks = [Subtask(title: "Bước 1"), Subtask(title: "Bước 2")]
        try store.updateTask(id: taskID, draft: draft, scope: .thisOnly)
        let firstSub = try XCTUnwrap(store.occurrence(taskID)?.checklist.first?.id)
        try store.toggleSubtask(occurrenceID: taskID, subtaskID: firstSub)
        let reopened = try AppStore(container: PersistenceController.makeContainer(url: url))
        XCTAssertEqual(reopened.occurrence(taskID)?.checklist.map(\.isDone), [true, false])
    }

    /// Bản đang cài (V2: chưa có chăm thú cưng / Sân chơi) → bản mới (V3): giữ việc, xu, đồ, trang bị;
    /// tạo hồ sơ chăm sóc + gói đồ ăn chào mừng đúng một lần.
    func testV2StoreOpensWithV3KeepingDataAndGrantsWelcomeOnce() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("cozy-migration-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("Cozyday.store")
        let taskID = UUID(), journalID = UUID()

        do {
            let v2 = Schema(versionedSchema: CozySchemaV2.self)
            let container = try ModelContainer(for: v2, configurations: [ModelConfiguration(schema: v2, url: url, cloudKitDatabase: .none)])
            let context = ModelContext(container)
            context.insert(CozySchemaV2.ProfileModel(
                userName: "An", petName: "Bông", goalsRaw: "study", activeStartMinute: 420, activeEndMinute: 1320,
                hapticsEnabled: false, journalReminderEnabled: false, journalReminderMinute: 1260,
                onboardingCompleted: true, createdAt: Date(), dataVersion: 1
            ))
            let occ = CozySchemaV2.TaskOccurrenceModel(id: taskID)
            occ.occurrenceKey = "o:\(taskID.uuidString.lowercased())"
            occ.dayRaw = "2026-10-18"
            occ.title = "Việc bản V2"
            occ.statusRaw = "done"
            occ.completedAt = Date()
            occ.subtasksJSON = Subtasks.encode([Subtask(title: "Bước A", isDone: true)])
            context.insert(occ)
            for (key, kind, xp, coins) in [("task:\(taskID.uuidString.lowercased())", "taskCompleted", 120, 140),
                                           ("purchase:hat.beanie", "purchase", 0, -30)] {
                let e = CozySchemaV2.LedgerEntryModel(id: UUID())
                e.key = key
                e.kindRaw = kind
                e.xp = xp
                e.coins = coins
                context.insert(e)
            }
            context.insert(CozySchemaV2.OwnedItemModel(itemID: "hat.beanie", acquiredAt: Date(), transactionID: nil))
            context.insert(CozySchemaV2.EquippedSlotModel(slotRaw: "hat", itemID: "hat.beanie"))
            let j = CozySchemaV2.JournalEntryModel(id: journalID)
            j.dayRaw = "2026-10-18"
            j.note = "Nhật ký cũ"
            context.insert(j)
            try context.save()
        }

        let store = try AppStore(container: PersistenceController.makeContainer(url: url))
        XCTAssertEqual(store.profile.petName, "Bông")
        XCTAssertFalse(store.profile.hapticsEnabled)
        XCTAssertEqual(store.occurrence(taskID)?.checklist.first?.title, "Bước A")
        XCTAssertEqual(store.wallet, Wallet(xp: 120, coins: 110))
        XCTAssertEqual(store.equippedMap[.hat], "hat.beanie")
        XCTAssertEqual(store.journal.first?.note, "Nhật ký cũ")
        XCTAssertEqual(store.foodCount("food.apple"), 3)
        XCTAssertNil(store.currentNeeds.mostUrgent)

        // Dùng tính năng mới rồi mở lại: không tặng lại, dữ liệu mới còn nguyên.
        try store.performCare(.feed, foodID: "food.apple", actionID: UUID())
        let reopened = try AppStore(container: PersistenceController.makeContainer(url: url))
        XCTAssertEqual(reopened.foodCount("food.apple"), 2)
        XCTAssertEqual(reopened.careActions.count, 1)
        XCTAssertEqual(reopened.wallet, Wallet(xp: 120, coins: 110))
    }
}
