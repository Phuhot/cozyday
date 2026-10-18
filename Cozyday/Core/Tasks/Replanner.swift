import Foundation

/// Sắp xếp lại các việc chưa xong trong ngày vào khoảng trống — thuật toán xác định, không AI.
///
/// - Chỉ di chuyển việc: chưa xong, không cố định, và (đã qua giờ bắt đầu hoặc chưa xếp giờ).
/// - Mọi việc khác (cố định, đã xong/bỏ qua, việc tương lai chưa làm) được coi là bận.
/// - Xếp từ thời điểm hiện tại (làm tròn lên 5 phút) tới hết khung giờ hoạt động.
/// - Ưu tiên cao xếp trước; cùng ưu tiên thì giữ thứ tự cũ. Giữ nguyên thời lượng.
/// - Không đủ chỗ: việc đó nằm trong `unplaced`, không bị âm thầm bỏ.
enum Replanner {
    struct Task: Equatable {
        var id: UUID
        var start: Int?
        var duration: Int
        var isFixed: Bool
        var isFinished: Bool
        var priority: TaskPriority
        var order: Int
    }

    struct Move: Equatable {
        var id: UUID
        var from: Int?
        var to: Int
    }

    struct Plan: Equatable {
        var moves: [Move]
        var unplaced: [UUID]
        var windowStart: Int
        var windowEnd: Int

        var isEmpty: Bool { moves.isEmpty && unplaced.isEmpty }
    }

    static let step = 5

    static func plan(
        tasks: [Task],
        nowMinute: Int,
        activeStart: Int,
        activeEnd: Int,
        includeUnscheduled: Bool
    ) -> Plan {
        let windowStart = max(activeStart, TimeOfDay.roundUp(nowMinute, step: step))
        let windowEnd = min(activeEnd, TimeOfDay.minutesPerDay)

        func isMovable(_ t: Task) -> Bool {
            guard !t.isFinished, !t.isFixed else { return false }
            if let start = t.start { return start < nowMinute }
            return includeUnscheduled
        }

        let movable = tasks.filter(isMovable).sorted {
            if $0.priority != $1.priority { return $0.priority > $1.priority }
            let a = $0.start ?? Int.max, b = $1.start ?? Int.max
            if a != b { return a < b }
            return $0.order < $1.order
        }
        var busy: [(Int, Int)] = tasks
            .filter { !isMovable($0) }
            .compactMap { t in t.start.map { ($0, $0 + t.duration) } }

        var moves: [Move] = []
        var unplaced: [UUID] = []
        for task in movable {
            if windowEnd - windowStart >= task.duration,
               let slot = firstFit(duration: task.duration, from: windowStart, to: windowEnd, busy: busy) {
                moves.append(Move(id: task.id, from: task.start, to: slot))
                busy.append((slot, slot + task.duration))
            } else {
                unplaced.append(task.id)
            }
        }
        return Plan(moves: moves, unplaced: unplaced, windowStart: windowStart, windowEnd: windowEnd)
    }

    /// Khe sớm nhất dài ít nhất `duration` trong [from, to) không giao với `busy`.
    static func firstFit(duration: Int, from: Int, to: Int, busy: [(Int, Int)]) -> Int? {
        var cursor = from
        for (s, e) in busy.sorted(by: { $0.0 < $1.0 }) {
            if e <= cursor { continue }
            if s >= cursor + duration { break }
            cursor = max(cursor, TimeOfDay.roundUp(e, step: step))
        }
        return cursor + duration <= to ? cursor : nil
    }
}
