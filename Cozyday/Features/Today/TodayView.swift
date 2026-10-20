import SwiftUI

enum TodayLayoutMode: String, CaseIterable, Identifiable {
    case timeline
    case list

    var id: String { rawValue }
    var label: String { self == .timeline ? "Timeline" : "Danh sách" }
}

/// Các sheet có thể mở từ màn Hôm nay.
enum TodaySheet: Identifiable {
    case newTask(day: DayKey?, startMinute: Int?)
    case edit(UUID)
    case detail(UUID)
    case move(UUID)
    case inbox
    case replan(Replanner.Plan, DayKey)
    case focus(UUID?)

    var id: String {
        switch self {
        case .newTask(let day, let start): return "new-\(day?.string ?? "inbox")-\(start ?? -1)"
        case .edit(let id): return "edit-\(id)"
        case .detail(let id): return "detail-\(id)"
        case .move(let id): return "move-\(id)"
        case .inbox: return "inbox"
        case .replan(_, let day): return "replan-\(day)"
        case .focus(let id): return "focus-\(id?.uuidString ?? "free")"
        }
    }
}

struct TodayView: View {
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(DayClock.self) private var dayClock
    @Environment(AppRouter.self) private var router
    @Environment(CalendarService.self) private var calendarService
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var selectedDay: DayKey?
    @State private var sheet: TodaySheet?
    @State private var layoutMode: TodayLayoutMode?
    @State private var showDatePicker = false

    private var day: DayKey { selectedDay ?? dayClock.today }
    private var effectiveLayout: TodayLayoutMode {
        layoutMode ?? (dynamicTypeSize.isAccessibilitySize ? .list : .timeline)
    }

    var body: some View {
        let tasks = store.tasks(on: day)
        let timed = tasks.filter { $0.startMinute != nil }
        let untimed = tasks.filter { $0.startMinute == nil }
        let isToday = day == dayClock.today
        let _ = calendarService.revision
        let events = calendarService.events(on: day, calendar: store.calendar)
        let timedEvents = events.filter { !$0.isAllDay }
        let allDayEvents = events.filter(\.isAllDay)
        let busy = timedEvents.map { (start: $0.startMinute, duration: $0.durationMinutes) }
        let plan = isToday ? store.replanPlan(for: day, includeUnscheduled: false, busy: busy) : nil

        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.l) {
                        TodayHeader(day: day, tasks: tasks, isToday: isToday)

                        DayStrip(selected: day, today: dayClock.today, calendar: store.calendar) { picked in
                            selectedDay = picked == dayClock.today ? nil : picked
                        } onPickDate: {
                            showDatePicker = true
                        }

                        if isToday, openInboxCount > 0 {
                            Button {
                                sheet = .inbox
                            } label: {
                                HStack {
                                    Label("Hộp chờ: \(openInboxCount) việc chưa xếp lịch", systemImage: "tray")
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .font(Typography.caption.weight(.semibold))
                                        .accessibilityHidden(true)
                                }
                            }
                            .buttonStyle(SoftButtonStyle(tint: Palette.lavender))
                        }

                        if let plan, !plan.isEmpty {
                            Button {
                                sheet = .replan(plan, day)
                            } label: {
                                Label("Có \(plan.moves.count + plan.unplaced.count) việc trễ giờ. Sắp xếp lại?", systemImage: "arrow.triangle.2.circlepath")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(SoftButtonStyle(tint: Palette.peach))
                        }

                        if tasks.isEmpty {
                            CozyCard {
                                EmptyStateView(
                                    symbol: "sparkles",
                                    title: isToday ? "Hôm nay còn trống" : "Ngày này còn trống",
                                    message: "Bấm nút + để thêm việc. Việc có giờ sẽ hiện trên timeline, việc chưa có giờ nằm ở mục riêng."
                                )
                            }
                        }

                        if !untimed.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.s) {
                                Text("Chưa xếp giờ")
                                    .font(Typography.headline)
                                    .foregroundStyle(Palette.inkMuted)
                                ForEach(untimed) { task in
                                    TaskRow(task: task, sheet: $sheet)
                                }
                            }
                        }

