import Foundation

enum MinigameKind: String, Codable, CaseIterable, Identifiable {
    case cloudJump
    case giftBasket
    case memoryMatch
    case blockPuzzle
    case sweetMerge

    var id: String { rawValue }

    var name: String {
        switch self {
        case .cloudJump: return "Nhảy Mây"
        case .giftBasket: return "Giỏ Quà"
        case .memoryMatch: return "Lật Thẻ Bạn Nhỏ"
        case .blockPuzzle: return "Xếp Khối"
        case .sweetMerge: return "Gộp Bánh"
        }
    }

    var blurb: String {
        switch self {
        case .cloudJump: return "Nảy từ đám mây này sang đám mây khác, lên cao nhất có thể."
        case .giftBasket: return "Cầm giỏ hứng quà rơi trong 60 giây, né bùn và mây mưa."
        case .memoryMatch: return "Lật thẻ tìm cặp bạn nhỏ giống nhau."
        case .blockPuzzle: return "Kéo khối kẹo dẻo vào bàn 8×8, lấp kín hàng hoặc cột để xóa."
        case .sweetMerge: return "Vuốt cho hai món giống nhau chạm nhau, gộp kẹo thành bánh kem nhiều tầng."
        }
    }

    var symbol: String {
        switch self {
        case .cloudJump: return "cloud.fill"
        case .giftBasket: return "basket.fill"
        case .memoryMatch: return "square.grid.3x3.fill"
        case .blockPuzzle: return "puzzlepiece.fill"
        case .sweetMerge: return "birthday.cake.fill"
        }
    }

    /// Luật ngắn trong màn hướng dẫn (đọc trong ~5 giây).
    var howTo: [String] {
        switch self {
        case .cloudJump: return ["Bạn nhỏ tự nảy khi chạm mây. Kéo ngang để sang trái/phải.",
                                 "Né mây giông và chim. Mây viền nét đứt chỉ nảy được một lần.",
                                 "Rơi xuống dưới là hết lượt."]
        case .giftBasket: return ["Kéo ngang để di chuyển giỏ.", "Hứng trái cây, sao, hộp quà.", "Né cục bùn nâu và đám mây mưa."]
        case .memoryMatch: return ["Chạm để lật hai thẻ.", "Giống nhau thì giữ mở.", "Ghép hết các cặp là thắng."]
        case .blockPuzzle: return ["Kéo một khối trong khay thả vào bàn. Bóng mờ cho biết khối sẽ nằm ở đâu.",
                                   "Lấp kín một hàng hoặc một cột là xóa. Xóa nhiều đường một lúc, hay xóa liền tay, được thêm điểm.",
                                   "Không còn chỗ cho khối nào trong khay là xong lượt."]
        case .sweetMerge: return ["Vuốt lên, xuống, trái, phải để dồn mọi món về một phía.",
                                  "Hai món giống nhau chạm nhau thì gộp thành món to hơn: kẹo, bánh quy, donut, cupcake, bánh kem…",
                                  "Bàn đầy mà không gộp được nữa là xong lượt."]
        }
    }

    /// Game theo lượt (không vẽ theo khung hình, không giới hạn thời gian).
    var isTurnBased: Bool {
        switch self {
        case .cloudJump, .giftBasket: return false
        case .memoryMatch, .blockPuzzle, .sweetMerge: return true
        }
    }

    /// Người chơi được tự kết thúc lượt ở màn tạm dừng mà vẫn tính xu theo điểm đã có.
    var canEndRun: Bool { self == .blockPuzzle || self == .sweetMerge }
}

enum MemoryLevel: String, Codable, CaseIterable, Identifiable {
    case easy, medium

    var id: String { rawValue }
    var pairs: Int { self == .easy ? 6 : 8 }
    var columns: Int { self == .easy ? 3 : 4 }
    var rows: Int { 4 }
    var label: String { self == .easy ? "Dễ" : "Vừa" }
    /// Hoàn thành trong thời gian này được +1 xu.
    var fastSeconds: Double { self == .easy ? 40 : 65 }
}

/// Mọi con số về thưởng Sân chơi. Xu Sân chơi là thưởng phụ: không có XP, có hạn mức mỗi ngày
/// (đối chiếu: một ngày bình thường từ việc + tập trung + nhật ký ≈ 30–45 xu).
enum MinigameConfig {
    static let dailyCoinCap = 40
    static let maxCoinsPerRun = 8

