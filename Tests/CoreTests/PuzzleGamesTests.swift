import Foundation
import XCTest
#if canImport(CozyCore)
@testable import CozyCore
#else
@testable import Cozyday
#endif

/// Xếp Khối (kiểu Block Blast) và Gộp Bánh (kiểu 2048).
final class BlockPuzzleTests: XCTestCase {
    private let n = BlockPuzzleEngine.size

    /// Bàn từ sơ đồ 8 dòng: "#" có khối, "." trống.
    private func board(_ rows: [String]) -> [Int] {
        var b = Array(repeating: 0, count: n * n)
        for (r, line) in rows.enumerated() {
            for (c, ch) in line.enumerated() where ch == "#" { b[r * n + c] = 1 }
        }
        return b
    }

    private func shapeID(_ rows: [String]) -> Int {
        let target = Set(BlockShape(id: -1, name: "", weight: 1, rows).cells)
        return BlockPuzzleEngine.shapes.first { Set($0.cells) == target }!.id
    }

    func testShapesAreNormalizedUniqueAndCoverClassicPieces() {
        let shapes = BlockPuzzleEngine.shapes
        XCTAssertGreaterThanOrEqual(shapes.count, 20)
        var seen = Set<Set<BlockCell>>()
        for (i, s) in shapes.enumerated() {
            XCTAssertEqual(s.id, i)
            XCTAssertTrue((1...5).contains(s.cells.count), s.name)
            XCTAssertEqual(s.cells.map(\.row).min(), 0)
            XCTAssertEqual(s.cells.map(\.col).min(), 0)
            XCTAssertGreaterThan(s.weight, 0)
            XCTAssertTrue(s.cells.contains(s.anchor))
            XCTAssertTrue(seen.insert(Set(s.cells)).inserted, "hình trùng: \(s.name)")
        }
        // Có đủ một ô, đường thẳng 2–5, vuông, L, T, S/Z.
        _ = shapeID(["#"]); _ = shapeID(["#####"]); _ = shapeID(["#", "#", "#", "#", "#"])
        _ = shapeID(["##", "##"]); _ = shapeID(["#.", "#.", "##"]); _ = shapeID(["###", ".#."])
        _ = shapeID([".##", "##."]); _ = shapeID(["##.", ".##"])
    }

    func testPlacementValidity() {
        let square = shapeID(["##", "##"])
        let line5 = shapeID(["#####"])
        var e = BlockPuzzleEngine(seed: 1, board: board(["", "", "", "...#"]), tray: [square, line5, nil])
        XCTAssertTrue(e.canPlace(shape: square, row: 0, col: 0))
        XCTAssertTrue(e.canPlace(shape: square, row: 6, col: 6))
        XCTAssertFalse(e.canPlace(shape: square, row: 7, col: 0), "lòi ra ngoài bàn")
        XCTAssertFalse(e.canPlace(shape: square, row: 0, col: -1))
        XCTAssertFalse(e.canPlace(shape: line5, row: 0, col: 4))
        XCTAssertTrue(e.canPlace(shape: line5, row: 0, col: 3))
        XCTAssertFalse(e.canPlace(shape: square, row: 2, col: 2), "đè lên khối có sẵn")
        XCTAssertFalse(e.canPlace(shape: line5, row: 3, col: 1))

        let before = e
        XCTAssertNil(e.place(slot: 0, row: 2, col: 3), "chỗ không hợp lệ")
        XCTAssertNil(e.place(slot: 2, row: 0, col: 0), "ô khay trống")
        XCTAssertNil(e.place(slot: 5, row: 0, col: 0))
        XCTAssertEqual(e, before, "đặt sai không đổi gì")

        let r = e.place(slot: 0, row: 0, col: 0)
        XCTAssertEqual(r?.placed.count, 4)
        XCTAssertEqual(r?.points, 4)
        XCTAssertEqual(r?.lines, 0)
        XCTAssertNil(e.tray[0], "khối đã đặt rời khay")
        XCTAssertTrue(e.isFilled(BlockCell(row: 1, col: 1)))
        XCTAssertNil(e.place(slot: 0, row: 4, col: 4), "không đặt lại được khối đã dùng")
        XCTAssertEqual(e.piecesPlaced, 1)
        XCTAssertEqual(e.score, 4)
    }