                        if !allDayEvents.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                ForEach(allDayEvents) { e in
                                    Label("Cả ngày: \(e.title)", systemImage: "calendar")
                                        .font(Typography.callout)
                                        .foregroundStyle(Palette.inkMuted)
                                        .accessibilityLabel("Sự kiện cả ngày trong app Lịch: \(e.title)")
                                }
                            }
                        }

                        if !timed.isEmpty || isToday {
                            HStack {
                                Text("Lịch trong ngày")
                                    .font(Typography.headline)
                                    .foregroundStyle(Palette.inkMuted)
                                Spacer()
                                Picker("Kiểu hiển thị", selection: Binding(get: { effectiveLayout }, set: { layoutMode = $0 })) {
                                    ForEach(TodayLayoutMode.allCases) { Text($0.label).tag($0) }
                                }
                                .pickerStyle(.segmented)
                                .fixedSize()
                            }
                            if effectiveLayout == .timeline {
                                DayTimeline(
                                    tasks: timed, isToday: isToday,
                                    activeStart: store.profile.activeStartMinute,
                                    activeEnd: store.profile.activeEndMinute,
                                    events: timedEvents,
                                    sheet: $sheet
                                )
                            } else if timed.isEmpty {
                                Text("Chưa có việc nào có giờ.")
                                    .font(Typography.callout)
                                    .foregroundStyle(Palette.inkMuted)
                            } else {
                                VStack(spacing: Spacing.s) {
                                    ForEach(timed) { TaskRow(task: $0, sheet: $sheet) }
                                    ForEach(timedEvents) { EventBlock(event: $0).frame(minHeight: 56) }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.l)
                    .padding(.bottom, 96)
                    .id("top")
                }
                .onChange(of: day) { _, _ in
                    withAnimation { proxy.scrollTo("top", anchor: .top) }
                }
            }
            .cozyBackground()
            .overlay(alignment: .bottomTrailing) { addButton }
            .navigationTitle(isToday ? "Hôm nay" : "Lịch ngày")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        sheet = .inbox
                    } label: {
                        // Trên iOS 26 thanh công cụ chỉ hiện biểu tượng; số việc nằm ở dòng "Hộp chờ" trong nội dung.
                        Image(systemName: "tray")
                            .frame(minWidth: HitTarget.min, minHeight: HitTarget.min)
                    }
                    .accessibilityLabel("Hộp chờ, \(openInboxCount) việc")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        sheet = .focus(nil)
                    } label: {
                        Image(systemName: store.activeFocus == nil ? "timer" : "timer.circle.fill")
                            .frame(minWidth: HitTarget.min, minHeight: HitTarget.min)
                    }
                    .accessibilityLabel(store.activeFocus == nil ? "Tập trung" : "Phiên tập trung đang chạy")
                    SettingsButton()
                }
            }
            .sheet(item: $sheet) { item in
                sheetContent(item)
            }
            .sheet(isPresented: $showDatePicker) {
                DayPickerSheet(selected: day, calendar: store.calendar) { picked in
                    selectedDay = picked == dayClock.today ? nil : picked
                }
                .presentationDetents([.medium, .large])
            }
            .onChange(of: day, initial: true) { _, newDay in
                ui.run { try store.ensureOccurrences(for: [newDay]) }
            }
            .onChange(of: router.pendingTaskID, initial: true) { _, id in
                guard let id else { return }
                router.pendingTaskID = nil
                if let task = store.occurrence(id) {
                    if let d = task.day { selectedDay = d == dayClock.today ? nil : d }
                    sheet = .detail(id)
                } else {
                    selectedDay = nil
                }
            }
            .onChange(of: router.showFocus, initial: true) { _, show in
                guard show else { return }
                router.showFocus = false
                sheet = .focus(nil)
            }
            .task { await openPreviewSheet() }
        }
    }

    private var openInboxCount: Int { store.inbox.filter { $0.status == .open }.count }

    private var addButton: some View {
        Button {
            let isToday = day == dayClock.today
            let suggested: Int
            if isToday {
                let next = TimeOfDay.roundUp(store.calendar.minuteOfDay(store.now) + 5, step: 30)
                suggested = min(next, 23 * 60)
            } else {
                suggested = 9 * 60
            }
            sheet = .newTask(day: day, startMinute: suggested)
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Palette.onAccent)
                .frame(width: 60, height: 60)
                .background(Palette.lavender, in: Circle())
                .shadow(color: Palette.lavender.opacity(0.35), radius: 8, y: 3)
        }
        .padding(Spacing.xl)
        .accessibilityLabel("Thêm việc")
    }

    /// Chỉ dùng khi CI chụp ảnh giao diện (bản Debug); bản Release không vào được nhánh này.
    private func openPreviewSheet() async {
        guard let screen = PreviewMode.current else { return }
        try? await Task.sleep(nanoseconds: 600_000_000)
        switch screen {
        case .editor:
            sheet = .newTask(day: day, startMinute: min(TimeOfDay.roundUp(store.calendar.minuteOfDay(store.now) + 5, step: 30), 23 * 60))
        case .replan:
            let busy = calendarService.events(on: day, calendar: store.calendar).filter { !$0.isAllDay }
                .map { (start: $0.startMinute, duration: $0.durationMinutes) }
            let plan = store.replanPlan(for: day, includeUnscheduled: false, busy: busy)
            if !plan.isEmpty { sheet = .replan(plan, day) }
        case .inbox:
            sheet = .inbox
        case .taskDetail:
            if let task = store.tasks(on: day).first(where: { !$0.checklist.isEmpty }) { sheet = .detail(task.id) }
        case .trailerToday:
            // Trailer: hoàn thành việc trễ giờ gần nhất, đúng như khi bấm nút tròn (lưu, thưởng, thú cưng vui).
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            let minute = store.calendar.minuteOfDay(store.now)
            let late = store.tasks(on: day).filter { $0.status == .open && ($0.startMinute ?? .max) < minute }
            if let task = late.max(by: { ($0.startMinute ?? 0) < ($1.startMinute ?? 0) }) {
                var reward: LedgerEntry?
                ui.run { reward = try store.setStatus(id: task.id, to: .done) }
                ui.reward(reward)
            }
        default:
            break
        }
    }

    @ViewBuilder
    private func sheetContent(_ item: TodaySheet) -> some View {
        switch item {
        case .newTask(let day, let start):
            TaskEditorView(mode: .create(day: day, startMinute: start))
        case .edit(let id):
            TaskEditorView(mode: .edit(id))
        case .detail(let id):
            TaskDetailSheet(taskID: id, sheet: $sheet)
                .presentationDetents([.medium, .large])
        case .move(let id):
            MoveTaskSheet(taskID: id)
                .presentationDetents([.medium, .large])
        case .inbox:
            InboxView()
        case .replan(let plan, let day):
            ReplanSheet(plan: plan, day: day)
                .presentationDetents([.medium, .large])
        case .focus(let taskID):
            FocusView(preselectedTaskID: taskID)
        }
    }
}

