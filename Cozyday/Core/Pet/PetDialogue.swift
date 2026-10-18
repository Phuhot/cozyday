import Foundation

/// Câu thú cưng nói khi được chạm vào — chọn theo ngữ cảnh trong ngày, không cần AI.
/// Không bao giờ trách móc hay tạo cảm giác tội lỗi.
enum PetDialogue {
    struct Context: Equatable {
        var minuteOfDay: Int
        var tasksDone: Int
        var tasksTotal: Int
        var wroteJournal: Bool
        var focusRunning: Bool
        var adventureReady: Bool
        var streak: Int
        var userName: String
    }

    static func lines(for c: Context) -> [String] {
        let name = c.userName.isEmpty ? "bạn" : c.userName
        var lines: [String] = []
        if c.focusRunning {
            return ["Suỵt… mình đang tập trung cùng \(name) đó.", "Cố lên, sắp xong rồi!", "Mình ngồi đây đọc sách với \(name) nhé."]
        }
        if c.adventureReady {
            lines.append("Mình đủ năng lượng rồi! Kể chuyện đi chơi cho \(name) nghe nhé?")
        }
        switch c.minuteOfDay {
        case 300..<660:
            lines += ["Chào buổi sáng, \(name)!", "Hôm nay mình làm gì trước nhỉ?", "Uống một cốc nước cho tỉnh táo nào."]
        case 660..<780:
            lines += ["Trưa rồi, nhớ ăn gì đó nhé.", "Nghỉ một chút cũng được mà."]
        case 780..<1080:
            lines += ["Buổi chiều lười biếng ghê…", "Duỗi lưng một cái nào!", "Một việc nhỏ thôi cũng là tiến bộ."]
        case 1080..<1320:
            lines += ["Tối rồi, hôm nay \(name) vất vả rồi.", "Ngồi yên một chút với mình đi."]
        default:
            lines += ["Khuya rồi… đi ngủ sớm nhé.", "Mình buồn ngủ quá… zzz"]
        }
        if c.tasksTotal > 0 {
            if c.tasksDone == c.tasksTotal {
                lines.append("Xong hết việc hôm nay rồi! Giỏi quá đi!")
            } else if c.tasksDone > 0 {
                lines.append("Đã xong \(c.tasksDone)/\(c.tasksTotal) việc rồi đó.")
            } else {
                lines.append("Bắt đầu bằng việc dễ nhất nhé?")
            }
        } else {
            lines.append("Hôm nay chưa có kế hoạch gì — thong thả cũng tốt.")
        }
        if !c.wroteJournal && c.minuteOfDay >= 1080 {
            lines.append("Hôm nay của \(name) thế nào? Viết vài dòng nhật ký không?")
        }
        if c.streak >= 3 {
            lines.append("\(c.streak) ngày liền mình gặp nhau rồi đó!")
        }
        lines += ["Rừ rừ…", "Mình thích được xoa đầu lắm.", "Có \(name) ở đây là vui rồi."]
        return lines
    }

    /// `tap` tăng dần mỗi lần chạm → lần lượt đổi câu, không ngẫu nhiên khó đoán.
    static func line(for c: Context, tap: Int) -> String {
        let all = lines(for: c)
        return all[((tap % all.count) + all.count) % all.count]
    }
}