    // Nhảy Mây: 1 xu cho mỗi 15 điểm, cần leo ít nhất 15 m.
    static let jumpMinHeight = 15
    static let jumpPointsPerCoin = 15
    // Giỏ Quà: chơi hết 60 giây, 1 xu cho mỗi 20 điểm, cần ít nhất 20 điểm.
    static let basketDuration: Double = 60
    static let basketMinScore = 20
    static let basketPointsPerCoin = 20
    // Lật thẻ: chỉ thưởng khi ghép hết bàn.
    static let memoryBaseEasy = 2
    static let memoryBaseMedium = 3
    // Xếp Khối: cần ít nhất 100 điểm, 1 xu cho mỗi 120 điểm (máy chơi tham khảo: 220–1700, trung bình ≈ 700).
    // Hết chỗ hoặc tự kết thúc lượt đều tính.
    static let blocksMinScore = 100
    static let blocksPointsPerCoin = 120
    // Gộp Bánh: cần ít nhất 400 điểm, 1 xu cho mỗi 400 điểm (máy chơi tham khảo: 600–5900, trung bình ≈ 2900).
    // Hết đường hoặc tự kết thúc lượt đều tính.
    static let mergeMinScore = 400
    static let mergePointsPerCoin = 400

    // Giới hạn hợp lý để kiểm tra kết quả (không tin hoàn toàn số liệu từ màn hình).
    static let jumpMaxMetersPerSecond = 8.0
    static let basketMaxPointsPerSecond = 40.0
    static let memoryMinSecondsPerPair = 0.6
    static let blocksMaxPointsPerSecond = 40.0
    static let blocksMaxMovesPerSecond = 4.0
    static let mergeMaxPointsPerSecond = 150.0
    static let mergeMaxMovesPerSecond = 8.0

    static let rulesText: [String] = [
        "Mỗi lượt Sân chơi hợp lệ: 1–\(maxCoinsPerRun) xu, không có XP. Tối đa \(dailyCoinCap) xu Sân chơi mỗi ngày (tính theo ngày lượt chơi kết thúc).",
        "Nhảy Mây: leo từ \(jumpMinHeight) m; cứ \(jumpPointsPerCoin) điểm được 1 xu. Giỏ Quà: chơi hết 60 giây, từ \(basketMinScore) điểm; cứ \(basketPointsPerCoin) điểm được 1 xu.",
        "Lật Thẻ: chỉ có xu khi ghép hết bàn (Dễ \(memoryBaseEasy) xu, Vừa \(memoryBaseMedium) xu, thêm xu khi lật ít và nhanh).",
        "Xếp Khối: từ \(blocksMinScore) điểm; cứ \(blocksPointsPerCoin) điểm được 1 xu. Gộp Bánh: từ \(mergeMinScore) điểm; cứ \(mergePointsPerCoin) điểm được 1 xu. Hai game này không giới hạn thời gian: bấm Tạm dừng rồi Kết thúc lượt vẫn nhận xu theo điểm đã có.",
        "Thoát giữa lượt không có xu. Thua không bao giờ mất xu. Hết hạn mức vẫn chơi và lưu kỷ lục được."
    ]
}

/// Kết quả một lượt do màn chơi tạo ra (từ engine), trước khi kiểm tra và tính thưởng.
struct MinigameOutcome: Codable, Equatable {
    var sessionID: UUID
    var kind: MinigameKind
    var score: Int
    /// Nhảy Mây: độ cao (m). Giỏ Quà: số món tốt đã hứng. Lật thẻ: số lượt lật (mỗi cặp thẻ mở = 1 lượt).
    /// Xếp Khối: số đường (hàng + cột) đã xóa. Gộp Bánh: giá trị món lớn nhất (2, 4, 8…).
    var primary: Int
    /// Nhảy Mây: số sao. Giỏ Quà: combo dài nhất. Lật thẻ: số cặp đã ghép.
    /// Xếp Khối: số khối đã đặt. Gộp Bánh: số lượt vuốt.
    var secondary: Int
    var level: MemoryLevel?
    /// Thời gian chạy thật của lượt (không tính tạm dừng), giây.
    var activeSeconds: Double
    /// Lượt kết thúc đúng luật: rơi (Nhảy Mây), hết 60 giây (Giỏ Quà), ghép hết bàn (Lật thẻ),
    /// hết nước đi hoặc người chơi tự kết thúc lượt (Xếp Khối, Gộp Bánh).
    var completed: Bool
    var species: String
    var startedAt: Date
    var finishedAt: Date
}

