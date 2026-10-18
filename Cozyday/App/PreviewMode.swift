import Foundation

/// Màn hình cần mở sẵn khi CI chụp ảnh giao diện trên iOS Simulator
/// (`scripts/ci/capture_screenshots.sh` chạy app với `-CozyPreview <tên>`).
enum PreviewScreen: String, CaseIterable {
    case onboarding
    case today
    case editor
    case replan
    case inbox
    case focus
    case corner
    case shop
    case journal
    case progress
    case settings
    case wardrobe
    case adventure
    case memories
    case gallery
    case breathing
    case taskDetail
    case journalEditor
}

/// Chế độ xem trước chỉ có trong bản Debug: dữ liệu mẫu nằm trong bộ nhớ, không đụng tới kho dữ liệu thật.
/// Bản Release (file IPA cài lên iPhone) luôn trả về `nil`, nên mọi nhánh xem trước đều không chạy.
enum PreviewMode {
    static var current: PreviewScreen? {
        #if DEBUG
        guard let raw = UserDefaults.standard.string(forKey: "CozyPreview") else { return nil }
        return PreviewScreen(rawValue: raw)
        #else
        return nil
        #endif
    }
}

#if DEBUG
/// Đồng hồ lệch được: dùng khi tạo dữ liệu mẫu cho các ngày trước, rồi trả về giờ thật.
final class PreviewClock: AppClock {
    private var offset: TimeInterval = 0
    var now: Date { Date().addingTimeInterval(offset) }
    func set(_ date: Date) { offset = date.timeIntervalSinceNow }
    func reset() { offset = 0 }
}

extension PreviewMode {
    @MainActor
    static func makeEnvironment(for screen: PreviewScreen) throws -> AppEnvironment {
        let clock = PreviewClock()
        let store = try AppStore(container: PersistenceController.makeContainer(inMemory: true), clock: clock)
        let ui = UIState()
        if screen != .onboarding {
            try seed(store, clock: clock, activeFocus: screen == .focus, adventureReady: screen == .adventure)
        }
        let router = AppRouter.shared
        switch screen {
        case .corner, .shop, .wardrobe, .adventure, .memories: router.selectedTab = .corner
        case .journal, .breathing, .journalEditor: router.selectedTab = .journal
        case .progress: router.selectedTab = .progress
        case .focus: router.showFocus = true
        case .settings: ui.showSettings = true
        default: router.selectedTab = .today
        }
        return AppEnvironment(store: store, ui: ui, dayClock: DayClock(), notifications: NotificationService(), calendar: CalendarService())
    }