    func testRowsAndColumnsClearTogether() {
        // Hàng 0 và cột 0 thiếu đúng ô góc; thêm một ô ở (5,5) không thuộc đường nào.
        var rows = Array(repeating: "#.......", count: 8)
        rows[0] = ".#######"
        rows[5] = "#....#.."
        let single = shapeID(["#"])
        var e = BlockPuzzleEngine(seed: 2, board: board(rows), tray: [single, single, single])
        let preview = e.linesCompleted(shape: single, row: 0, col: 0)
        XCTAssertEqual(preview.rows, [0])
        XCTAssertEqual(preview.cols, [0])
        let r = e.place(slot: 0, row: 0, col: 0)!
        XCTAssertEqual(r.clearedRows, [0])
        XCTAssertEqual(r.clearedCols, [0])
        XCTAssertEqual(r.lines, 2)
        XCTAssertEqual(r.clearedCells.count, 15, "ô giao chỉ tính một lần")
        XCTAssertEqual(r.clearedColors.count, 15)
        XCTAssertEqual(r.points, 1 + 10 * 2 * 2, "combo 2 đường: 10 × 2 × 2")
        XCTAssertEqual(e.filledCount, 1)
        XCTAssertTrue(e.isFilled(BlockCell(row: 5, col: 5)))
        XCTAssertEqual(e.linesCleared, 2)
        XCTAssertEqual(e.bestCombo, 2)
    }

    func testComboAndStreakScoring() {
        XCTAssertEqual(BlockPuzzleEngine.points(cells: 3, lines: 0, streak: 0), 3)
        XCTAssertEqual(BlockPuzzleEngine.points(cells: 3, lines: 1, streak: 1), 13)
        XCTAssertEqual(BlockPuzzleEngine.points(cells: 3, lines: 2, streak: 1), 43)
        XCTAssertEqual(BlockPuzzleEngine.points(cells: 3, lines: 3, streak: 1), 93)
        XCTAssertEqual(BlockPuzzleEngine.points(cells: 4, lines: 1, streak: 3), 4 + 10 + 20)
        XCTAssertEqual(BlockPuzzleEngine.points(cells: 1, lines: 1, streak: 50), 1 + 10 + 50, "thưởng chuỗi tối đa +50")

        // Hai lần xóa liền nhau: lần hai có thưởng chuỗi; lần không xóa thì chuỗi về 0.
        let single = shapeID(["#"])
        var rows = Array(repeating: "........", count: 8)
        rows[0] = "#######."
        rows[1] = "#######."
        var e = BlockPuzzleEngine(seed: 3, board: board(rows), tray: [single, single, single])
        let a = e.place(slot: 0, row: 0, col: 7)!
        XCTAssertEqual(a.streak, 1)
        XCTAssertEqual(a.points, 11)
        let b = e.place(slot: 1, row: 1, col: 7)!
        XCTAssertEqual(b.streak, 2)
        XCTAssertEqual(b.points, 1 + 10 + 10)
        XCTAssertEqual(e.bestStreak, 2)
        let c = e.place(slot: 2, row: 7, col: 7)!
        XCTAssertEqual(c.streak, 0)
        XCTAssertEqual(c.points, 1)
        XCTAssertEqual(e.streak, 0)
        XCTAssertEqual(e.score, 11 + 21 + 1)
    }

    func testNewSetOfThreeOnlyAfterAllPlaced() {
        var e = BlockPuzzleEngine(seed: 4)
        let first = e.tray.compactMap { $0?.id }
        XCTAssertEqual(first.count, 3)
        var refills: [Bool] = []
        for _ in 0..<3 {
            let m = BlockPuzzleBot.bestMove(e)!
            refills.append(e.place(slot: m.slot, row: m.row, col: m.col)!.refilled)
        }
        XCTAssertEqual(refills, [false, false, true])
        let second = e.tray.compactMap { $0?.id }
        XCTAssertEqual(second.count, 3)
        XCTAssertTrue(Set(first).isDisjoint(with: second), "bộ mới là khối mới")
    }

