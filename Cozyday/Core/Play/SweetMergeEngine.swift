import Foundation

enum MergeDirection: String, CaseIterable, Equatable {
    case up, down, left, right

    var label: String {
        switch self {
        case .up: return "Gộp lên"
        case .down: return "Gộp xuống"
        case .left: return "Gộp sang trái"
        case .right: return "Gộp sang phải"
        }
    }
}

/// Một món bánh trên bàn Gộp Bánh. `level` 1 = kẹo (giá trị 2), mỗi bậc gấp đôi.
struct SweetTile: Identifiable, Equatable {
    let id: Int
    var level: Int
    /// Chỉ số ô = hàng × 4 + cột.
    var index: Int
    /// Số lần món này được gộp lên (để giao diện nảy nhẹ khi vừa gộp).
    var merges = 0

    var value: Int { SweetLadder.value(level) }
}

/// Bậc thang món ngọt.
enum SweetLadder {
    static let names = ["kẹo", "bánh quy", "donut", "cupcake", "bánh kem dâu", "bánh kem 2 tầng",
                        "bánh kem 3 tầng", "tháp bánh su", "bánh kem cầu vồng", "lâu đài bánh ngọt", "vương miện kẹo"]

    static func value(_ level: Int) -> Int { 1 << max(1, min(30, level)) }

    static func name(_ level: Int) -> String {
        guard level >= 1 else { return "" }
        return level <= names.count ? names[level - 1] : "ngôi sao ngọt"
    }

    /// Bậc của một giá trị (2 → 1, 4 → 2…). 0 nếu không phải lũy thừa của 2 từ 2 trở lên.
    static func level(ofValue v: Int) -> Int {
        guard v >= 2, v & (v - 1) == 0 else { return 0 }
        return v.trailingZeroBitCount
    }
}

struct SweetMerge: Equatable {
    /// Món còn lại (giữ id, lên bậc) và món bị gộp vào.
    var survivor: Int
    var consumed: Int
    var index: Int
    var level: Int
}

struct SweetMoveResult: Equatable {
    var direction: MergeDirection
    /// Vị trí mới của mọi món đã trượt (id → ô).
    var slides: [Int: Int]
    var merges: [SweetMerge]
    /// Món bị gộp, ở vị trí cuối cùng (để vẽ trượt vào rồi biến mất).
    var consumed: [SweetTile]
    var spawned: SweetTile?
    var points: Int
    var gameOver: Bool
    /// Bậc cao nhất vừa tạo ra trong lần vuốt này (0 nếu không gộp).
    var topMergeLevel: Int { merges.map(\.level).max() ?? 0 }
}

/// Logic Gộp Bánh — thuần, có seed. Bàn 4×4 kiểu 2048: vuốt một hướng, mọi món trượt hết cỡ; hai món cùng loại
/// chạm nhau thì gộp lên một bậc (mỗi món chỉ gộp một lần mỗi lượt vuốt). Sau mỗi lượt vuốt có thay đổi, một món mới
/// xuất hiện ở ô trống (90% kẹo, 10% bánh quy). Hết lượt khi bàn đầy và không còn hai món cạnh nhau giống nhau.
struct SweetMergeEngine: Equatable {
    static let size = 4
    static let secondLevelChance = 0.1

    private(set) var tiles: [SweetTile] = []
    private(set) var score = 0
    private(set) var moves = 0
    private(set) var mergesMade = 0
    private(set) var isOver = false
    private var rng: SeededRandom
    private var nextID = 1

    static func == (l: SweetMergeEngine, r: SweetMergeEngine) -> Bool {
        l.tiles == r.tiles && l.score == r.score && l.moves == r.moves && l.isOver == r.isOver
    }

    init(seed: UInt64) {
        rng = SeededRandom(seed: seed)
        spawn()
        spawn()
    }

    /// Chỉ dùng trong test: bàn dựng sẵn (bậc theo từng ô, 0 = trống).
    init(seed: UInt64, levels: [Int]) {
        rng = SeededRandom(seed: seed)
        for (i, l) in levels.prefix(Self.size * Self.size).enumerated() where l > 0 {
            tiles.append(SweetTile(id: nextID, level: l, index: i))
            nextID += 1
        }
        isOver = !canMove
    }

    // MARK: Truy vấn

    func tile(at index: Int) -> SweetTile? { tiles.first { $0.index == index } }

    /// Bậc ở từng ô (0 = trống).
    var levels: [Int] {
        var grid = Array(repeating: 0, count: Self.size * Self.size)
        for t in tiles { grid[t.index] = t.level }
        return grid
    }

