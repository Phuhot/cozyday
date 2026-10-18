import Foundation

/// Chuyến phiêu lưu mỗi ngày: thú cưng nạp năng lượng từ những gì bạn làm trong ngày
/// (hoàn thành việc, phiên tập trung, nhật ký, bài thở). Đủ năng lượng thì đi chơi và về kể chuyện.
/// Năng lượng suy ra từ sổ cái — không lưu riêng, không bao giờ bị trừ.
struct AdventureStory: Equatable {
    var title: String
    var text: String
    /// Món kỷ niệm nhặt được (chỉ để kể, không phải vật phẩm trong cửa hàng).
    var keepsake: String
}

struct AdventureMemory: Identifiable, Equatable {
    var day: DayKey
    var story: AdventureStory
    var id: DayKey { day }
}

enum Adventure {
    static let energyPerActivity = 25
    static let fullEnergy = 100

    static let countedKinds: Set<LedgerKind> = [.taskCompleted, .focusCompleted, .journalWritten, .breathing]

    static func energy(on day: DayKey, ledger: [LedgerEntry], calendar: Calendar) -> Int {
        let count = ledger.filter { countedKinds.contains($0.kind) && DayKey($0.createdAt, calendar: calendar) == day }.count
        return min(fullEnergy, count * energyPerActivity)
    }

    static func isReady(on day: DayKey, ledger: [LedgerEntry], calendar: Calendar) -> Bool {
        energy(on: day, ledger: ledger, calendar: calendar) >= fullEnergy
    }

    static func reward(day: DayKey, existingKeys: Set<String>, petName: String, now: Date) -> LedgerEntry? {
        let key = LedgerKeys.adventure(day)
        guard !existingKeys.contains(key) else { return nil }
        return LedgerEntry(
            id: UUID(), key: key, kind: .adventure,
            xp: RewardConfig.adventureXP, coins: RewardConfig.adventureCoins,
            createdAt: now, refID: day.string, memo: story(for: day, petName: petName).title
        )
    }

    // MARK: Câu chuyện — chọn cố định theo ngày (cùng một ngày luôn ra cùng một câu chuyện)

    static let places = [
        "bờ hồ sen", "khu vườn sau nhà", "thư viện nhỏ cuối phố", "đồi cỏ lau", "chợ hoa buổi sáng",
        "con hẻm có giàn hoa giấy", "tiệm bánh mì đầu ngõ", "bãi biển lúc hoàng hôn", "khu rừng thông",
        "sân thượng đầy chậu cây", "ga tàu cũ", "cánh đồng lúa"
    ]
    static let meetings = [
        "gặp một chú ốc sên đi chậm rãi", "làm quen với một chú chim sẻ hay hát",
        "ngồi xem mây trôi cùng một bạn mèo hàng xóm", "giúp một bạn kiến khiêng hạt gạo",
        "nghe bà cụ bán hoa kể chuyện ngày xưa", "đuổi theo một cánh bướm vàng",
        "nằm dưới gốc cây nghe gió thổi", "đếm được mười chín chiếc lá rơi",
        "tập huýt sáo (gần được rồi)", "chia nửa chiếc bánh quy với một chú sóc"
    ]
    static let keepsakes = [
        "một chiếc lá hình trái tim", "một viên sỏi tròn nhẵn", "một chiếc lông vũ màu xanh",
        "một bông hoa dại tím", "một vỏ ốc nhỏ", "một tấm bưu thiếp cũ", "một hạt dẻ bóng loáng",
        "một chiếc cúc áo màu vàng", "một quả thông nhỏ", "một mẩu ruy băng đỏ",
        "một tờ giấy vẽ ngôi sao", "một chiếc chuông gió bằng tre"
    ]
    static let endings = [
        "rồi chạy một mạch về nhà vì nhớ bạn.",
        "và mang về tặng bạn, coi như quà cho một ngày cố gắng.",
        "rồi về kể cho bạn nghe, mắt sáng lấp lánh.",
        "và quyết định ngày mai sẽ quay lại đó.",
        "rồi ngủ gật trên đường về, mơ thấy bạn.",
        "và cất thật kỹ vào góc phòng.",
        "rồi ngân nga suốt quãng đường về nhà.",
        "và nói rằng hôm nay là một ngày thật đẹp."
    ]

    static func story(for day: DayKey, petName: String) -> AdventureStory {
        func pick(_ list: [String], _ salt: String) -> String {
            list[Int(stableHash(day.string + "|" + salt) % UInt64(list.count))]
        }
        let place = pick(places, "place")
        let meeting = pick(meetings, "meet")
        let keepsake = pick(keepsakes, "keep")
        let ending = pick(endings, "end")
        let name = petName.isEmpty ? ProfileRecord.defaultPetName : petName
        return AdventureStory(
            title: "Chuyến đi tới \(place)",
            text: "\(name) ghé \(place), \(meeting), nhặt được \(keepsake) \(ending)",
            keepsake: keepsake
        )
    }

    /// FNV-1a 64-bit: ổn định giữa các lần chạy (không như `hashValue`).
    static func stableHash(_ s: String) -> UInt64 {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in s.utf8 {
            h ^= UInt64(b)
            h = h &* 0x0000_0100_0000_01B3
        }
        return h
    }
}
