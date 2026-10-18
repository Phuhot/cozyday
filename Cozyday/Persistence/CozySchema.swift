import Foundation
import SwiftData

/// Lược đồ dữ liệu phiên bản 1. Không dùng quan hệ (relationship) giữa các bảng: tham chiếu bằng ID
/// để quy tắc xóa rõ ràng, và xóa một việc không bao giờ cascade xóa sổ cái thưởng.
///
/// Khi cần đổi lược đồ: tạo `CozySchemaV2` mới, thêm vào `CozyMigrationPlan.schemas` và một
/// `MigrationStage`. Không sửa trực tiếp các model của V1 đã phát hành.
enum CozySchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            ProfileModel.self,
            TaskTemplateModel.self,
            TaskOccurrenceModel.self,
            LedgerEntryModel.self,
            OwnedItemModel.self,
            EquippedSlotModel.self,
            FocusSessionModel.self,
            JournalEntryModel.self
        ]
    }

    @Model
    final class ProfileModel {
        var userName: String = ""
        var petName: String = ""
        var goalsRaw: String = ""
        var activeStartMinute: Int = 420
        var activeEndMinute: Int = 1320
        var hapticsEnabled: Bool = true
        var journalReminderEnabled: Bool = false
        var journalReminderMinute: Int = 1260
        var onboardingCompleted: Bool = false
        var createdAt: Date = Date(timeIntervalSince1970: 0)
        /// Phiên bản dữ liệu đã ghi lần cuối — dùng để phát hiện cần migration.
        var dataVersion: Int = 1

        init(userName: String, petName: String, goalsRaw: String, activeStartMinute: Int, activeEndMinute: Int,
             hapticsEnabled: Bool, journalReminderEnabled: Bool, journalReminderMinute: Int,
             onboardingCompleted: Bool, createdAt: Date, dataVersion: Int) {
            self.userName = userName
            self.petName = petName
            self.goalsRaw = goalsRaw
            self.activeStartMinute = activeStartMinute
            self.activeEndMinute = activeEndMinute
            self.hapticsEnabled = hapticsEnabled
            self.journalReminderEnabled = journalReminderEnabled
            self.journalReminderMinute = journalReminderMinute
            self.onboardingCompleted = onboardingCompleted
            self.createdAt = createdAt
            self.dataVersion = dataVersion
        }
    }

    @Model
    final class TaskTemplateModel {
        var id: UUID = UUID()
        var title: String = ""
        var notes: String = ""
        var categoryRaw: String = "personal"
        var priorityRaw: Int = 1
        var startMinute: Int?
        var durationMinutes: Int = 30
        var isFixed: Bool = false
        var reminderOffsetMinutes: Int?
        var frequencyRaw: String = "daily"
        var weekdaysRaw: String = ""
        var startDayRaw: String = ""
        var endDayRaw: String?
        var createdAt: Date = Date(timeIntervalSince1970: 0)

        init(id: UUID) {
            self.id = id
        }
    }

    @Model
    final class TaskOccurrenceModel {
        var id: UUID = UUID()
        var occurrenceKey: String = ""
        var templateID: UUID?
        /// "yyyy-MM-dd", hoặc chuỗi rỗng = Hộp chờ (chưa xếp ngày).
        var dayRaw: String = ""
        var startMinute: Int?
        var durationMinutes: Int = 30
        var title: String = ""
        var notes: String = ""
        var categoryRaw: String = "personal"
        var priorityRaw: Int = 1
        var isFixed: Bool = false
        var reminderOffsetMinutes: Int?
        var statusRaw: String = "open"
        var completedAt: Date?
        var isDetached: Bool = false
        var isRemoved: Bool = false
        var createdAt: Date = Date(timeIntervalSince1970: 0)
        var updatedAt: Date = Date(timeIntervalSince1970: 0)

        init(id: UUID) {
            self.id = id
        }
    }

    @Model
    final class LedgerEntryModel {
        var id: UUID = UUID()
        var key: String = ""
        var kindRaw: String = ""
        var xp: Int = 0
        var coins: Int = 0
        var createdAt: Date = Date(timeIntervalSince1970: 0)
        var refID: String?
        var memo: String = ""

        init(id: UUID) {
            self.id = id
        }
    }

    @Model
    final class OwnedItemModel {
        var itemID: String = ""
        var acquiredAt: Date = Date(timeIntervalSince1970: 0)
        var transactionID: UUID?

        init(itemID: String, acquiredAt: Date, transactionID: UUID?) {
            self.itemID = itemID
            self.acquiredAt = acquiredAt
            self.transactionID = transactionID
        }
    }

    @Model
    final class EquippedSlotModel {
        var slotRaw: String = ""
        var itemID: String = ""

        init(slotRaw: String, itemID: String) {
            self.slotRaw = slotRaw
            self.itemID = itemID
        }
    }

    @Model
    final class FocusSessionModel {
        var id: UUID = UUID()
        var kindRaw: String = "focus"
        var plannedSeconds: Int = 1500
        var startedAt: Date = Date(timeIntervalSince1970: 0)
        var accumulatedSeconds: Double = 0
        var runningSince: Date?
        var endedAt: Date?
        var statusRaw: String = "active"
        var occurrenceID: UUID?
        var focusedSeconds: Double = 0

        init(id: UUID) {
            self.id = id
        }
    }

    @Model
    final class JournalEntryModel {
        var id: UUID = UUID()
        var dayRaw: String = ""
        var mood: Int = 3
        var note: String = ""
        var createdAt: Date = Date(timeIntervalSince1970: 0)
        var updatedAt: Date = Date(timeIntervalSince1970: 0)

        init(id: UUID) {
            self.id = id
        }
    }
}

enum CozyMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [CozySchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

typealias ProfileModel = CozySchemaV1.ProfileModel
typealias TaskTemplateModel = CozySchemaV1.TaskTemplateModel
typealias TaskOccurrenceModel = CozySchemaV1.TaskOccurrenceModel
typealias LedgerEntryModel = CozySchemaV1.LedgerEntryModel
typealias OwnedItemModel = CozySchemaV1.OwnedItemModel
typealias EquippedSlotModel = CozySchemaV1.EquippedSlotModel
typealias FocusSessionModel = CozySchemaV1.FocusSessionModel
typealias JournalEntryModel = CozySchemaV1.JournalEntryModel