enum MinigameRewardNote: String, Codable, Equatable {
    case rewarded
    /// Chỉ nhận một phần vì sắp chạm hạn mức ngày.
    case partialCap
    case dailyCapReached
    case belowThreshold
    case notCompleted
    case implausible

    var message: String {
        switch self {
        case .rewarded: return ""
        case .partialCap: return "Chỉ nhận phần còn lại của hạn mức hôm nay."
        case .dailyCapReached: return "Hôm nay đã nhận đủ xu sân chơi. Kỷ lục vẫn được lưu!"
        case .belowThreshold: return "Chưa đủ điểm tối thiểu để nhận xu. Thử lại nhé!"
        case .notCompleted: return "Lượt chưa hoàn thành nên chưa có xu."
        case .implausible: return "Kết quả không hợp lệ nên không tính xu."
        }
    }
}

struct MinigameReward: Equatable {
    /// Xu thực nhận (sau hạn mức).
    var coins: Int
    /// Xu tính theo kết quả, trước hạn mức.
    var earned: Int
    var note: MinigameRewardNote
}

/// Một lượt đã lưu. `id` = sessionID (khóa chống trao thưởng hai lần).
struct MinigameResultRecord: Codable, Equatable, Identifiable {
    var id: UUID
    var kind: MinigameKind
    var score: Int
    var primary: Int
    var secondary: Int
    var level: MemoryLevel?
    var activeSeconds: Double
    var species: String
    var startedAt: Date
    var finishedAt: Date
    /// Ngày địa phương lúc kết thúc lượt — dùng tính hạn mức.
    var day: DayKey
    var coins: Int
    var earned: Int
    var note: MinigameRewardNote
}

enum MinigamePolicy {
    /// Kiểm tra kết quả có hợp lý với thời gian chơi không.
    static func isPlausible(_ o: MinigameOutcome) -> Bool {
        guard o.score >= 0, o.primary >= 0, o.secondary >= 0, o.activeSeconds.isFinite, o.activeSeconds >= 0,
              o.activeSeconds <= 6 * 3600 else { return false }
        switch o.kind {
        case .cloudJump:
            let maxMeters = MinigameConfig.jumpMaxMetersPerSecond * o.activeSeconds + 5
            return Double(o.primary) <= maxMeters
                && o.secondary <= o.primary / 2 + 5
                && o.score == CloudJumpEngine.score(heightMeters: o.primary, stars: o.secondary)
        case .giftBasket:
            return o.activeSeconds <= MinigameConfig.basketDuration + 1
                && Double(o.score) <= MinigameConfig.basketMaxPointsPerSecond * o.activeSeconds + 5
        case .memoryMatch:
            guard let level = o.level else { return false }
            return o.secondary <= level.pairs
                && o.primary >= o.secondary
                && (!o.completed || (o.secondary == level.pairs
                                     && o.activeSeconds >= Double(level.pairs) * MinigameConfig.memoryMinSecondsPerPair))
        case .blockPuzzle:
            // primary = số đường đã xóa, secondary = số khối đã đặt (mỗi khối 1–5 ô; mỗi ô góp vào tối đa 2 đường).
            let moves = o.secondary, lines = o.primary
            return Double(moves) <= MinigameConfig.blocksMaxMovesPerSecond * o.activeSeconds + 3
                && lines * 4 <= moves * 5 + 4
                && o.score >= moves
                && o.score <= moves * 5 + lines * 110
                && Double(o.score) <= MinigameConfig.blocksMaxPointsPerSecond * o.activeSeconds + 100
        case .sweetMerge:
            // primary = giá trị món lớn nhất, secondary = số lượt vuốt. Mỗi lượt sinh tối đa 4 giá trị mới,
            // và món bậc L dựng từ món bậc 2 đã cho ít nhất (L − 2) × giá trị của nó.
            let moves = o.secondary, top = o.primary
            let level = SweetLadder.level(ofValue: top)
            return level >= 1 && level <= 17
                && Double(moves) <= MinigameConfig.mergeMaxMovesPerSecond * o.activeSeconds + 3
                && top <= 4 * (moves + 2)
                && o.score >= top * max(0, level - 2)
                && o.score <= 64 * (moves + 2)
                && Double(o.score) <= MinigameConfig.mergeMaxPointsPerSecond * o.activeSeconds + 200
        }
    }

