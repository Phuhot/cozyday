import Foundation

/// Một việc con trong danh sách kiểm (checklist) của việc. Không có thưởng riêng —
/// thưởng vẫn chỉ tính khi hoàn thành việc chính.
struct Subtask: Codable, Equatable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var isDone: Bool

    init(id: UUID = UUID(), title: String, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }
}

enum Subtasks {
    static let maxCount = 20
    static let maxTitleLength = 120

    /// Bỏ dòng trống, cắt khoảng trắng, giới hạn độ dài và số lượng.
    static func normalized(_ list: [Subtask]) -> [Subtask] {
        list.compactMap { s -> Subtask? in
            let t = s.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { return nil }
            return Subtask(id: s.id, title: String(t.prefix(maxTitleLength)), isDone: s.isDone)
        }
        .prefix(maxCount)
        .map { $0 }
    }

    /// Danh sách mới cho một lần lặp: cùng nội dung, chưa làm.
    static func fresh(_ list: [Subtask]) -> [Subtask] {
        list.map { Subtask(id: $0.id, title: $0.title, isDone: false) }
    }

    /// Áp danh sách mới của mẫu vào một lần việc, giữ trạng thái đã làm của các mục còn giữ nguyên.
    static func merge(template list: [Subtask], keepingStateFrom existing: [Subtask]) -> [Subtask] {
        let done = Dictionary(existing.map { ($0.id, $0.isDone) }, uniquingKeysWith: { a, _ in a })
        return list.map { Subtask(id: $0.id, title: $0.title, isDone: done[$0.id] ?? false) }
    }

    static func encode(_ list: [Subtask]) -> String {
        guard !list.isEmpty, let data = try? JSONEncoder().encode(list) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    /// Chuỗi rỗng hoặc hỏng → danh sách rỗng (không làm hỏng cả việc).
    static func decode(_ json: String) -> [Subtask] {
        guard !json.isEmpty, let list = try? JSONDecoder().decode([Subtask].self, from: Data(json.utf8)) else { return [] }
        return list
    }

    static func progressLabel(_ list: [Subtask]) -> String? {
        guard !list.isEmpty else { return nil }
        return "\(list.filter(\.isDone).count)/\(list.count)"
    }
}
