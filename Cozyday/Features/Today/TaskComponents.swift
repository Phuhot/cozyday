import SwiftUI

/// Nút tròn hoàn thành việc (vùng chạm 44 pt). Lần đầu hoàn thành → thưởng + mèo vui.
struct CompleteButton: View {
    let task: TaskOccurrenceRecord
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui

    var body: some View {
        let done = task.status == .done
        Button {
            toggle()
        } label: {
            Image(systemName: done ? "checkmark.circle.fill" : (task.status == .skipped ? "minus.circle" : "circle"))
                .font(.title3)
                .foregroundStyle(done ? Palette.sage : task.category.color)
                .frame(width: HitTarget.min, height: HitTarget.min)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(done ? "Bỏ đánh dấu hoàn thành" : "Đánh dấu hoàn thành")
        .sensoryFeedback(trigger: task.status) { _, new in
            store.profile.hapticsEnabled && new == .done ? .success : nil
        }
    }

    private func toggle() {
        let target: TaskStatus = task.status == .done ? .open : .done
        var reward: LedgerEntry?
        ui.run { reward = try store.setStatus(id: task.id, to: target) }
        ui.reward(reward)
    }
}

/// Dòng việc dạng danh sách (dùng cho mục chưa xếp giờ, chế độ Danh sách và Hộp chờ).
struct TaskRow: View {
    let task: TaskOccurrenceRecord
    @Binding var sheet: TodaySheet?

    var body: some View {
        let finished = task.status != .open
        HStack(spacing: Spacing.s) {
            CompleteButton(task: task)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(task.title)
                    .font(Typography.body.weight(.medium))
                    .strikethrough(finished)
                    .foregroundStyle(Palette.ink.opacity(finished ? 0.55 : 1))
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Spacing.xs) {
                    if let start = task.startMinute {
                        Text(TimeOfDay.rangeLabel(start: start, duration: task.durationMinutes)).monospacedDigit()
                    } else {
                        Text(TimeOfDay.durationLabel(task.durationMinutes))
                    }
                    Text("·")
                    Text(task.category.label)
                    if let progress = Subtasks.progressLabel(task.checklist) {
                        Label(progress, systemImage: "checklist").labelStyle(.titleAndIcon).monospacedDigit()
                    }
                    if task.isRecurring { Image(systemName: "repeat").accessibilityHidden(true) }
                    if task.priority == .high { Image(systemName: "flag.fill").foregroundStyle(Palette.peach).accessibilityHidden(true) }
                }
                .font(Typography.caption)
                .foregroundStyle(Palette.inkMuted)
            }
            Spacer(minLength: 0)
        }
        .padding(.trailing, Spacing.m)
        .frame(minHeight: 56)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2).fill(task.category.color).frame(width: 4).padding(.vertical, Spacing.s)
        }
        .contentShape(Rectangle())
        .onTapGesture { sheet = .detail(task.id) }
        .contextMenu { TaskContextMenu(task: task, sheet: $sheet) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(TaskAccessibility.label(task, overlaps: false))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { sheet = .detail(task.id) }
        .modifier(TaskAccessibilityActions(task: task, sheet: $sheet))
    }
}

enum TaskAccessibility {
    static func label(_ t: TaskOccurrenceRecord, overlaps: Bool) -> String {
        var parts = [t.title]
        if let start = t.startMinute {
            parts.append("từ \(TimeOfDay.label(start)) đến \(TimeOfDay.label(start + t.durationMinutes))")
        } else {
            parts.append("chưa xếp giờ, \(TimeOfDay.durationLabel(t.durationMinutes))")
        }
        parts.append(t.category.label)
        switch t.status {
        case .done: parts.append("đã hoàn thành")
        case .skipped: parts.append("đã bỏ qua")
        case .open: break
        }
        if !t.checklist.isEmpty {
            parts.append("\(t.checklist.filter(\.isDone).count) trên \(t.checklist.count) việc con xong")
        }
        if overlaps { parts.append("trùng giờ với việc khác") }
        if t.isRecurring { parts.append("lặp lại") }
        return parts.joined(separator: ", ")
    }
}

/// Thao tác thay thế cho VoiceOver (không cần cử chỉ kéo/nhấn giữ).
struct TaskAccessibilityActions: ViewModifier {
    let task: TaskOccurrenceRecord
    @Binding var sheet: TodaySheet?
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui

    func body(content: Content) -> some View {
        content
            .accessibilityAction(named: task.status == .done ? "Bỏ hoàn thành" : "Hoàn thành") {
                var reward: LedgerEntry?
                ui.run { reward = try store.setStatus(id: task.id, to: task.status == .done ? .open : .done) }
                ui.reward(reward)
            }
            .accessibilityAction(named: "Sửa") { sheet = .edit(task.id) }
            .accessibilityAction(named: "Đổi ngày hoặc giờ") { sheet = .move(task.id) }
    }
}

