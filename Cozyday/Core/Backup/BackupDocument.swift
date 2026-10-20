import Foundation

/// Toàn bộ dữ liệu có thể khôi phục của Cozyday, dạng JSON có phiên bản.
/// File ở dạng đọc được (KHÔNG mã hóa) — chứa nội dung riêng tư như tên việc và nhật ký.
struct BackupDocument: Codable, Equatable {
    static let formatID = "cozyday.backup"
    /// 1: bản đầu. 2: thêm chăm thú cưng (nhu cầu, khay đồ ăn, lịch sử chăm sóc) và kết quả Sân chơi.
    /// Bản 1 vẫn đọc được: các phần mới để trống → dùng giá trị mặc định khi khôi phục.
    static let currentSchemaVersion = 2

    var format: String
    var schemaVersion: Int
    var exportedAt: Date
    var appVersion: String
    var profile: ProfileRecord
    var templates: [TaskTemplateRecord]
    var occurrences: [TaskOccurrenceRecord]
    var ledger: [LedgerEntry]
    var ownedItems: [OwnedItemRecord]
    var equipped: [EquippedRecord]
    var focusSessions: [FocusSessionRecord]
    var journal: [JournalRecord]
    // V2 (có thể thiếu trong file cũ)
    var petCare: PetCareRecord?
    var foodStock: [FoodStockRecord]?
    var careActions: [CareActionRecord]?
    var minigameResults: [MinigameResultRecord]?
    /// Ảnh đại diện (thêm sau, vẫn là bản 2 vì là trường tùy chọn; file cũ không có → ảnh mặc định).
    var avatar: AvatarConfig?

    var counts: BackupCounts {
        BackupCounts(
            templates: templates.count,
            occurrences: occurrences.filter { !$0.isRemoved }.count,
            ledger: ledger.count,
            ownedItems: ownedItems.count,
            focusSessions: focusSessions.count,
            journal: journal.count,
            coins: Wallet(entries: ledger).coins,
            xp: Wallet(entries: ledger).xp,
            food: (foodStock ?? []).reduce(0) { $0 + $1.count },
            minigames: minigameResults?.count ?? 0
        )
    }
}

struct BackupCounts: Equatable {
    var templates: Int
    var occurrences: Int
    var ledger: Int
    var ownedItems: Int
    var focusSessions: Int
    var journal: Int
    var coins: Int
    var xp: Int
    var food: Int = 0
    var minigames: Int = 0
}

enum BackupError: Error, Equatable {
    case tooLarge(bytes: Int, limit: Int)
    case notJSON
    case wrongFormat
    case unsupportedVersion(found: Int, supported: Int)
    case corrupted(String)
    case duplicateID(String)
    case brokenReference(String)
    case invalidValue(String)

    var message: String {
        switch self {
        case .tooLarge(let bytes, let limit):
            return "File quá lớn (\(bytes / 1_000_000) MB, giới hạn \(limit / 1_000_000) MB)."
        case .notJSON:
            return "File không phải JSON hợp lệ."
        case .wrongFormat:
            return "Đây không phải file sao lưu của CozyDay."
        case .unsupportedVersion(let found, let supported):
            return "File sao lưu dùng phiên bản dữ liệu \(found), app này chỉ đọc được tới \(supported). Hãy cập nhật CozyDay trước khi khôi phục."
        case .corrupted(let detail):
            return "File sao lưu bị hỏng hoặc thiếu dữ liệu: \(detail)"
        case .duplicateID(let what):
            return "File sao lưu có ID bị trùng (\(what))."
        case .brokenReference(let what):
            return "File sao lưu có tham chiếu không hợp lệ (\(what))."
        case .invalidValue(let what):
            return "File sao lưu có giá trị không hợp lệ (\(what))."
        }
    }
}