    func testGameOverWhenNoPieceFits() {
        // Bàn kín xen kẽ: không có hai ô trống cạnh nhau, không hàng/cột nào đầy.
        let checker = (0..<8).map { r in String((0..<8).map { c in (r + c) % 2 == 0 ? "#" : "." }) }
        let domino = shapeID(["##"]), square = shapeID(["##", "##"]), single = shapeID(["#"])
        let stuck = BlockPuzzleEngine(seed: 5, board: board(checker), tray: [domino, square, nil])
        XCTAssertTrue(stuck.isOver)
        XCTAssertFalse(stuck.anyPieceFits)
        var e = BlockPuzzleEngine(seed: 5, board: board(checker), tray: [single, domino, nil])
        XCTAssertFalse(e.isOver, "còn khối một ô thì vẫn chơi được")
        let r = e.place(slot: 0, row: 0, col: 1)!
        XCTAssertTrue(r.gameOver, "chỉ còn khối hai ô, không chỗ nào vừa")
        XCTAssertTrue(e.isOver)
        XCTAssertNil(e.place(slot: 1, row: 0, col: 0), "hết lượt thì không đặt được nữa")
    }

    func testSameSeedSameGame() {
        func play(_ seed: UInt64) -> BlockPuzzleEngine {
            var e = BlockPuzzleEngine(seed: seed)
            for _ in 0..<40 where !e.isOver {
                guard let m = BlockPuzzleBot.bestMove(e) else { break }
                e.place(slot: m.slot, row: m.row, col: m.col)
            }
            return e
        }
        XCTAssertEqual(play(77), play(77))
        XCTAssertNotEqual(BlockPuzzleEngine(seed: 1).tray.map { $0?.shape }, BlockPuzzleEngine(seed: 2).tray.map { $0?.shape })
    }

    func testBotPlaysToGameOverAndResultIsPlausible() {
        var scores: [Int] = []
        for seed in UInt64(1)...8 {
            var e = BlockPuzzleEngine(seed: seed)
            var moves = 0
            var total = 0
            while !e.isOver, moves < 1500 {
                guard let m = BlockPuzzleBot.bestMove(e) else { break }
                total += e.place(slot: m.slot, row: m.row, col: m.col)!.points
                moves += 1
            }
            XCTAssertTrue(e.isOver, "seed \(seed): phải hết lượt trong giới hạn")
            XCTAssertNil(BlockPuzzleBot.bestMove(e))
            XCTAssertEqual(total, e.score)
            XCTAssertEqual(moves, e.piecesPlaced)
            // Chơi 1 giây/khối: kết quả hợp lệ.
            let o = MinigameOutcome(sessionID: UUID(), kind: .blockPuzzle, score: e.score, primary: e.linesCleared,
                                    secondary: e.piecesPlaced, level: nil, activeSeconds: Double(moves), completed: true,
                                    species: "cat", startedAt: Date(), finishedAt: Date())
            XCTAssertTrue(MinigamePolicy.isPlausible(o), "seed \(seed): \(e.score) điểm, \(e.linesCleared) đường, \(moves) khối")
            scores.append(e.score)
        }
        print("Xếp Khối — điểm máy chơi:", scores)
    }
}

final class SweetMergeTests: XCTestCase {
    /// Bàn từ 4 hàng bậc.
    private func engine(_ rows: [[Int]], seed: UInt64 = 1) -> SweetMergeEngine {
        SweetMergeEngine(seed: seed, levels: rows.flatMap { $0 })
    }

    private func row(_ e: SweetMergeEngine, _ r: Int) -> [Int] { Array(e.levels[(r * 4)..<(r * 4 + 4)]) }

    func testLadder() {
        XCTAssertEqual(SweetLadder.value(1), 2)
        XCTAssertEqual(SweetLadder.value(11), 2048)
        XCTAssertEqual(SweetLadder.level(ofValue: 2), 1)
        XCTAssertEqual(SweetLadder.level(ofValue: 64), 6)
        XCTAssertEqual(SweetLadder.level(ofValue: 6), 0)
        XCTAssertEqual(SweetLadder.level(ofValue: 1), 0)
        XCTAssertEqual(SweetLadder.name(1), "kẹo")
        XCTAssertEqual(SweetLadder.name(4), "cupcake")
        XCTAssertFalse(SweetLadder.name(20).isEmpty)
    }