struct TaskContextMenu: View {
    let task: TaskOccurrenceRecord
    @Binding var sheet: TodaySheet?
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui

    var body: some View {
        if task.status == .done {
            Button { ui.run { try store.setStatus(id: task.id, to: .open) } } label: {
                Label("Bỏ hoàn thành", systemImage: "arrow.uturn.backward")
            }
        } else {
            Button {
                var reward: LedgerEntry?
                ui.run { reward = try store.setStatus(id: task.id, to: .done) }
                ui.reward(reward)
            } label: {
                Label("Hoàn thành", systemImage: "checkmark.circle")
            }
            if task.status == .open {
                Button { ui.run { try store.setStatus(id: task.id, to: .skipped) } } label: {
                    Label("Bỏ qua lần này", systemImage: "forward")
                }
            } else {
                Button { ui.run { try store.setStatus(id: task.id, to: .open) } } label: {
                    Label("Đánh dấu chưa làm", systemImage: "circle")
                }
            }
        }
        Button { sheet = .focus(task.id) } label: { Label("Tập trung cho việc này", systemImage: "timer") }
        if let day = task.day {
            Button {
                ui.run { try store.moveTask(id: task.id, to: day.adding(days: 1, calendar: store.calendar), startMinute: task.startMinute) }
            } label: {
                Label("Chuyển sang ngày mai", systemImage: "arrow.right.circle")
            }
        }
        Button { sheet = .move(task.id) } label: { Label("Đổi ngày / giờ…", systemImage: "calendar") }
        Button { sheet = .edit(task.id) } label: { Label("Sửa", systemImage: "pencil") }
    }
}

/// Chi tiết một việc + các thao tác.
struct TaskDetailSheet: View {
    let taskID: UUID
    @Binding var sheet: TodaySheet?
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Group {
                if let task = store.occurrence(taskID) {
                    content(task)
                } else {
                    EmptyStateView(symbol: "questionmark.circle", title: "Không còn việc này", message: "Việc có thể đã bị xóa.")
                }
            }
            .cozyBackground()
            .navigationTitle("Chi tiết")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Đóng") { dismiss() } }
            }
            .overlay(alignment: .top) { ErrorOverlay() }
        }
    }

    @ViewBuilder
    private func content(_ task: TaskOccurrenceRecord) -> some View {
        let template = store.template(task.templateID)
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Label(task.category.label, systemImage: task.category.symbol)
                        .font(Typography.caption.weight(.semibold))
                        .foregroundStyle(task.category.color)
                    Text(task.title)
                        .font(Typography.title)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(whenText(task))
                        .font(Typography.callout)
                        .foregroundStyle(Palette.inkMuted)
                    if let template {
                        Label(template.recurrence.summary, systemImage: "repeat")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.inkMuted)
                    }
                    if task.isFixed {
                        Label("Giờ cố định (không bị sắp xếp lại)", systemImage: "pin")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.inkMuted)
                    }
                    Label(ReminderPlanner.offsetLabel(task.reminderOffsetMinutes), systemImage: "bell")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.inkMuted)
                }
                if !task.notes.isEmpty {
                    CozyCard { Text(task.notes).font(Typography.body).foregroundStyle(Palette.ink) }
                }
                if !task.checklist.isEmpty {
                    CozyCard {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Text("Việc con")
                                    .font(Typography.headline)
                                    .foregroundStyle(Palette.ink)
                                Spacer()
                                Text(Subtasks.progressLabel(task.checklist) ?? "")
                                    .font(Typography.caption.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(Palette.inkMuted)
                            }
                            ForEach(task.checklist) { item in
                                Button {
                                    ui.run { try store.toggleSubtask(occurrenceID: task.id, subtaskID: item.id) }
                                } label: {
                                    HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                                        Image(systemName: item.isDone ? "checkmark.square.fill" : "square")
                                            .foregroundStyle(item.isDone ? Palette.sage : Palette.inkMuted)
                                        Text(item.title)
                                            .font(Typography.body)
                                            .foregroundStyle(item.isDone ? Palette.inkMuted : Palette.ink)
                                            .strikethrough(item.isDone)
                                            .multilineTextAlignment(.leading)
                                        Spacer(minLength: 0)
                                    }
                                    .frame(minHeight: HitTarget.min)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(item.title)
                                .accessibilityValue(item.isDone ? "đã xong" : "chưa xong")
                                .accessibilityHint("Chạm để đổi trạng thái")
                            }
                        }
                    }
                }

                VStack(spacing: Spacing.s) {
                    if task.status == .done {
                        Button("Bỏ đánh dấu hoàn thành") { ui.run { try store.setStatus(id: task.id, to: .open) } }
                            .buttonStyle(SoftButtonStyle())
                        Text("Phần thưởng đã nhận không bị thu hồi, và hoàn thành lại sẽ không nhận thêm.")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.inkMuted)
                    } else {
                        Button {
                            var reward: LedgerEntry?
                            ui.run { reward = try store.setStatus(id: task.id, to: .done) }
                            ui.reward(reward)
                            dismiss()
                        } label: {
                            Label("Hoàn thành", systemImage: "checkmark")
                        }
                        .buttonStyle(PrimaryButtonStyle(color: Palette.sage))
                        HStack(spacing: Spacing.s) {
                            Button {
                                sheet = .focus(task.id)
                            } label: { Label("Tập trung", systemImage: "timer") }
                            .buttonStyle(SoftButtonStyle())
                            Button {
                                ui.run { try store.setStatus(id: task.id, to: task.status == .skipped ? .open : .skipped) }
                            } label: { Label(task.status == .skipped ? "Chưa làm" : "Bỏ qua", systemImage: "forward") }
                            .buttonStyle(SoftButtonStyle(tint: Palette.inkMuted))
                        }
                    }
                    HStack(spacing: Spacing.s) {
                        Button { sheet = .move(task.id) } label: { Label("Đổi ngày/giờ", systemImage: "calendar") }
                            .buttonStyle(SoftButtonStyle())
                        Button { sheet = .edit(task.id) } label: { Label("Sửa", systemImage: "pencil") }
                            .buttonStyle(SoftButtonStyle())
                    }
                    Button(role: .destructive) { confirmDelete = true } label: {
                        Label("Xóa", systemImage: "trash")
                    }
                    .buttonStyle(SoftButtonStyle(tint: Palette.danger))
                }
            }
            .padding(Spacing.l)
        }
        .confirmationDialog("Xóa việc này?", isPresented: $confirmDelete, titleVisibility: .visible) {
            if task.isRecurring {
                Button("Chỉ lần này", role: .destructive) { delete(task, .thisOnly) }
                Button("Lần này và các lần sau", role: .destructive) { delete(task, .thisAndFuture) }
            } else {
                Button("Xóa", role: .destructive) { delete(task, .thisOnly) }
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Xu và XP đã nhận vẫn được giữ.")
        }
    }

    private func whenText(_ task: TaskOccurrenceRecord) -> String {
        guard let day = task.day else { return "Hộp chờ · \(TimeOfDay.durationLabel(task.durationMinutes))" }
        let date = DateText.long(day, calendar: store.calendar)
        guard let start = task.startMinute else { return "\(date) · chưa xếp giờ · \(TimeOfDay.durationLabel(task.durationMinutes))" }
        return "\(date) · \(TimeOfDay.rangeLabel(start: start, duration: task.durationMinutes))"
    }

    private func delete(_ task: TaskOccurrenceRecord, _ scope: RecurringScope) {
        if ui.run({ try store.deleteTask(id: task.id, scope: scope) }) {
            dismiss()
        }
    }
}

