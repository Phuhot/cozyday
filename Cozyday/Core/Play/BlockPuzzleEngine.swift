import Foundation

/// Một ô trên bàn Xếp Khối (hàng từ trên xuống, cột từ trái sang).
struct BlockCell: Hashable, Codable {
    var row: Int
    var col: Int
}

/// Hình khối cố định (1–5 ô). Ô đã chuẩn hóa: hàng/cột nhỏ nhất đều là 0.
struct BlockShape: Equatable {
    let id: Int
    let name: String
    let cells: [BlockCell]
    /// Trọng số khi bốc ngẫu nhiên (khối to, khó đặt ra ít hơn).
    let weight: Int

    var width: Int { (cells.map(\.col).max() ?? 0) + 1 }
    var height: Int { (cells.map(\.row).max() ?? 0) + 1 }

    /// Ô "cầm" khi đặt bằng chạm hoặc VoiceOver: ô gần tâm khung nhất.
    var anchor: BlockCell {
        let cr = Double(height - 1) / 2, cc = Double(width - 1) / 2
        return cells.min { a, b in
            let da = (Double(a.row) - cr) * (Double(a.row) - cr) + (Double(a.col) - cc) * (Double(a.col) - cc)
            let db = (Double(b.row) - cr) * (Double(b.row) - cr) + (Double(b.col) - cc) * (Double(b.col) - cc)
            return da != db ? da < db : (a.row, a.col) < (b.row, b.col)
        } ?? BlockCell(row: 0, col: 0)
    }

    /// Tạo hình từ sơ đồ chữ: "#" là ô có khối, mỗi phần tử là một hàng.
    init(id: Int, name: String, weight: Int, _ rows: [String]) {
        self.id = id
        self.name = name
        self.weight = weight
        var list: [BlockCell] = []
        for (r, line) in rows.enumerated() {
            for (c, ch) in line.enumerated() where ch == "#" { list.append(BlockCell(row: r, col: c)) }
        }
        cells = list
    }
}

/// Một khối đang chờ trong khay (3 ô khay).
struct BlockPiece: Identifiable, Equatable {
    let id: Int
    let shape: Int
    /// Màu kẹo dẻo (0..<BlockPuzzleEngine.colorCount).
    let color: Int
}

/// Kết quả một lần đặt khối.
struct BlockMoveResult: Equatable {
    var piece: BlockPiece
    var placed: [BlockCell]
    var clearedRows: [Int]
    var clearedCols: [Int]
    /// Các ô bị xóa (ô giao giữa hàng và cột chỉ tính một lần), kèm màu trước khi xóa — để vẽ hiệu ứng nổ.
    var clearedCells: [BlockCell]
    var clearedColors: [Int]
    var points: Int
    /// Số đường xóa trong lần đặt này (combo).
    var lines: Int { clearedRows.count + clearedCols.count }
    /// Số lần đặt liên tiếp có xóa đường (tính cả lần này; 0 nếu lần này không xóa).
    var streak: Int
    /// Khay vừa được phát bộ 3 khối mới.
    var refilled: Bool
    var gameOver: Bool
}

/// Logic Xếp Khối — thuần, có seed. Bàn 8×8; khay 3 khối; đặt hết 3 khối thì phát bộ mới. Hàng và cột đầy được xóa
/// cùng lúc. Hết lượt khi không khối nào còn lại trong khay đặt vừa chỗ nào.
struct BlockPuzzleEngine: Equatable {
    static let size = 8
    static let traySize = 3
    static let colorCount = 6
    static let pointsPerLine = 10
    static let streakBonusPerStep = 10
    static let maxStreakBonusSteps = 5

