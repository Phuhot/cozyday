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

extension Error {
    /// Lỗi ghi đĩa tạm thời (dữ liệu đã được rollback) — có thể thử lại với cùng mã giao dịch/lượt chơi.
    var isSaveFailure: Bool {
        if case .saveFailed? = self as? StoreError { return true }
        return false
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

    // Bộ đệm bản ghi đã lưu. Chỉ các phương thức của AppStore (kể cả extension ở file khác)
    // được ghi vào đây, và luôn cùng lúc với việc ghi model trong `commit`. View chỉ đọc.
    var profile: ProfileRecord
    var templates: [TaskTemplateRecord] = []
    var occurrences: [TaskOccurrenceRecord] = []
    var ledger: [LedgerEntry] = []
    var owned: [OwnedItemRecord] = []
    var equipped: [EquippedRecord] = []
    var focusSessions: [FocusSessionRecord] = []
    var journal: [JournalRecord] = []
    /// Chăm thú cưng (V3): nhu cầu, khay đồ ăn, lịch sử chăm sóc gần đây.
    var petCare: PetCareRecord
    var foodStock: [FoodStockRecord] = []
    var careActions: [CareActionRecord] = []
    /// Sân chơi (V3): các lượt đã kết thúc.
    var minigameResults: [MinigameResultRecord] = []
    /// Ảnh đại diện: chỉ là lựa chọn hiển thị nên lưu trong UserDefaults (không đổi lược đồ SwiftData),
    /// vẫn có trong bản sao lưu. Ghi qua `saveAvatar`.
    var avatar: AvatarConfig = .standard
    @ObservationIgnored let defaults: UserDefaults

    /// Tăng sau mỗi lần ghi thành công — dùng để đồng bộ lại thông báo.
    private(set) var changeCounter = 0

    @ObservationIgnored private var isWriting = false
    #if DEBUG
    /// Chỉ dùng trong test: lần `commit` kế tiếp giả lập lỗi lưu (sau khi đã sửa model) để kiểm tra rollback.
    @ObservationIgnored var failNextSaveForTesting = false
    #endif

    init(container: ModelContainer, clock: AppClock = SystemClock(), calendar: Calendar = .autoupdatingCurrent,
         defaults: UserDefaults = .standard) throws {
        self.context = ModelContext(container)
        self.defaults = defaults
        self.context.autosaveEnabled = false
        self.clock = clock
        self.calendar = calendar
        self.profile = ProfileRecord.makeDefault(now: clock.now)
        self.petCare = PetCareRecord(needs: .initial(at: clock.now), welcomeGranted: true, createdAt: clock.now)
        try ensureProfile()
        try ensurePetCare()
        self.avatar = Self.loadAvatar(from: defaults)
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
        if let care = try fetchPetCareModel() { petCare = care.record }
        foodStock = try context.fetch(FetchDescriptor<FoodStockModel>()).map(\.record)
        careActions = try context.fetch(FetchDescriptor<CareActionModel>()).compactMap(\.record)
            .sorted { $0.performedAt < $1.performedAt }
        minigameResults = try context.fetch(FetchDescriptor<MinigameResultModel>()).compactMap(\.record)
            .sorted { $0.finishedAt < $1.finishedAt }
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

    /// Tạo hồ sơ chăm sóc đúng một lần (thú cưng mới hoặc bản cũ vừa nâng cấp lên V3), kèm gói đồ ăn chào mừng
    /// trong CÙNG một lần lưu — mở lại app hay chạy lại migration không tặng thêm.
    private func ensurePetCare() throws {
        guard try fetchPetCareModel() == nil else { return }
        let record = PetCareRecord(needs: .initial(at: clock.now), welcomeGranted: true, createdAt: clock.now)
        context.insert(PetCareStateModel(record: record))
        let existing = Set(try context.fetch(FetchDescriptor<FoodStockModel>()).map(\.foodID))
        for pack in CareConfig.welcomePack where !existing.contains(pack.foodID) {
            context.insert(FoodStockModel(foodID: pack.foodID, count: pack.count))
        }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw StoreError.saveFailed(error.localizedDescription)
        }
    }

    func fetchPetCareModel() throws -> PetCareStateModel? {
        var descriptor = FetchDescriptor<PetCareStateModel>(sortBy: [SortDescriptor(\.createdAt)])
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
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
            #if DEBUG
            if failNextSaveForTesting {
                failNextSaveForTesting = false
                throw StoreError.saveFailed("lỗi giả lập trong test")
            }
            #endif
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
