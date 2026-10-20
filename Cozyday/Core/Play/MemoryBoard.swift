import Foundation

enum CardState: Equatable {
    case down, up, matched
}

struct MemoryCard: Identifiable, Equatable {
    let id: Int
    /// Hình trên thẻ (chỉ số trong `MemoryBoard.faces`).
    let face: Int
    var state: CardState = .down
}

enum FlipResult: Equatable {
    /// Không làm gì: đang khóa chờ úp cặp sai, thẻ đã mở/đã ghép, bàn đã xong hoặc chỉ số sai.
    case ignored
    case opened
    case matched
    /// Hai thẻ khác nhau: bàn khóa tới khi `resolveMismatch(token:)` được gọi với đúng mã này.
    case mismatch(token: Int)
    case completed
}

/// Logic Lật Thẻ — thuần. Mỗi lần mở tối đa hai thẻ; cặp sai khóa bàn cho tới khi được úp lại,
/// và mã `token` bảo đảm lệnh úp trễ của một lần trước (hay của bàn cũ) không làm hỏng bàn hiện tại.
struct MemoryBoard: Equatable {
    /// Các loài dùng làm hình thẻ — hình dạng và màu lông khác nhau rõ.
    static let faces: [PetSpecies] = [.cat, .bunny, .duck, .frog, .panda, .penguin, .fox, .capybara]

    let level: MemoryLevel
    private(set) var cards: [MemoryCard]
    /// Số lượt: mỗi lần mở thẻ thứ hai = 1 lượt.
    private(set) var moves = 0
    private(set) var pairsFound = 0
    private(set) var pending: (a: Int, b: Int, token: Int)?
    private var tokenCounter = 0

    static func == (l: MemoryBoard, r: MemoryBoard) -> Bool {
        l.level == r.level && l.cards == r.cards && l.moves == r.moves && l.pairsFound == r.pairsFound
            && l.pending?.a == r.pending?.a && l.pending?.b == r.pending?.b && l.pending?.token == r.pending?.token
    }

    init(level: MemoryLevel, seed: UInt64) {
        self.level = level
        var rng = SeededRandom(seed: seed)
        let faces = Array(0..<Self.faces.count).shuffled(using: &rng).prefix(level.pairs)
        let deck = (faces + faces).shuffled(using: &rng)
        cards = deck.enumerated().map { MemoryCard(id: $0.offset, face: $0.element) }
    }

    var isLocked: Bool { pending != nil }
    var isComplete: Bool { pairsFound == level.pairs }
    var openUnmatched: [Int] { cards.indices.filter { cards[$0].state == .up } }

    mutating func flip(_ index: Int) -> FlipResult {
        guard !isComplete, !isLocked, cards.indices.contains(index), cards[index].state == .down else { return .ignored }
        let open = openUnmatched
        guard open.count < 2 else { return .ignored }
        cards[index].state = .up
        guard let first = open.first else { return .opened }
        moves += 1
        if cards[first].face == cards[index].face {
            cards[first].state = .matched
            cards[index].state = .matched
            pairsFound += 1
            return isComplete ? .completed : .matched
        }
        tokenCounter += 1
        pending = (first, index, tokenCounter)
        return .mismatch(token: tokenCounter)
    }

    /// Úp lại cặp sai. Trả về false nếu mã không còn hiệu lực (đã úp rồi hoặc của lần khác).
    @discardableResult
    mutating func resolveMismatch(token: Int) -> Bool {
        guard let p = pending, p.token == token else { return false }
        cards[p.a].state = .down
        cards[p.b].state = .down
        pending = nil
        return true
    }

    /// Điểm: ghép càng ít lượt và càng nhanh càng cao (không bao giờ âm).
    static func score(level: MemoryLevel, moves: Int, seconds: Double) -> Int {
        let base = level.pairs * 100
        let extraMoves = max(0, moves - level.pairs)
        return max(level.pairs * 10, base - extraMoves * 15 - Int(seconds.rounded()))
    }
}
