import Foundation
import SwiftData

extension AppStore {
    static var appVersionString: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "?"
        let build = info["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    /// Ảnh chụp toàn bộ dữ liệu có thể khôi phục (gồm cả sổ cái và đồ đạc).
    func makeBackup() -> BackupDocument {
        BackupDocument(
            format: BackupDocument.formatID,
            schemaVersion: BackupDocument.currentSchemaVersion,
            exportedAt: now,
            appVersion: Self.appVersionString,
            profile: profile,
            templates: templates,
            occurrences: occurrences,
            ledger: ledger,
            ownedItems: owned,
            equipped: equipped,
            focusSessions: focusSessions,
            journal: journal,
            petCare: petCare,
            foodStock: foodStock,
            careActions: careActions,
            minigameResults: minigameResults,
            avatar: avatar
        )
    }

    /// Thay thế TOÀN BỘ dữ liệu hiện có bằng bản sao lưu đã được kiểm tra.
    /// Xóa + chèn trong một lần save: lỗi giữa chừng → rollback, dữ liệu cũ còn nguyên.
    func restore(_ document: BackupDocument) throws {
        try BackupValidator.validate(document)
        try commit {
            try self.deleteAll(ProfileModel.self)
            try self.deleteAll(TaskTemplateModel.self)
            try self.deleteAll(TaskOccurrenceModel.self)
            try self.deleteAll(LedgerEntryModel.self)
            try self.deleteAll(OwnedItemModel.self)
            try self.deleteAll(EquippedSlotModel.self)
            try self.deleteAll(FocusSessionModel.self)
            try self.deleteAll(JournalEntryModel.self)
            try self.deleteAll(PetCareStateModel.self)
            try self.deleteAll(FoodStockModel.self)
            try self.deleteAll(CareActionModel.self)
            try self.deleteAll(MinigameResultModel.self)

            self.context.insert(ProfileModel(record: document.profile))
            document.templates.forEach { self.context.insert(TaskTemplateModel(record: $0)) }
            document.occurrences.forEach { self.context.insert(TaskOccurrenceModel(record: $0)) }
            document.ledger.forEach { self.context.insert(LedgerEntryModel(record: $0)) }
            document.ownedItems.forEach { self.context.insert(OwnedItemModel(record: $0)) }
            document.equipped.forEach { self.context.insert(EquippedSlotModel(record: $0)) }
            document.focusSessions.forEach { self.context.insert(FocusSessionModel(record: $0)) }
            document.journal.forEach { self.context.insert(JournalEntryModel(record: $0)) }
            // File cũ (bản 1) chưa có phần chăm sóc: dùng chỉ số mặc định dễ chịu, không tặng lại gói chào mừng.
            let care = document.petCare ?? PetCareRecord(needs: .initial(at: self.now), welcomeGranted: true, createdAt: self.now)
            self.context.insert(PetCareStateModel(record: care))
            (document.foodStock ?? []).filter { $0.count > 0 }.forEach { self.context.insert(FoodStockModel(record: $0)) }
            (document.careActions ?? []).forEach { self.context.insert(CareActionModel(record: $0)) }
            (document.minigameResults ?? []).forEach { self.context.insert(MinigameResultModel(record: $0)) }
        }
        try reloadAll()
        // Ảnh đại diện nằm ngoài SwiftData: chỉ ghi sau khi phần dữ liệu chính đã khôi phục xong.
        try? saveAvatar(document.avatar ?? .standard)
        // Phiên tập trung quá hạn trong bản sao lưu: chốt một lần (khóa sổ cái chống thưởng trùng).
        _ = try? reconcileFocus()
        try? ensureUpcomingOccurrences()
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
        for model in try context.fetch(FetchDescriptor<T>()) {
            context.delete(model)
        }
    }
}