    func testSlideAndMergeLeftRight() {
        var e = engine([[1, 1, 1, 1], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
        let r = e.move(.left)!
        XCTAssertEqual(row(e, 0).prefix(2), [2, 2])
        XCTAssertEqual(r.points, 8)
        XCTAssertEqual(r.merges.count, 2)
        XCTAssertEqual(e.score, 8)
        XCTAssertEqual(e.moves, 1)

        var three = engine([[1, 1, 1, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
        three.move(.right)
        XCTAssertEqual(row(three, 0).suffix(2), [1, 2], "cặp gần phía vuốt gộp trước")
        var three2 = engine([[1, 1, 1, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
        three2.move(.left)
        XCTAssertEqual(row(three2, 0).prefix(2), [2, 1])
    }

    func testNoDoubleMergeInOneMove() {
        var e = engine([[2, 1, 1, 0], [1, 1, 2, 0], [3, 3, 3, 3], [0, 0, 0, 0]])
        let r = e.move(.left)!
        XCTAssertEqual(row(e, 0).prefix(2), [2, 2], "kẹo vừa gộp thành bánh quy không gộp tiếp với bánh quy bên cạnh")
        XCTAssertEqual(row(e, 1).prefix(2), [2, 2])
        XCTAssertEqual(row(e, 2).prefix(2), [4, 4])
        XCTAssertEqual(r.merges.count, 4)
        XCTAssertEqual(r.points, 4 + 4 + 16 + 16)
        // Món còn lại giữ id, món bị gộp được báo lại.
        for m in r.merges {
            XCTAssertNotNil(e.tiles.first { $0.id == m.survivor && $0.level == m.level })
            XCTAssertNil(e.tiles.first { $0.id == m.consumed })
            XCTAssertTrue(r.consumed.contains { $0.id == m.consumed && $0.index == m.index })
        }
    }

    func testUpDownColumns() {
        var e = engine([[1, 0, 0, 0], [1, 0, 0, 0], [2, 0, 0, 0], [2, 0, 0, 0]])
        e.move(.down)
        XCTAssertEqual(e.levels[12], 3)
        XCTAssertEqual(e.levels[8], 2)
        var u = engine([[1, 0, 0, 0], [1, 0, 0, 0], [2, 0, 0, 0], [2, 0, 0, 0]])
        u.move(.up)
        XCTAssertEqual(u.levels[0], 2)
        XCTAssertEqual(u.levels[4], 3)
    }

    func testMoveThatChangesNothingIsIgnored() {
        var e = engine([[1, 2, 0, 0], [3, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
        let before = e
        XCTAssertNil(e.move(.left))
        XCTAssertNil(e.move(.up))
        XCTAssertEqual(e, before, "không trượt được thì không có món mới, không tính lượt")
        XCTAssertFalse(e.canMove(.left))
        XCTAssertTrue(e.canMove(.right))
    }

    func testSpawnAfterEachValidMove() {
        var e = engine([[1, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]], seed: 9)
        let r = e.move(.right)!
        let s = try! XCTUnwrap(r.spawned)
        XCTAssertTrue([1, 2].contains(s.level))
        XCTAssertNotEqual(s.index, 3, "món mới chỉ ở ô trống")
        XCTAssertEqual(e.tiles.count, 2)
        XCTAssertEqual(Set(e.tiles.map(\.id)).count, 2)

        // Tỉ lệ: khoảng 90% kẹo, 10% bánh quy.
        var second = 0, total = 0
        for seed in UInt64(1)...1500 {
            let fresh = SweetMergeEngine(seed: seed)
            XCTAssertEqual(fresh.tiles.count, 2)
            for t in fresh.tiles {
                total += 1
                if t.level == 2 { second += 1 } else { XCTAssertEqual(t.level, 1) }
            }
        }
        let ratio = Double(second) / Double(total)
        XCTAssertGreaterThan(ratio, 0.07)
        XCTAssertLessThan(ratio, 0.13)
    }

    func testGameOverDetection() {
        let full = engine([[1, 2, 1, 2], [2, 1, 2, 1], [1, 2, 1, 2], [2, 1, 2, 1]])
        XCTAssertTrue(full.isOver)
        XCTAssertFalse(full.canMove)
        var almost = engine([[1, 2, 1, 2], [2, 1, 2, 1], [1, 2, 1, 2], [2, 1, 2, 2]])
        XCTAssertFalse(almost.isOver, "còn hai món cạnh nhau giống nhau")
        XCTAssertNotNil(almost.move(.right))
        var stuck = full
        XCTAssertNil(stuck.move(.left))
    }

    func testSameSeedSameGame() {
        func play(_ seed: UInt64) -> SweetMergeEngine {
            var e = SweetMergeEngine(seed: seed)
            for _ in 0..<120 where !e.isOver {
                guard let d = SweetMergeBot.bestMove(e) else { break }
                e.move(d)
            }
            return e
        }
        XCTAssertEqual(play(42), play(42))
        XCTAssertNotEqual(play(42).levels, play(43).levels)
    }

    func testBotPlaysToGameOverAndResultIsPlausible() {
        var scores: [(Int, Int)] = []
        for seed in UInt64(1)...8 {
            var e = SweetMergeEngine(seed: seed)
            var total = 0
            while !e.isOver, e.moves < 5000 {
                guard let d = SweetMergeBot.bestMove(e) else { break }
                total += e.move(d)!.points
            }
            XCTAssertTrue(e.isOver, "seed \(seed): phải hết lượt trong giới hạn")
            XCTAssertNil(SweetMergeBot.bestMove(e))
            XCTAssertEqual(total, e.score)
            XCTAssertGreaterThanOrEqual(e.score, e.highestValue * max(0, e.highestLevel - 2))
            // Vuốt 0,5 giây/lượt: kết quả hợp lệ.
            let o = MinigameOutcome(sessionID: UUID(), kind: .sweetMerge, score: e.score, primary: e.highestValue,
                                    secondary: e.moves, level: nil, activeSeconds: Double(e.moves) * 0.5, completed: true,
                                    species: "cat", startedAt: Date(), finishedAt: Date())
            XCTAssertTrue(MinigamePolicy.isPlausible(o), "seed \(seed): \(e.score) điểm, món \(e.highestValue), \(e.moves) lượt")
            scores.append((e.score, e.highestValue))
        }
        print("Gộp Bánh — điểm máy chơi:", scores)
    }
}

/// Thưởng và vòng đời lượt của hai game theo lượt.
final class PuzzleRewardTests: XCTestCase {
    private let t0 = date(2026, 10, 20, 9)

    private func outcome(_ kind: MinigameKind, score: Int, primary: Int, secondary: Int, seconds: Double) -> MinigameOutcome {
        MinigameOutcome(sessionID: UUID(), kind: kind, score: score, primary: primary, secondary: secondary, level: nil,
                        activeSeconds: seconds, completed: true, species: "cat",
                        startedAt: t0.addingTimeInterval(-seconds), finishedAt: t0)
    }

    func testLooserCaps() {
        XCTAssertEqual(MinigameConfig.dailyCoinCap, 40)
        XCTAssertEqual(MinigameConfig.maxCoinsPerRun, 8)
        XCTAssertTrue(MinigameConfig.rulesText[0].contains("1–8 xu"))
        XCTAssertTrue(MinigameConfig.rulesText[0].contains("40 xu"))
    }

    func testKindsAreWired() {
        XCTAssertEqual(MinigameKind.allCases.count, 5)
        for k in [MinigameKind.blockPuzzle, .sweetMerge] {
            XCTAssertFalse(k.name.isEmpty)
            XCTAssertFalse(k.blurb.isEmpty)
            XCTAssertEqual(k.howTo.count, 3)
            XCTAssertTrue(k.isTurnBased)
            XCTAssertTrue(k.canEndRun)
            XCTAssertFalse(k.howTo.joined().contains("—"), "không dùng gạch dài")
        }
        XCTAssertFalse(MinigameKind.memoryMatch.canEndRun)
        XCTAssertFalse(MinigameKind.cloudJump.isTurnBased)
    }

    func testBlockRewards() {
        let ok = outcome(.blockPuzzle, score: 400, primary: 12, secondary: 40, seconds: 120)
        XCTAssertEqual(MinigamePolicy.coins(for: ok).0, 3)
        let low = outcome(.blockPuzzle, score: 90, primary: 1, secondary: 15, seconds: 40)
        XCTAssertEqual(MinigamePolicy.coins(for: low).1, .belowThreshold)
        let huge = outcome(.blockPuzzle, score: 3000, primary: 90, secondary: 300, seconds: 900)
        XCTAssertEqual(MinigamePolicy.coins(for: huge).0, MinigameConfig.maxCoinsPerRun)
    }

    func testBlockImplausible() {
        // Quá nhanh: 400 điểm trong 3 giây.
        XCTAssertEqual(MinigamePolicy.coins(for: outcome(.blockPuzzle, score: 400, primary: 12, secondary: 10, seconds: 3)).1, .implausible)
        // Nhiều đường hơn số ô có thể lấp.
        XCTAssertEqual(MinigamePolicy.coins(for: outcome(.blockPuzzle, score: 400, primary: 40, secondary: 10, seconds: 60)).1, .implausible)
        // Điểm vượt mức tối đa theo số khối và số đường.
        XCTAssertEqual(MinigamePolicy.coins(for: outcome(.blockPuzzle, score: 2000, primary: 2, secondary: 30, seconds: 300)).1, .implausible)
        // Điểm ít hơn số khối đã đặt.
        XCTAssertEqual(MinigamePolicy.coins(for: outcome(.blockPuzzle, score: 5, primary: 0, secondary: 30, seconds: 60)).1, .implausible)
    }

    func testMergeRewards() {
        let ok = outcome(.sweetMerge, score: 1500, primary: 128, secondary: 160, seconds: 200)
        XCTAssertEqual(MinigamePolicy.coins(for: ok).0, 3)
        let low = outcome(.sweetMerge, score: 380, primary: 64, secondary: 60, seconds: 60)
        XCTAssertEqual(MinigamePolicy.coins(for: low).1, .belowThreshold)
        let huge = outcome(.sweetMerge, score: 20000, primary: 2048, secondary: 1000, seconds: 900)
        XCTAssertEqual(MinigamePolicy.coins(for: huge).0, MinigameConfig.maxCoinsPerRun)
    }

    func testMergeImplausible() {
        // Giá trị không phải lũy thừa của 2.
        XCTAssertEqual(MinigamePolicy.coins(for: outcome(.sweetMerge, score: 1500, primary: 100, secondary: 160, seconds: 200)).1, .implausible)
        // Món 1024 mà mới vuốt 20 lượt.
        XCTAssertEqual(MinigamePolicy.coins(for: outcome(.sweetMerge, score: 9000, primary: 1024, secondary: 20, seconds: 200)).1, .implausible)
        // Món 512 mà điểm quá thấp.
        XCTAssertEqual(MinigamePolicy.coins(for: outcome(.sweetMerge, score: 600, primary: 512, secondary: 300, seconds: 300)).1, .implausible)
        // Vuốt nhanh hơn tay người.
        XCTAssertEqual(MinigamePolicy.coins(for: outcome(.sweetMerge, score: 1500, primary: 128, secondary: 400, seconds: 10)).1, .implausible)
    }

    func testEndRunFromPauseCountsAsFinished() {
        var s = PlaySession()
        s.endRun()
        XCTAssertEqual(s.phase, .ready, "chưa bắt đầu thì không kết thúc được")
        s.start(at: 0)
        s.tick(at: 3)
        s.pause()
        s.endRun()
        XCTAssertEqual(s.phase, .finished)
        s.abandon()
        XCTAssertEqual(s.phase, .finished)
        var gone = PlaySession()
        gone.start(at: 0)
        gone.abandon()
        gone.endRun()
        XCTAssertEqual(gone.phase, .abandoned, "đã thoát thì không thành kết thúc")
    }
}