enum BackupCodec {
    static let maxBytes = 25_000_000

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var c = encoder.singleValueContainer()
            try c.encode(isoFormatter().string(from: date))
        }
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let raw = try c.decode(String.self)
            if let d = isoFormatter().date(from: raw) { return d }
            let plain = ISO8601DateFormatter()
            if let d = plain.date(from: raw) { return d }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Thời điểm không hợp lệ: \(raw)")
        }
        return decoder
    }

    private static func isoFormatter() -> ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }

    static func encode(_ document: BackupDocument) throws -> Data {
        try makeEncoder().encode(document)
    }

    private struct Header: Decodable {
        var format: String?
        var schemaVersion: Int?
    }

    /// Đọc + kiểm tra đầy đủ. Không ghi gì vào dữ liệu đang có.
    static func decodeAndValidate(_ data: Data) throws -> BackupDocument {
        guard data.count <= maxBytes else { throw BackupError.tooLarge(bytes: data.count, limit: maxBytes) }
        guard (try? JSONSerialization.jsonObject(with: data)) != nil else { throw BackupError.notJSON }
        let header: Header
        do {
            header = try JSONDecoder().decode(Header.self, from: data)
        } catch {
            throw BackupError.wrongFormat
        }
        guard header.format == BackupDocument.formatID, let version = header.schemaVersion else {
            throw BackupError.wrongFormat
        }
        guard version >= 1, version <= BackupDocument.currentSchemaVersion else {
            throw BackupError.unsupportedVersion(found: version, supported: BackupDocument.currentSchemaVersion)
        }
        let document: BackupDocument
        do {
            document = try makeDecoder().decode(BackupDocument.self, from: data)
        } catch let error as DecodingError {
            throw BackupError.corrupted(describe(error))
        }
        try BackupValidator.validate(document)
        return document
    }

    private static func describe(_ error: DecodingError) -> String {
        func path(_ ctx: DecodingError.Context) -> String {
            ctx.codingPath.map { $0.intValue.map(String.init) ?? $0.stringValue }.joined(separator: ".")
        }
        switch error {
        case .keyNotFound(let key, let ctx): return "thiếu trường \(key.stringValue) tại \(path(ctx))"
        case .typeMismatch(_, let ctx): return "sai kiểu dữ liệu tại \(path(ctx))"
        case .valueNotFound(_, let ctx): return "thiếu giá trị tại \(path(ctx))"
        case .dataCorrupted(let ctx): return "dữ liệu hỏng tại \(path(ctx))"
        @unknown default: return "lỗi không xác định"
        }
    }
}