    /// Hai tuần dữ liệu mẫu: việc đã xong, phiên tập trung, nhật ký, đồ đã mua; hôm nay có việc xong,
    /// việc trễ giờ, hai việc trùng giờ, việc chưa xếp giờ và Hộp chờ. Tên người dùng là tên giả.
    @MainActor
    private static func seed(_ store: AppStore, clock: PreviewClock, activeFocus: Bool, adventureReady: Bool) throws {
        let cal = store.calendar
        let today = store.today
        let habit = HabitSuggestion.all.filter { $0.id == "read" }
        try store.completeOnboarding(userName: "An", petName: "Bông", goals: [.study, .health], habits: habit)

        let pastTitles: [(String, TaskCategory)] = [
            ("Ôn từ vựng tiếng Anh", .study), ("Chạy bộ 20 phút", .health), ("Dọn bàn làm việc", .home),
            ("Viết báo cáo tuần", .work), ("Đọc một chương sách", .personal)
        ]
        let moods: [Mood] = [.good, .okay, .great, .good, .low, .good, .great, .okay, .good, .great, .good, .okay, .good]
        let notes = ["Hôm nay khá ổn.", "Hơi mệt nhưng làm xong việc chính.", "Đi dạo buổi tối, dễ chịu."]
        for back in stride(from: 13, through: 1, by: -1) {
            let day = today.adding(days: -back, calendar: cal)
            clock.set(day.date(atMinute: 20 * 60, in: cal))
            for i in 0..<(2 + back % 3) {
                let sample = pastTitles[(back + i) % pastTitles.count]
                var draft = TaskDraft()
                draft.title = sample.0
                draft.category = sample.1
                draft.day = day
                draft.startMinute = 8 * 60 + i * 90
                draft.durationMinutes = 45
                if let id = try store.createTask(draft) { _ = try store.setStatus(id: id, to: .done) }
            }
            if back % 2 == 0 {
                clock.set(day.date(atMinute: 14 * 60, in: cal))
                try store.startFocus(kind: .focus, minutes: 25, occurrenceID: nil)
                clock.set(day.date(atMinute: 14 * 60 + 26, in: cal))
                _ = try store.reconcileFocus()
            }
            if back != 4 {
                clock.set(day.date(atMinute: 21 * 60, in: cal))
                _ = try store.saveJournal(day: day, mood: moods[back - 1], note: notes[back % notes.count])
            }
            if back % 3 != 1, Adventure.isReady(on: day, ledger: store.ledger, calendar: cal) {
                clock.set(day.date(atMinute: 21 * 60 + 30, in: cal))
                try store.claimAdventure(day: day)
            }
        }
        clock.reset()

        for item in ["desk.pine", "seat.rug", "plant.cactus", "lamp.candle", "wall.poster", "plant.monstera", "seat.cushion"] {
            try store.buy(itemID: item)
        }
        try store.equip(itemID: "plant.monstera")
        try store.equip(itemID: "seat.cushion")
        for item in ["hat.sprout", "hat.beanie", "neck.scarf", "fur.ginger"] {
            try store.buy(itemID: item)
        }
        try store.equip(itemID: "hat.beanie")
        try store.equip(itemID: "neck.scarf")

        // Hôm nay: các mốc đặt quanh giờ hiện tại để luôn có việc đã qua, đang tới và trễ giờ.
        let nowMinute = cal.minuteOfDay(store.now)
        let base = min(max(TimeOfDay.roundUp(nowMinute, step: 30), 10 * 60), 19 * 60)
        let plan: [(String, TaskCategory, Int?, Int, TaskStatus, TaskPriority)] = [
            ("Đi bộ 30 phút", .health, base - 180, 30, .done, .normal),
            ("Ôn từ vựng tiếng Anh", .study, base - 120, 45, .done, .normal),
            ("Trả lời email của nhóm", .work, base - 60, 30, .open, .normal),
            ("Học Swift: bài 4 — danh sách và điều hướng", .study, base, 60, .open, .high),
            ("Gọi điện cho bà", .personal, base + 15, 20, .open, .normal),
            ("Nấu bữa tối", .home, base + 90, 45, .open, .normal),
            ("Tưới cây ngoài ban công", .home, nil, 10, .open, .low)
        ]
        var firstOpen: UUID?
        for item in plan {
            var draft = TaskDraft()
            draft.title = item.0
            draft.category = item.1
            draft.day = today
            draft.startMinute = item.2
            draft.durationMinutes = item.3
            draft.priority = item.5
            draft.isFixed = item.0 == "Nấu bữa tối"
            if item.0.hasPrefix("Học Swift") {
                draft.subtasks = [Subtask(title: "Đọc phần NavigationStack", isDone: true),
                                  Subtask(title: "Làm bài tập danh sách"), Subtask(title: "Ghi chú 3 điều học được")]
            }
            guard let id = try store.createTask(draft) else { continue }
            if item.4 != .open { _ = try store.setStatus(id: id, to: item.4) }
            if item.4 == .open, item.2 != nil, firstOpen == nil { firstOpen = id }
        }
        for title in ["Dọn tủ quần áo", "Đặt lịch khám răng"] {
            var draft = TaskDraft()
            draft.title = title
            draft.category = .home
            try store.createTask(draft)
        }
        try store.ensureUpcomingOccurrences()

        if adventureReady {
            // Hôm nay đủ năng lượng: thêm một phiên tập trung buổi sáng và bài thở.
            clock.set(today.date(atMinute: 7 * 60, in: cal))
            try store.startFocus(kind: .focus, minutes: 25, occurrenceID: nil)
            clock.set(today.date(atMinute: 7 * 60 + 26, in: cal))
            _ = try store.reconcileFocus()
            clock.reset()
            try store.completeBreathing(day: today)
        }

        if activeFocus {
            clock.set(store.now.addingTimeInterval(-7 * 60))
            try store.startFocus(kind: .focus, minutes: 25, occurrenceID: firstOpen)
            clock.reset()
        }
    }
}
#endif