    /// Bộ hình cố định. Thứ tự và id không đổi (seed cũ vẫn ra cùng ván).
    static let shapes: [BlockShape] = {
        let defs: [(String, Int, [String])] = [
            ("một ô", 2, ["#"]),
            ("hai ô ngang", 3, ["##"]),
            ("hai ô dọc", 3, ["#", "#"]),
            ("ba ô ngang", 3, ["###"]),
            ("ba ô dọc", 3, ["#", "#", "#"]),
            ("bốn ô ngang", 2, ["####"]),
            ("bốn ô dọc", 2, ["#", "#", "#", "#"]),
            ("năm ô ngang", 1, ["#####"]),
            ("năm ô dọc", 1, ["#", "#", "#", "#", "#"]),
            ("vuông 2×2", 3, ["##", "##"]),
            ("góc nhỏ", 2, ["##", "#."]),
            ("góc nhỏ", 2, ["##", ".#"]),
            ("góc nhỏ", 2, ["#.", "##"]),
            ("góc nhỏ", 2, [".#", "##"]),
            ("chữ L", 1, ["#.", "#.", "##"]),
            ("chữ L", 1, ["###", "#.."]),
            ("chữ L", 1, ["##", ".#", ".#"]),
            ("chữ L", 1, ["..#", "###"]),
            ("chữ J", 1, [".#", ".#", "##"]),
            ("chữ J", 1, ["#..", "###"]),
            ("chữ J", 1, ["##", "#.", "#."]),
            ("chữ J", 1, ["###", "..#"]),
            ("chữ T", 1, ["###", ".#."]),
            ("chữ T", 1, [".#.", "###"]),
            ("chữ T", 1, ["#.", "##", "#."]),
            ("chữ T", 1, [".#", "##", ".#"]),
            ("chữ S", 1, [".##", "##."]),
            ("chữ S", 1, ["#.", "##", ".#"]),
            ("chữ Z", 1, ["##.", ".##"]),
            ("chữ Z", 1, [".#", "##", "#."]),
            ("góc lớn", 1, ["###", "#..", "#.."]),
            ("góc lớn", 1, ["###", "..#", "..#"]),
            ("góc lớn", 1, ["#..", "#..", "###"]),
            ("góc lớn", 1, ["..#", "..#", "###"])
        ]
        return defs.enumerated().map { BlockShape(id: $0.offset, name: $0.element.0, weight: $0.element.1, $0.element.2) }
    }()

    static func shape(_ id: Int) -> BlockShape { shapes[max(0, min(shapes.count - 1, id))] }

    /// Điểm một lần đặt: mỗi ô đặt 1 điểm; mỗi đường 10 điểm nhân số đường xóa cùng lúc (combo);
    /// thêm 10 điểm cho mỗi lần xóa liên tiếp trước đó (tối đa +50).
    static func points(cells: Int, lines: Int, streak: Int) -> Int {
        guard lines > 0 else { return cells }
        return cells + pointsPerLine * lines * lines + streakBonusPerStep * min(maxStreakBonusSteps, max(0, streak - 1))
    }

    /// 0 = trống, 1…colorCount = màu kẹo + 1. Chỉ số = hàng × 8 + cột.
    private(set) var board: [Int]
    private(set) var tray: [BlockPiece?]
    private(set) var score = 0
    private(set) var linesCleared = 0
    private(set) var piecesPlaced = 0
    private(set) var cellsPlaced = 0
    private(set) var streak = 0
    private(set) var bestStreak = 0
    /// Nhiều đường nhất xóa trong một lần đặt.
    private(set) var bestCombo = 0
    private(set) var isOver = false
    private var rng: SeededRandom
    private var nextID = 1

    static func == (l: BlockPuzzleEngine, r: BlockPuzzleEngine) -> Bool {
        l.board == r.board && l.tray == r.tray && l.score == r.score && l.linesCleared == r.linesCleared
            && l.piecesPlaced == r.piecesPlaced && l.streak == r.streak && l.isOver == r.isOver
    }

    init(seed: UInt64) {
        rng = SeededRandom(seed: seed)
        board = Array(repeating: 0, count: Self.size * Self.size)
        tray = Array(repeating: nil, count: Self.traySize)
        refill()
    }

    /// Chỉ dùng trong test: bàn và khay dựng sẵn.
    init(seed: UInt64, board: [Int], tray: [Int?]) {
        rng = SeededRandom(seed: seed)
        self.board = board.count == Self.size * Self.size ? board : Array(repeating: 0, count: Self.size * Self.size)
        self.tray = tray.prefix(Self.traySize).enumerated().map { i, s in s.map { BlockPiece(id: 100 + i, shape: $0, color: i % Self.colorCount) } }
        while self.tray.count < Self.traySize { self.tray.append(nil) }
        if self.tray.allSatisfy({ $0 == nil }) { refill() }
        isOver = !anyPieceFits
    }