enum BackupValidator {
    static func validate(_ d: BackupDocument) throws {
        func unique<T: Hashable>(_ values: [T], _ what: String) throws {
            if Set(values).count != values.count { throw BackupError.duplicateID(what) }
        }
        try unique(d.templates.map(\.id), "mẫu việc lặp")
        try unique(d.occurrences.map(\.id), "việc")
        try unique(d.occurrences.map(\.occurrenceKey), "khóa việc")
        try unique(d.ledger.map(\.id), "sổ cái")
        try unique(d.ledger.map(\.key), "khóa sổ cái")
        try unique(d.ownedItems.map(\.itemID), "đồ đã sở hữu")
        try unique(d.equipped.map(\.slot), "vị trí đồ")
        try unique(d.focusSessions.map(\.id), "phiên tập trung")
        try unique(d.journal.map(\.id), "nhật ký")
        try unique(d.journal.map(\.day), "ngày nhật ký")

        let p = d.profile
        guard validMinute(p.activeStartMinute), (1...TimeOfDay.minutesPerDay).contains(p.activeEndMinute),
              p.activeStartMinute < p.activeEndMinute, validMinute(p.journalReminderMinute) else {
            throw BackupError.invalidValue("giờ trong hồ sơ")
        }

        let templateIDs = Set(d.templates.map(\.id))
        for t in d.templates {
            try checkTiming(start: t.startMinute, duration: t.durationMinutes, what: "mẫu “\(t.title.prefix(20))”")
            if t.recurrence.frequency == .weekly && t.recurrence.weekdays.isEmpty {
                throw BackupError.invalidValue("lịch lặp theo thứ không có thứ nào")
            }
            if let end = t.recurrence.endDay, end < t.recurrence.startDay {
                throw BackupError.invalidValue("ngày kết thúc lặp trước ngày bắt đầu")
            }
            try checkOffset(t.reminderOffsetMinutes)
        }
        for list in d.occurrences.map(\.checklist) + d.templates.map(\.checklist) {
            if list.count > Subtasks.maxCount || list.contains(where: { $0.title.isEmpty || $0.title.count > Subtasks.maxTitleLength }) {
                throw BackupError.invalidValue("việc con")
            }
            try unique(list.map(\.id), "việc con")
        }
        for o in d.occurrences {
            if let tid = o.templateID, !templateIDs.contains(tid) {
                // Mẫu có thể đã bị xóa "lần này trở đi" — chỉ chấp nhận cho lần đã xong/bỏ qua.
                if o.status == .open && !o.isRemoved {
                    throw BackupError.brokenReference("việc trỏ tới mẫu lặp không tồn tại")
                }
            }
            if o.startMinute != nil && o.day == nil {
                throw BackupError.invalidValue("việc có giờ nhưng không có ngày")
            }
            try checkTiming(start: o.startMinute, duration: o.durationMinutes, what: "việc “\(o.title.prefix(20))”")
            try checkOffset(o.reminderOffsetMinutes)
            if o.status == .done && o.completedAt == nil {
                throw BackupError.invalidValue("việc đã xong nhưng thiếu thời điểm hoàn thành")
            }
        }
        let wallet = Wallet(entries: d.ledger)
        if wallet.coins < 0 { throw BackupError.invalidValue("số xu âm") }
        for e in d.ledger {
            switch e.kind {
            case .gacha:
                // Một lượt quay: trừ giá, cộng lại xu hoàn khi trùng (có thể dương nếu món Bí mật trùng).
                guard e.coins <= GachaConfig.duplicateRefund(.secret), e.coins >= -GachaConfig.singlePrice, e.xp == 0 else {
                    throw BackupError.invalidValue("dòng máy gacha")
                }
            case .purchase, .foodPurchase:
                guard e.coins <= 0, e.xp == 0 else { throw BackupError.invalidValue("dòng mua đồ") }
            case .minigame:
                guard e.coins >= 0, e.coins <= MinigameConfig.maxCoinsPerRun, e.xp == 0 else { throw BackupError.invalidValue("dòng thưởng Sân chơi") }
            default:
                guard e.coins >= 0, e.xp >= 0 else { throw BackupError.invalidValue("dòng thưởng âm") }
            }
        }
        let owned = Set(d.ownedItems.map(\.itemID))
        for item in d.ownedItems where Catalog.item(item.itemID) == nil {
            throw BackupError.brokenReference("món đồ không có trong danh mục: \(item.itemID)")
        }
        for eq in d.equipped {
            guard let item = Catalog.item(eq.itemID), item.slot == eq.slot else {
                throw BackupError.brokenReference("món đồ trang bị sai vị trí: \(eq.itemID)")
            }
            guard owned.contains(eq.itemID) else {
                throw BackupError.brokenReference("trang bị món chưa sở hữu: \(eq.itemID)")
            }
        }
        if d.focusSessions.filter(\.isActive).count > 1 {
            throw BackupError.invalidValue("nhiều hơn một phiên tập trung đang chạy")
        }
        for s in d.focusSessions {
            guard s.plannedSeconds >= 60, s.plannedSeconds <= 4 * 3600,
                  s.accumulatedSeconds >= 0, s.focusedSeconds >= 0,
                  s.focusedSeconds <= Double(s.plannedSeconds) + 1 else {
                throw BackupError.invalidValue("phiên tập trung")
            }
        }
        for j in d.journal {
            guard Mood(rawValue: j.mood) != nil else { throw BackupError.invalidValue("mood ngoài khoảng 1–5") }
            guard j.note.count <= JournalRecord.maxNoteLength else { throw BackupError.invalidValue("nhật ký quá dài") }
        }
        try validateCareAndPlay(d)
    }

