import Foundation
import SwiftData

/// Lược đồ dữ liệu phiên bản 4 — giữ nguyên mọi model của V3, chỉ THÊM:
/// - cột `tickets` (vé máy gacha, mặc định 0) trong sổ cái;
/// - bảng `KeepsakeModel` (kỷ vật chuyến đi trưng bày trong phòng).
/// Chuyển từ V3 bằng migration nhẹ (thêm cột có giá trị mặc định + thêm bảng): dữ liệu cũ giữ nguyên.
enum CozySchemaV4: VersionedSchema {
    static let versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            ProfileModel.self,
            TaskTemplateModel.self,
            TaskOccurrenceModel.self,
            LedgerEntryModel.self,
            OwnedItemModel.self,
            EquippedSlotModel.self,
            FocusSessionModel.self,
            JournalEntryModel.self,
            PetCareStateModel.self,
            FoodStockModel.self,
            CareActionModel.self,
            MinigameResultModel.self,
            KeepsakeModel.self
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
        /// V2: danh sách việc con (JSON), rỗng = không có.
        var subtasksJSON: String = ""

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
        /// V2: danh sách việc con (JSON), rỗng = không có.
        var subtasksJSON: String = ""

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
        /// Vé máy gacha (V4). Dòng cũ = 0.
        var tickets: Int = 0

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

    /// V3: hồ sơ chăm sóc dùng chung (một bản ghi duy nhất).
    @Model
    final class PetCareStateModel {
        var fullness: Double = 80
        var cleanliness: Double = 85
        var happiness: Double = 80
        var asOf: Date = Date(timeIntervalSince1970: 0)
        var welcomeGranted: Bool = false
        var createdAt: Date = Date(timeIntervalSince1970: 0)

        init(createdAt: Date) {
            self.createdAt = createdAt
        }
    }

    /// V3: số lượng một món trong khay đồ ăn.
    @Model
    final class FoodStockModel {
        var foodID: String = ""
        var count: Int = 0

        init(foodID: String, count: Int) {
            self.foodID = foodID
            self.count = count
        }
    }

    /// V3: một lần chăm sóc đã lưu (`id` = careActionID).
    @Model
    final class CareActionModel {
        var id: UUID = UUID()
        var kindRaw: String = ""
        var dayRaw: String = ""
        var performedAt: Date = Date(timeIntervalSince1970: 0)
        var foodID: String?
        var before: Int = 0
        var after: Int = 0
        var xp: Int = 0
        var coins: Int = 0
        var noteRaw: String = ""

        init(id: UUID) {
            self.id = id
        }
    }

    /// V3: một lượt Sân chơi đã kết thúc (`id` = sessionID).
    @Model
    final class MinigameResultModel {
        var id: UUID = UUID()
        var kindRaw: String = ""
        var score: Int = 0
        var primary: Int = 0
        var secondary: Int = 0
        var levelRaw: String?
        var activeSeconds: Double = 0
        var species: String = ""
        var startedAt: Date = Date(timeIntervalSince1970: 0)
        var finishedAt: Date = Date(timeIntervalSince1970: 0)
        var dayRaw: String = ""
        var coins: Int = 0
        var earned: Int = 0
        var noteRaw: String = ""

        init(id: UUID) {
            self.id = id
        }
    }

    @Model
    final class KeepsakeModel {
        var id: UUID = UUID()
        var sourceKey: String = ""
        var artID: String = ""
        var title: String = ""
        var story: String = ""
        var dayRaw: String = ""
        var petName: String = ""
        var species: String = ""
        var createdAt: Date = Date(timeIntervalSince1970: 0)
        var placedRoom: String?

        init(id: UUID) {
            self.id = id
        }
    }
}
