import Foundation
import SwiftData
import Observation

enum StoreError: Error, LocalizedError, Equatable {
    case saveFailed(String)
    case notFound
    case invalid(String)
    case busy

    var errorDescription: String? {
        switch self {
        case .saveFailed(let detail):
            return "Không lưu được dữ liệu. Thay đổi vừa rồi chưa được ghi. Chi tiết: \(detail)"
        case .notFound:
            return "Không tìm thấy dữ liệu này (có thể đã bị xóa)."
        case .invalid(let message):
            return message
        case .busy:
            return "Đang lưu thay đổi trước đó, hãy thử lại."
        }
    }
}

/// Nơi duy nhất đọc/ghi dữ liệu của app. Chạy trên main actor nên các thao tác được tuần tự hóa:
/// bấm nhanh hai lần không thể tạo hai giao dịch song song.
///
/// Mỗi thao tác ghi: kiểm tra bằng logic Core → sửa model → `save()` một lần. Nếu save lỗi:
/// `rollback()` và nạp lại từ đĩa, không báo thành công giả.
@MainActor
@Observable
final class AppStore {
    let context: ModelContext
    let clock: AppClock
    let calendar: Calendar

    private(set) var profile: ProfileRecord
    private(set) var templates: [TaskTemplateRecord] = []
    private(set) var occurrences: [TaskOccurrenceRecord] = []
    private(set) var ledger: [LedgerEntry] = []
    private(set) var owned: [OwnedItemRecord] = []
    private(set) var equipped: [EquippedRecord] = []
    private(set) var focusSessions: [FocusSessionRecord] = []
    private(set) var journal: [JournalRecord] = []

    /// Tăng sau mỗi lần ghi thành công — dùng để đồng bộ lại thông báo.
    private(set) var changeCounter = 0

    @ObservationIgnored private var isWriting = false

    init(container: ModelContainer, clock: AppClock = SystemClock(), calendar: Calendar = .autoupdatingCurrent) throws {
        self.context = ModelContext(container)
        self.context.autosaveEnabled = false
        self.clock = clock
        self.calendar = calendar
        self.profile = ProfileRecord.makeDefault(now: clock.now)
        try ensureProfile()
        try reloadAll()
        try repairDuplicateOccurrences()
    }

    var now: Date { clock.now }
    var today: DayKey { DayKey(clock.now, calendar: calendar) }

    // MARK: Nạp dữ liệu

    func reloadAll() throws {
        if let p = try fetchProfileModel() { profile = p.record }
        templates = try context.fetch(FetchDescriptor<TaskTemplateModel>()).compactMap(\.record)
        occurrences = try context.fetch(FetchDescriptor<TaskOccurrenceModel>()).map(\.record)
        ledger = try context.fetch(FetchDescriptor<LedgerEntryModel>()).compactMap(\.record)
            .sorted { $0.createdAt < $1.createdAt }
        owned = try context.fetch(FetchDescriptor<OwnedItemModel>()).map(\.record)
        equipped = try context.fetch(FetchDescriptor<EquippedSlotModel>()).compactMap(\.record)
        focusSessions = try context.fetch(FetchDescriptor<FocusSessionModel>()).map(\.record)
            .sorted { $0.startedAt < $1.startedAt }
        journal = try context.fetch(FetchDescriptor<JournalEntryModel>()).compactMap(\.record)
    }

    /// Tạo hồ sơ mặc định đúng một lần (idempotent). Không bao giờ ghi đè hồ sơ đang có.
    private func ensureProfile() throws {
        guard try fetchProfileModel() == nil else { return }
        context.insert(ProfileModel(record: ProfileRecord.makeDefault(now: clock.now)))
        do {
            try context.save()
        } catch {
            context.rollback()
            throw StoreError.saveFailed(error.localizedDescription)
        }
    }

    func fetchProfileModel() throws -> ProfileModel? {
        var descriptor = FetchDescriptor<ProfileModel>(sortBy: [SortDescriptor(\.createdAt)])
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Phòng hờ: nếu có hai occurrence cùng khóa (không nên xảy ra), giữ bản có tiến độ.
    private func repairDuplicateOccurrences() throws {
        let groups = Dictionary(grouping: occurrences, by: \.occurrenceKey).filter { $0.value.count > 1 }
        guard !groups.isEmpty else { return }
        try commit {
            for (_, dupes) in groups {
                let keep = dupes.sorted { a, b in
                    if (a.status != .open) != (b.status != .open) { return a.status != .open }
                    return a.updatedAt > b.updatedAt
                }.first!
                for d in dupes where d.id != keep.id {
                    try self.context.delete(self.occurrenceModel(d.id))
                }
            }
        }
        try reloadAll()
    }

    // MARK: Ghi có giao dịch

    /// Chạy `body` rồi save đúng một lần. Lỗi → rollback, nạp lại, ném lỗi.
    func commit(_ body: () throws -> Void) throws {
        guard !isWriting else { throw StoreError.busy }
        isWriting = true
        defer { isWriting = false }
        do {
            try body()
            try context.save()
            changeCounter += 1
        } catch {
            context.rollback()
            try? reloadAll()
            if let storeError = error as? StoreError { throw storeError }
            throw StoreError.saveFailed(error.localizedDescription)
        }
    }

    // MARK: Tra cứu model

    func occurrenceModel(_ id: UUID) throws -> TaskOccurrenceModel {
        var d = FetchDescriptor<TaskOccurrenceModel>(predicate: #Predicate { $0.id == id })
        d.fetchLimit = 1
        guard let m = try context.fetch(d).first else { throw StoreError.notFound }
        return m
    }

    func templateModel(_ id: UUID) throws -> TaskTemplateModel {
        var d = FetchDescriptor<TaskTemplateModel>(predicate: #Predicate { $0.id == id })
        d.fetchLimit = 1
        guard let m = try context.fetch(d).first else { throw StoreError.notFound }
        return m
    }

    func focusModel(_ id: UUID) throws -> FocusSessionModel {
        var d = FetchDescriptor<FocusSessionModel>(predicate: #Predicate { $0.id == id })
        d.fetchLimit = 1
        guard let m = try context.fetch(d).first else { throw StoreError.notFound }
        return m
    }

    // MARK: Hồ sơ

    func updateProfile(_ change: (inout ProfileRecord) -> Void) throws {
        var updated = profile
        change(&updated)
        guard updated.activeStartMinute < updated.activeEndMinute else {
            throw StoreError.invalid("Giờ bắt đầu ngày phải sớm hơn giờ kết thúc.")
        }
        try commit {
            guard let model = try self.fetchProfileModel() else { throw StoreError.notFound }
            model.apply(updated)
            self.profile = updated
        }
    }

    // MARK: Ví & sổ cái

    var wallet: Wallet { Wallet(entries: ledger) }
    var ledgerKeys: Set<String> { Set(ledger.map(\.key)) }

    func insertLedger(_ entry: LedgerEntry) {
        context.insert(LedgerEntryModel(record: entry))
        ledger.append(entry)
    }
}