struct TodayHeader: View {
    let day: DayKey
    let tasks: [TaskOccurrenceRecord]
    let isToday: Bool
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(AppRouter.self) private var router

    private var greeting: String {
        guard isToday else { return "Xem trước / xem lại một ngày khác" }
        let minute = store.calendar.minuteOfDay(store.now)
        let part: String
        switch minute {
        case 300..<660: part = "Chào buổi sáng"
        case 660..<780: part = "Chào buổi trưa"
        case 780..<1080: part = "Chào buổi chiều"
        default: part = "Chào buổi tối"
        }
        return "\(part), \(store.profile.displayUserName)"
    }

    @Environment(DayClock.self) private var dayClock
    @State private var tip = 0

    var body: some View {
        let counted = tasks.filter { $0.status != .skipped }
        let done = counted.filter { $0.status == .done }.count
        VStack(alignment: .leading, spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(DateText.long(day, calendar: store.calendar))
                    .font(Typography.title)
                    .foregroundStyle(Palette.ink)
                Text(greeting)
                    .font(Typography.callout)
                    .foregroundStyle(Palette.inkMuted)
            }
            // Thú cưng nói chuyện với bạn (chạm bong bóng để nghe câu khác, chạm thú cưng để sang Góc nhỏ).
            HStack(alignment: .bottom, spacing: Spacing.xs) {
                Button {
                    router.selectedTab = .corner
                } label: {
                    PetView(appearance: store.petAppearance, mood: ui.petMood(store: store),
                            name: store.profile.displayPetName, bounceTrigger: ui.celebrateCounter)
                        .frame(width: 76, height: 76)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Mở Góc nhỏ")
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Button {
                        withAnimation(Motion.bouncy) { tip += 1 }
                    } label: {
                        Text(isToday ? PetDialogue.line(for: store.petDialogueContext(today: dayClock.today), tap: tip, species: store.petAppearance.species)
                                     : "Mình xem giúp bạn ngày này nhé!")
                            .font(Typography.callout.weight(.semibold))
                            .foregroundStyle(Palette.bubbleInk)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(tip)
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Nghe câu khác")
                    if !counted.isEmpty {
                        HStack(spacing: Spacing.s) {
                            ProgressView(value: Double(done), total: Double(max(1, counted.count)))
                                .tint(Palette.sage)
                            Text("\(done)/\(counted.count) việc")
                                .font(Typography.caption.weight(.bold))
                                .foregroundStyle(Palette.bubbleInk.opacity(0.8))
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.m)
                .background(Palette.bubble, in: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 4,
                                                                      bottomTrailingRadius: 20, topTrailingRadius: 20, style: .continuous))
                .padding(.bottom, Spacing.m)
            }
        }
        .padding(.top, Spacing.s)
    }
}

/// Định dạng ngày tiếng Việt, không phụ thuộc ngôn ngữ máy.
enum DateText {
    static func weekdayName(_ weekday: Int) -> String { Weekday.longLabel(weekday) }

    static func long(_ day: DayKey, calendar: Calendar) -> String {
        "\(weekdayName(day.weekday(calendar: calendar))), \(day.day) tháng \(day.month)"
    }

    static func short(_ day: DayKey) -> String { "\(day.day)/\(day.month)" }

    static func weekdayShort(_ day: DayKey, calendar: Calendar) -> String { Weekday.shortLabel(day.weekday(calendar: calendar)) }

    static func full(_ day: DayKey, calendar: Calendar) -> String {
        "\(weekdayName(day.weekday(calendar: calendar))), \(day.day)/\(day.month)/\(day.year)"
    }

    static func monthTitle(year: Int, month: Int) -> String { "Tháng \(month), \(year)" }

    static func time(_ date: Date, calendar: Calendar) -> String {
        TimeOfDay.label(calendar.minuteOfDay(date))
    }

    static func dateTime(_ date: Date, calendar: Calendar) -> String {
        let d = DayKey(date, calendar: calendar)
        return "\(short(d)) \(time(date, calendar: calendar))"
    }
}