    // MARK: Truy vấn

    func color(at cell: BlockCell) -> Int? {
        guard Self.contains(cell) else { return nil }
        let v = board[cell.row * Self.size + cell.col]
        return v == 0 ? nil : v - 1
    }

    func isFilled(_ cell: BlockCell) -> Bool { color(at: cell) != nil }

    var filledCount: Int { board.filter { $0 != 0 }.count }
    /// Tỉ lệ bàn đã kín (0…1).
    var fillRatio: Double { Double(filledCount) / Double(board.count) }

    static func contains(_ c: BlockCell) -> Bool { c.row >= 0 && c.col >= 0 && c.row < size && c.col < size }

    /// Các ô khối chiếm khi đặt góc trên trái tại (row, col).
    static func cells(of shape: BlockShape, row: Int, col: Int) -> [BlockCell] {
        shape.cells.map { BlockCell(row: $0.row + row, col: $0.col + col) }
    }

    func canPlace(shape id: Int, row: Int, col: Int) -> Bool {
        Self.cells(of: Self.shape(id), row: row, col: col).allSatisfy { Self.contains($0) && !isFilled($0) }
    }

    func fits(shape id: Int) -> Bool {
        let s = Self.shape(id)
        for r in 0...(Self.size - s.height) {
            for c in 0...(Self.size - s.width) where canPlace(shape: id, row: r, col: c) { return true }
        }
        return false
    }

    /// Mọi góc trên trái hợp lệ cho khối.
    func validOrigins(shape id: Int) -> [BlockCell] {
        let s = Self.shape(id)
        var list: [BlockCell] = []
        for r in 0...(Self.size - s.height) {
            for c in 0...(Self.size - s.width) where canPlace(shape: id, row: r, col: c) { list.append(BlockCell(row: r, col: c)) }
        }
        return list
    }

    var anyPieceFits: Bool { tray.contains { $0.map { fits(shape: $0.shape) } ?? false } }

    /// Hàng và cột sẽ đầy nếu đặt khối ở đây (để tô sáng trước khi thả).
    func linesCompleted(shape id: Int, row: Int, col: Int) -> (rows: [Int], cols: [Int]) {
        guard canPlace(shape: id, row: row, col: col) else { return ([], []) }
        var filled = Set(Self.cells(of: Self.shape(id), row: row, col: col))
        for i in board.indices where board[i] != 0 { filled.insert(BlockCell(row: i / Self.size, col: i % Self.size)) }
        let rows = (0..<Self.size).filter { r in (0..<Self.size).allSatisfy { filled.contains(BlockCell(row: r, col: $0)) } }
        let cols = (0..<Self.size).filter { c in (0..<Self.size).allSatisfy { filled.contains(BlockCell(row: $0, col: c)) } }
        return (rows, cols)
    }

    // MARK: Đặt khối

    /// Đặt khối ở ô khay `slot` với góc trên trái (row, col). Trả về nil nếu không hợp lệ (bàn không đổi).
    @discardableResult
    mutating func place(slot: Int, row: Int, col: Int) -> BlockMoveResult? {
        guard !isOver, tray.indices.contains(slot), let piece = tray[slot], canPlace(shape: piece.shape, row: row, col: col) else { return nil }
        let placed = Self.cells(of: Self.shape(piece.shape), row: row, col: col)
        for c in placed { board[c.row * Self.size + c.col] = piece.color + 1 }
        tray[slot] = nil
        piecesPlaced += 1
        cellsPlaced += placed.count

        // Hàng và cột đầy được tìm trên cùng một trạng thái rồi xóa cùng lúc.
        let rows = (0..<Self.size).filter { r in (0..<Self.size).allSatisfy { board[r * Self.size + $0] != 0 } }
        let cols = (0..<Self.size).filter { c in (0..<Self.size).allSatisfy { board[$0 * Self.size + c] != 0 } }
        var cleared = Set<BlockCell>()
        for r in rows { for c in 0..<Self.size { cleared.insert(BlockCell(row: r, col: c)) } }
        for c in cols { for r in 0..<Self.size { cleared.insert(BlockCell(row: r, col: c)) } }
        let clearedList = cleared.sorted { ($0.row, $0.col) < ($1.row, $1.col) }
        let clearedColors = clearedList.map { board[$0.row * Self.size + $0.col] - 1 }
        for c in clearedList { board[c.row * Self.size + c.col] = 0 }

        let lines = rows.count + cols.count
        if lines > 0 {
            streak += 1
            bestStreak = max(bestStreak, streak)
            bestCombo = max(bestCombo, lines)
        } else {
            streak = 0
        }
        linesCleared += lines
        let points = Self.points(cells: placed.count, lines: lines, streak: streak)
        score += points

        var refilled = false
        if tray.allSatisfy({ $0 == nil }) {
            refill()
            refilled = true
        }
        isOver = !anyPieceFits
        return BlockMoveResult(piece: piece, placed: placed, clearedRows: rows, clearedCols: cols, clearedCells: clearedList,
                               clearedColors: clearedColors, points: points, streak: lines > 0 ? streak : 0,
                               refilled: refilled, gameOver: isOver)
    }

