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
}