    var highestLevel: Int { tiles.map(\.level).max() ?? 0 }
    var highestValue: Int { highestLevel > 0 ? SweetLadder.value(highestLevel) : 0 }
    var emptyCount: Int { Self.size * Self.size - tiles.count }

    var canMove: Bool {
        if tiles.count < Self.size * Self.size { return true }
        let g = levels
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                let v = g[r * Self.size + c]
                if c + 1 < Self.size && g[r * Self.size + c + 1] == v { return true }
                if r + 1 < Self.size && g[(r + 1) * Self.size + c] == v { return true }
            }
        }
        return false
    }

    func canMove(_ d: MergeDirection) -> Bool {
        var copy = self
        return copy.slide(d) != nil
    }

    /// Các ô của một hàng/cột theo thứ tự trượt (ô đầu tiên là ô món dồn tới).
    static func line(_ i: Int, _ d: MergeDirection) -> [Int] {
        let s = size
        switch d {
        case .left: return (0..<s).map { i * s + $0 }
        case .right: return (0..<s).reversed().map { i * s + $0 }
        case .up: return (0..<s).map { $0 * s + i }
        case .down: return (0..<s).reversed().map { $0 * s + i }
        }
    }

    // MARK: Vuốt

    /// Vuốt một hướng. Trả về nil nếu không món nào di chuyển (không tính lượt, không có món mới).
    @discardableResult
    mutating func move(_ d: MergeDirection) -> SweetMoveResult? {
        guard !isOver, var result = slide(d) else { return nil }
        moves += 1
        mergesMade += result.merges.count
        score += result.points
        result.spawned = spawn()
        isOver = !canMove
        result.gameOver = isOver
        return result
    }

    /// Trượt + gộp, chưa sinh món mới.
    private mutating func slide(_ d: MergeDirection) -> SweetMoveResult? {
        var byIndex: [Int: SweetTile] = [:]
        for t in tiles { byIndex[t.index] = t }
        var next: [SweetTile] = []
        var slides: [Int: Int] = [:]
        var merges: [SweetMerge] = []
        var consumed: [SweetTile] = []
        var points = 0
        var changed = false
        for i in 0..<Self.size {
            let cells = Self.line(i, d)
            let row = cells.compactMap { byIndex[$0] }
            var target = 0
            var k = 0
            while k < row.count {
                var a = row[k]
                let dest = cells[target]
                // Mỗi món gộp tối đa một lần: sau khi gộp, bỏ qua cả hai món.
                if k + 1 < row.count, row[k + 1].level == a.level {
                    var b = row[k + 1]
                    a.level += 1
                    a.merges += 1
                    a.index = dest
                    b.index = dest
                    merges.append(SweetMerge(survivor: a.id, consumed: b.id, index: dest, level: a.level))
                    consumed.append(b)
                    points += SweetLadder.value(a.level)
                    changed = true
                    k += 2
                } else {
                    if a.index != dest { changed = true }
                    a.index = dest
                    k += 1
                }
                slides[a.id] = dest
                next.append(a)
                target += 1
            }
        }
        guard changed else { return nil }
        tiles = next.sorted { $0.index < $1.index }
        return SweetMoveResult(direction: d, slides: slides, merges: merges, consumed: consumed, spawned: nil, points: points, gameOver: false)
    }

    @discardableResult
    private mutating func spawn() -> SweetTile? {
        let occupied = Set(tiles.map(\.index))
        let empty = (0..<(Self.size * Self.size)).filter { !occupied.contains($0) }
        guard !empty.isEmpty else { return nil }
        let index = empty[Int.random(in: 0..<empty.count, using: &rng)]
        let level = Double.random(in: 0..<1, using: &rng) < Self.secondLevelChance ? 2 : 1
        let t = SweetTile(id: nextID, level: level, index: index)
        nextID += 1
        tiles.append(t)
        tiles.sort { $0.index < $1.index }
        return t
    }
}

/// Người chơi máy (xem trước trong bản Debug và test): ưu tiên dồn về góc dưới trái, chọn nước nhiều điểm và nhiều ô trống.
enum SweetMergeBot {
    static func bestMove(_ e: SweetMergeEngine) -> MergeDirection? {
        let order: [MergeDirection] = [.down, .left, .right, .up]
        var best: (MergeDirection, Int)?
        for (rank, d) in order.enumerated() {
            var copy = e
            guard let r = copy.move(d) else { continue }
            let value = r.points * 2 + copy.emptyCount * 8 - rank * 6 - (d == .up ? 40 : 0)
            if best == nil || value > best!.1 { best = (d, value) }
        }
        return best?.0
    }
}
