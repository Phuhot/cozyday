import Foundation

/// Tâm trạng 1–5 có nhãn chữ. Chỉ để tự ghi lại — app không suy luận hay chẩn đoán gì từ mood.
enum Mood: Int, Codable, CaseIterable, Identifiable {
    case veryLow = 1
    case low = 2
    case okay = 3
    case good = 4
    case great = 5

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .veryLow: return "Rất mệt"
        case .low: return "Hơi buồn"
        case .okay: return "Bình thường"
        case .good: return "Vui"
        case .great: return "Rất vui"
        }
    }
}

struct JournalRecord: Codable, Equatable, Identifiable {
    var id: UUID
    var day: DayKey
    var mood: Int
    var note: String
    var createdAt: Date
    var updatedAt: Date

    static let maxNoteLength = 2000
}

struct ProfileRecord: Codable, Equatable {
    var userName: String
    var petName: String
    var goals: [String]
    var activeStartMinute: Int
    var activeEndMinute: Int
    var hapticsEnabled: Bool
    var journalReminderEnabled: Bool
    var journalReminderMinute: Int
    var onboardingCompleted: Bool
    var createdAt: Date

    static let defaultUserName = "bạn"
    static let defaultPetName = "Bông"

    static func makeDefault(now: Date) -> ProfileRecord {
        ProfileRecord(
            userName: "", petName: defaultPetName, goals: [],
            activeStartMinute: 7 * 60, activeEndMinute: 22 * 60,
            hapticsEnabled: true, journalReminderEnabled: false, journalReminderMinute: 21 * 60,
            onboardingCompleted: false, createdAt: now
        )
    }

    var displayUserName: String {
        let t = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? Self.defaultUserName : t
    }

    var displayPetName: String {
        let t = petName.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? Self.defaultPetName : t
    }
}

/// Mục tiêu sử dụng chọn trong onboarding.
enum UsageGoal: String, CaseIterable, Identifiable {
    case study, work, health, habits, rest

    var id: String { rawValue }

    var label: String {
        switch self {
        case .study: return "Học tập đều đặn"
        case .work: return "Làm việc gọn gàng"
        case .health: return "Chăm sóc sức khỏe"
        case .habits: return "Xây thói quen tốt"
        case .rest: return "Nghỉ ngơi đủ"
        }
    }
}

/// Thói quen gợi ý ở onboarding — chỉ được tạo khi người dùng chọn.
struct HabitSuggestion: Identifiable, Equatable {
    let id: String
    let title: String
    let category: TaskCategory
    let startMinute: Int
    let duration: Int

    static let all: [HabitSuggestion] = [
        HabitSuggestion(id: "water", title: "Uống một cốc nước", category: .health, startMinute: 7 * 60 + 30, duration: 5),
        HabitSuggestion(id: "plan", title: "Xem lại kế hoạch trong ngày", category: .personal, startMinute: 8 * 60, duration: 10),
        HabitSuggestion(id: "study", title: "Học 45 phút", category: .study, startMinute: 9 * 60, duration: 45),
        HabitSuggestion(id: "walk", title: "Đi bộ 15 phút", category: .health, startMinute: 17 * 60 + 30, duration: 15),
        HabitSuggestion(id: "tidy", title: "Dọn bàn học", category: .home, startMinute: 20 * 60, duration: 10),
        HabitSuggestion(id: "read", title: "Đọc sách trước khi ngủ", category: .personal, startMinute: 21 * 60 + 30, duration: 20)
    ]
}

/// Câu gợi ý viết nhật ký — chọn cố định theo ngày, có thể đổi câu khác. Không bắt buộc dùng.
enum JournalPrompts {
    static let all: [String] = [
        "Điều nhỏ nào hôm nay làm bạn mỉm cười?",
        "Hôm nay bạn đã làm tốt điều gì, dù rất nhỏ?",
        "Có ai bạn muốn cảm ơn hôm nay không?",
        "Việc gì đang chiếm nhiều suy nghĩ của bạn nhất?",
        "Nếu ngày mai chỉ làm được một việc, bạn chọn việc nào?",
        "Bạn đã nghỉ ngơi đủ chưa? Cơ thể bạn đang cần gì?",
        "Một khoảnh khắc yên bình trong ngày hôm nay là gì?",
        "Điều gì khiến bạn thấy khó khăn hôm nay, và bạn đã vượt qua thế nào?",
        "Bạn học được điều gì mới hôm nay?",
        "Ba điều bạn biết ơn lúc này là gì?",
        "Hôm nay bạn đã tử tế với chính mình ở điểm nào?",
        "Có điều gì bạn muốn buông bỏ trước khi ngủ?",
        "Bài hát, món ăn hay câu nói nào hợp với tâm trạng hôm nay?",
        "Nếu kể ngày hôm nay bằng một câu, bạn sẽ viết gì?",
        "Điều gì bạn đang mong chờ trong tuần này?",
        "Bạn đã dành thời gian cho người mình thương chưa?",
        "Có việc nào bạn đang để đó? Bước đầu tiên nhỏ nhất của nó là gì?",
        "Lúc nào trong ngày bạn thấy có năng lượng nhất?",
        "Hôm nay có điều gì bất ngờ không?",
        "Bạn muốn nói gì với chính mình của một năm trước?"
    ]

    static func prompt(for day: DayKey, shift: Int = 0) -> String {
        let base = Int(Adventure.stableHash("prompt|" + day.string) % UInt64(all.count))
        return all[((base + shift) % all.count + all.count) % all.count]
    }
}