    /// Đặt bằng chạm / VoiceOver: ô `anchor` của khối nằm ở `cell`.
    @discardableResult
    mutating func place(slot: Int, anchoredAt cell: BlockCell) -> BlockMoveResult? {
        guard tray.indices.contains(slot), let piece = tray[slot] else { return nil }
        let a = Self.shape(piece.shape).anchor
        return place(slot: slot, row: cell.row - a.row, col: cell.col - a.col)
    }

    // MARK: Phát khối

    /// Phát bộ 3 khối mới. Thử vài lần để bộ mới có ít nhất một khối đặt vừa (vẫn hoàn toàn theo seed).
    private mutating func refill() {
        var best: [BlockPiece] = []
        for attempt in 0..<6 {
            var set: [BlockPiece] = []
            for _ in 0..<Self.traySize {
                set.append(BlockPiece(id: nextID, shape: randomShape(), color: Int.random(in: 0..<Self.colorCount, using: &rng)))
                nextID += 1
            }
            best = set
            if attempt == 5 || set.contains(where: { fits(shape: $0.shape) }) { break }
        }
        tray = best
    }

    private mutating func randomShape() -> Int {
        let total = Self.shapes.reduce(0) { $0 + $1.weight }
        var roll = Int.random(in: 0..<total, using: &rng)
        for s in Self.shapes {
            if roll < s.weight { return s.id }
            roll -= s.weight
        }
        return 0
    }
}

/// Người chơi máy đơn giản (xem trước trong bản Debug và test): chọn nước xóa nhiều đường nhất,
/// rồi nước để lại bàn "gọn" nhất (ít ô trống lẻ).
enum BlockPuzzleBot {
    struct Move: Equatable { var slot: Int; var row: Int; var col: Int }

    static func bestMove(_ e: BlockPuzzleEngine) -> Move? {
        var best: (Move, Int)?
        for (slot, piece) in e.tray.enumerated() {
            guard let piece else { continue }
            for o in e.validOrigins(shape: piece.shape) {
                var copy = e
                guard let r = copy.place(slot: slot, row: o.row, col: o.col) else { continue }
                let value = r.lines * 100 - holes(copy) * 3 - (copy.isOver ? 1000 : 0) + o.row
                if best == nil || value > best!.1 { best = (Move(slot: slot, row: o.row, col: o.col), value) }
            }
        }
        return best?.0
    }

    /// Số ô trống bị bao quanh (cả bốn phía là khối hoặc mép bàn).
    static func holes(_ e: BlockPuzzleEngine) -> Int {
        var n = 0
        let s = BlockPuzzleEngine.size
        for r in 0..<s {
            for c in 0..<s where !e.isFilled(BlockCell(row: r, col: c)) {
                let around = [BlockCell(row: r - 1, col: c), BlockCell(row: r + 1, col: c), BlockCell(row: r, col: c - 1), BlockCell(row: r, col: c + 1)]
                if around.allSatisfy({ !BlockPuzzleEngine.contains($0) || e.isFilled($0) }) { n += 1 }
            }
        }
        return n
    }
}