    /// Xu tính theo kết quả (trước hạn mức ngày).
    static func coins(for o: MinigameOutcome) -> (Int, MinigameRewardNote) {
        guard isPlausible(o) else { return (0, .implausible) }
        guard o.completed else { return (0, .notCompleted) }
        let raw: Int
        switch o.kind {
        case .cloudJump:
            guard o.primary >= MinigameConfig.jumpMinHeight else { return (0, .belowThreshold) }
            raw = o.score / MinigameConfig.jumpPointsPerCoin
        case .giftBasket:
            guard o.activeSeconds >= MinigameConfig.basketDuration - 0.5 else { return (0, .notCompleted) }
            guard o.score >= MinigameConfig.basketMinScore else { return (0, .belowThreshold) }
            raw = o.score / MinigameConfig.basketPointsPerCoin
        case .memoryMatch:
            guard let level = o.level else { return (0, .implausible) }
            var c = level == .easy ? MinigameConfig.memoryBaseEasy : MinigameConfig.memoryBaseMedium
            if o.primary <= level.pairs * 2 { c += 1 }
            if o.primary <= level.pairs + 3 { c += 1 }
            if o.activeSeconds <= level.fastSeconds { c += 1 }
            raw = c
        case .blockPuzzle:
            guard o.score >= MinigameConfig.blocksMinScore else { return (0, .belowThreshold) }
            raw = o.score / MinigameConfig.blocksPointsPerCoin
        case .sweetMerge:
            guard o.score >= MinigameConfig.mergeMinScore else { return (0, .belowThreshold) }
            raw = o.score / MinigameConfig.mergePointsPerCoin
        }
        let coins = min(MinigameConfig.maxCoinsPerRun, max(1, raw))
        return (coins, .rewarded)
    }

    /// Thưởng thực nhận khi đã nhận `awardedToday` xu Sân chơi trong ngày kết thúc lượt.
    static func reward(for o: MinigameOutcome, awardedToday: Int) -> MinigameReward {
        let (earned, note) = coins(for: o)
        guard note == .rewarded else { return MinigameReward(coins: 0, earned: 0, note: note) }
        let left = max(0, MinigameConfig.dailyCoinCap - awardedToday)
        if left == 0 { return MinigameReward(coins: 0, earned: earned, note: .dailyCapReached) }
        if left < earned { return MinigameReward(coins: left, earned: earned, note: .partialCap) }
        return MinigameReward(coins: earned, earned: earned, note: .rewarded)
    }

    static func awarded(on day: DayKey, results: [MinigameResultRecord]) -> Int {
        results.filter { $0.day == day }.reduce(0) { $0 + $1.coins }
    }

    static func best(_ kind: MinigameKind, results: [MinigameResultRecord]) -> MinigameResultRecord? {
        results.filter { $0.kind == kind }.max { a, b in
            a.score != b.score ? a.score < b.score : a.finishedAt > b.finishedAt
        }
    }

    /// Kết quả nên giữ khi cắt bớt lịch sử: mới nhất `keep` lượt, mọi lượt kết thúc từ `since`
    /// (vài ngày gần đây — đủ tính hạn mức và kiểm tra bản sao lưu) và kỷ lục của từng game.
    static func retained(_ results: [MinigameResultRecord], since: Date, keep: Int = 200) -> Set<UUID> {
        var ids = Set(results.sorted { $0.finishedAt > $1.finishedAt }.prefix(keep).map(\.id))
        ids.formUnion(results.filter { $0.finishedAt >= since }.map(\.id))
        for kind in MinigameKind.allCases {
            if let b = best(kind, results: results) { ids.insert(b.id) }
        }
        return ids
    }
}