/// Đổi ngày/giờ bằng form — cách thay thế cho kéo thả, dùng được với VoiceOver.
struct MoveTaskSheet: View {
    let taskID: UUID
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var hasTime = true
    @State private var time = Date()
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                if let task = store.occurrence(taskID) {
                    Section {
                        Text(task.title).font(Typography.headline)
                        if task.isRecurring {
                            Text("Việc lặp lại: chỉ lần này được chuyển.")
                                .font(Typography.caption)
                                .foregroundStyle(Palette.inkMuted)
                        }
                    }
                    Section("Ngày mới") {
                        DatePicker("Ngày", selection: $date, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "vi_VN"))
                        Toggle("Có giờ cụ thể", isOn: $hasTime)
                        if hasTime {
                            DatePicker("Bắt đầu", selection: $time, displayedComponents: .hourAndMinute)
                                .environment(\.locale, Locale(identifier: "vi_VN"))
                        }
                    }
                    Section {
                        Button("Lưu thay đổi") { save(task) }
                            .frame(minHeight: HitTarget.min)
                        if task.day != nil {
                            Button("Đưa về Hộp chờ (bỏ ngày)") {
                                if ui.run({ try store.moveTask(id: task.id, to: nil, startMinute: nil) }) { dismiss() }
                            }
                            .frame(minHeight: HitTarget.min)
                        }
                    }
                    .onAppear { load(task) }
                } else {
                    Text("Không còn việc này.")
                }
            }
            .navigationTitle("Đổi ngày / giờ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Hủy") { dismiss() } } }
            .overlay(alignment: .top) { ErrorOverlay() }
        }
    }

    private func load(_ task: TaskOccurrenceRecord) {
        guard !loaded else { return }
        loaded = true
        let day = task.day ?? store.today
        date = day.date(atMinute: 12 * 60, in: store.calendar)
        hasTime = task.startMinute != nil || task.day == nil
        time = day.date(atMinute: task.startMinute ?? 9 * 60, in: store.calendar)
    }

    private func save(_ task: TaskOccurrenceRecord) {
        let day = DayKey(date, calendar: store.calendar)
        let start = hasTime ? store.calendar.minuteOfDay(time) : nil
        if ui.run({ try store.moveTask(id: task.id, to: day, startMinute: start) }) { dismiss() }
    }
}