    /// Phần V2: chỉ số trong giới hạn, số lượng không âm, ID không trùng, thưởng có lịch sử đi kèm
    /// (để sau khi khôi phục vẫn chống được thưởng trùng và tính đúng hạn mức).
    private static func validateCareAndPlay(_ d: BackupDocument) throws {
        func unique<T: Hashable>(_ values: [T], _ what: String) throws {
            if Set(values).count != values.count { throw BackupError.duplicateID(what) }
        }
        if let care = d.petCare, !care.needs.isValid { throw BackupError.invalidValue("chỉ số chăm sóc") }
        if let avatar = d.avatar, !avatar.isWellFormed { throw BackupError.invalidValue("ảnh đại diện") }
        let stock = d.foodStock ?? []
        try unique(stock.map(\.foodID), "khay đồ ăn")
        for s in stock {
            guard FoodCatalog.item(s.foodID) != nil else { throw BackupError.brokenReference("món ăn không có trong danh mục: \(s.foodID)") }
            guard (0...FoodCatalog.maxStock).contains(s.count) else { throw BackupError.invalidValue("số lượng đồ ăn") }
        }
        let actions = d.careActions ?? []
        try unique(actions.map(\.id), "lịch sử chăm sóc")
        for a in actions {
            guard (0...100).contains(a.before), (0...100).contains(a.after), a.xp >= 0, a.coins >= 0 else {
                throw BackupError.invalidValue("lịch sử chăm sóc")
            }
            if let food = a.foodID, FoodCatalog.item(food) == nil { throw BackupError.brokenReference("món ăn: \(food)") }
        }
        let results = d.minigameResults ?? []
        try unique(results.map(\.id), "lượt Sân chơi")
        for r in results {
            guard r.coins >= 0, r.coins <= MinigameConfig.maxCoinsPerRun, r.score >= 0, r.activeSeconds >= 0 else {
                throw BackupError.invalidValue("kết quả Sân chơi")
            }
        }
        // Thưởng gần ngày xuất file phải có lịch sử tương ứng (lịch sử cũ hơn có thể đã được cắt bớt).
        let careIDs = Set(actions.map { $0.id.uuidString.lowercased() })
        let resultIDs = Set(results.map { $0.id.uuidString.lowercased() })
        let recent = d.exportedAt.addingTimeInterval(-2 * 86400)
        for e in d.ledger where e.createdAt >= recent {
            if e.kind == .care, !careIDs.contains(e.refID ?? "") { throw BackupError.brokenReference("thưởng chăm sóc thiếu lịch sử") }
            if e.kind == .minigame, !resultIDs.contains(e.refID ?? "") { throw BackupError.brokenReference("thưởng Sân chơi thiếu kết quả") }
        }
    }

    private static func validMinute(_ m: Int) -> Bool { (0..<TimeOfDay.minutesPerDay).contains(m) }

    private static func checkTiming(start: Int?, duration: Int, what: String) throws {
        guard duration >= 1, duration <= 24 * 60 else { throw BackupError.invalidValue("thời lượng của \(what)") }
        if let start {
            guard validMinute(start), start + duration <= TimeOfDay.minutesPerDay else {
                throw BackupError.invalidValue("giờ của \(what)")
            }
        }
    }

    private static func checkOffset(_ offset: Int?) throws {
        if let offset, offset < 0 || offset > 24 * 60 { throw BackupError.invalidValue("thời gian nhắc trước") }
    }
}
