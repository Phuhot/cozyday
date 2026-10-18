import SwiftUI

/// Form tạo/sửa việc.
struct TaskEditorView: View {
    enum Mode {
        case create(day: DayKey?, startMinute: Int?)
        case edit(UUID)
    }

    let mode: Mode
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(NotificationService.self) private var notifications
    @Environment(\.dismiss) private var dismiss

    @State private var draft = TaskDraft()
    @State private var hasDay = true
    @State private var hasTime = true
    @State private var date = Date()
    @State private var time = Date()
    @State private var hasEndDay = false
    @State private var endDate = Date()
    @State private var loaded = false
    @State private var validationMessage: String?
    @State private var askScope = false
    @State private var permissionNote: String?

    private var editingID: UUID? {
        if case .edit(let id) = mode { return id }
        return nil
    }

    private var editingTask: TaskOccurrenceRecord? { editingID.flatMap { store.occurrence($0) } }
    private var isEditingRecurring: Bool { editingTask?.isRecurring == true }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Tên việc", text: $draft.title, axis: .vertical)
                        .font(Typography.headline)
                        .lineLimit(1...3)
                    TextField("Ghi chú (không bắt buộc)", text: $draft.notes, axis: .vertical)
                        .lineLimit(2...6)
                }

                Section("Nhóm & ưu tiên") {
                    Picker("Nhóm", selection: $draft.category) {
                        ForEach(TaskCategory.allCases) { c in
                            Label(c.label, systemImage: c.symbol).tag(c)
                        }
                    }
                    Picker("Ưu tiên", selection: $draft.priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    if isEditingRecurring {
                        LabeledContent("Ngày", value: editingTask?.day.map { DateText.full($0, calendar: store.calendar) } ?? "—")
                        Text("Muốn chuyển ngày của lần này, dùng \"Đổi ngày/giờ\" trong chi tiết việc.")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.inkMuted)
                    } else {
                        Toggle("Xếp vào một ngày", isOn: $hasDay.animation())
                        if hasDay {
                            DatePicker("Ngày", selection: $date, displayedComponents: .date)
                                .environment(\.locale, Locale(identifier: "vi_VN"))
                        } else {
                            Text("Việc sẽ nằm trong Hộp chờ cho tới khi bạn xếp lịch.")
                                .font(Typography.caption)
                                .foregroundStyle(Palette.inkMuted)
                        }
                    }
                    if hasDay || isEditingRecurring {
                        Toggle("Có giờ bắt đầu", isOn: $hasTime.animation())
                        if hasTime {
                            DatePicker("Bắt đầu", selection: $time, displayedComponents: .hourAndMinute)
                                .environment(\.locale, Locale(identifier: "vi_VN"))
                        }
                    }
                    Stepper(value: $draft.durationMinutes, in: TaskValidation.minDuration...TaskValidation.maxDuration, step: 5) {
                        LabeledContent("Thời lượng", value: TimeOfDay.durationLabel(draft.durationMinutes))
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.s) {
                            ForEach([15, 30, 45, 60, 90, 120], id: \.self) { m in
                                ChipToggle(title: TimeOfDay.durationLabel(m), isOn: draft.durationMinutes == m) {
                                    draft.durationMinutes = m
                                }
                            }
                        }
                    }
                    if hasDay || isEditingRecurring, hasTime {
                        Toggle("Giờ cố định (không sắp xếp lại)", isOn: $draft.isFixed)
                    }
                } header: {
                    Text("Thời gian")
                } footer: {
                    if hasTime, hasDay || isEditingRecurring {
                        Text("Kết thúc lúc \(TimeOfDay.label(store.calendar.minuteOfDay(time) + draft.durationMinutes)). Việc không được kéo qua nửa đêm.")
                    }
                }

                if hasTime && (hasDay || isEditingRecurring) {
                    Section {
                        Picker("Nhắc việc", selection: Binding(
                            get: { draft.reminderOffsetMinutes ?? -1 },
                            set: { draft.reminderOffsetMinutes = $0 < 0 ? nil : $0; if $0 >= 0 { askNotificationPermission() } }
                        )) {
                            Text("Không nhắc").tag(-1)
                            ForEach(ReminderPlanner.offsetChoices, id: \.self) { m in
                                Text(ReminderPlanner.offsetLabel(m)).tag(m)
                            }
                        }
                    } footer: {
                        if let permissionNote { Text(permissionNote) }
                    }
                }

                if hasDay || isEditingRecurring {
                    Section {
                        Picker("Lặp lại", selection: $draft.repeatFrequency) {
                            Text("Không lặp").tag(RecurrenceFrequency?.none)
                            ForEach(RecurrenceFrequency.allCases, id: \.self) { f in
                                Text(f.label).tag(RecurrenceFrequency?.some(f))
                            }
                        }
                        if draft.repeatFrequency == .weekly {
                            WeekdayPicker(selection: $draft.repeatWeekdays)
                        }
                        if draft.repeatFrequency != nil {
                            Toggle("Có ngày kết thúc", isOn: $hasEndDay.animation())
                            if hasEndDay {
                                DatePicker("Kết thúc", selection: $endDate, displayedComponents: .date)
                                    .environment(\.locale, Locale(identifier: "vi_VN"))
                            }
                        }
                    } header: {
                        Text("Lặp lại")
                    } footer: {
                        if isEditingRecurring {
                            Text("Khi lưu, bạn chọn áp dụng cho chỉ lần này hay lần này và các lần sau. Đổi lịch lặp chỉ có tác dụng với \"các lần sau\". Các lần đã hoàn thành trước đó không bị sửa.")
                        }
                    }
                }

                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(Palette.danger)
                    }
                }
            }
            .navigationTitle(editingID == nil ? "Việc mới" : "Sửa việc")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { attemptSave() }
                        .disabled(draft.trimmedTitle.isEmpty)
                }
            }
            .confirmationDialog("Áp dụng thay đổi cho", isPresented: $askScope, titleVisibility: .visible) {
                Button("Chỉ lần này") { save(scope: .thisOnly) }
                Button("Lần này và các lần sau") { save(scope: .thisAndFuture) }
                Button("Hủy", role: .cancel) {}
            }
            .overlay(alignment: .top) { ErrorOverlay() }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        switch mode {
        case .create(let day, let start):
            draft.day = day
            hasDay = day != nil
            hasTime = start != nil
            let base = day ?? store.today
            date = base.date(atMinute: 12 * 60, in: store.calendar)
            time = base.date(atMinute: start ?? 9 * 60, in: store.calendar)
            endDate = base.adding(days: 30, calendar: store.calendar).date(atMinute: 12 * 60, in: store.calendar)
        case .edit(let id):
            guard let task = store.occurrence(id) else { return }
            draft = TaskDraft(occurrence: task, template: store.template(task.templateID))
            hasDay = task.day != nil
            hasTime = task.startMinute != nil
            let base = task.day ?? store.today
            date = base.date(atMinute: 12 * 60, in: store.calendar)
            time = base.date(atMinute: task.startMinute ?? 9 * 60, in: store.calendar)
            hasEndDay = draft.repeatEndDay != nil
            endDate = (draft.repeatEndDay ?? base.adding(days: 30, calendar: store.calendar)).date(atMinute: 12 * 60, in: store.calendar)
        }
    }

    /// Dựng draft cuối cùng từ các trường của form.
    private func finalDraft() -> TaskDraft {
        var d = draft
        if isEditingRecurring {
            d.day = editingTask?.day
        } else {
            d.day = hasDay ? DayKey(date, calendar: store.calendar) : nil
        }
        d.startMinute = (d.day != nil && hasTime) ? store.calendar.minuteOfDay(time) : nil
        if d.startMinute == nil {
            d.reminderOffsetMinutes = nil
            d.isFixed = false
        }
        if d.day == nil { d.repeatFrequency = nil }
        d.repeatEndDay = (d.repeatFrequency != nil && hasEndDay) ? DayKey(endDate, calendar: store.calendar) : nil
        if d.repeatFrequency != .weekly { d.repeatWeekdays = [] }
        return d
    }

    private func attemptSave() {
        let d = finalDraft()
        if let error = TaskValidation.validate(d) {
            validationMessage = error.message
            return
        }
        validationMessage = nil
        if isEditingRecurring {
            askScope = true
        } else {
            save(scope: .thisOnly)
        }
    }

    private func save(scope: RecurringScope) {
        let d = finalDraft()
        let ok: Bool
        if let id = editingID {
            ok = ui.run { try store.updateTask(id: id, draft: d, scope: scope) }
        } else {
            ok = ui.run { _ = try store.createTask(d) }
        }
        if ok { dismiss() }
    }

    private func askNotificationPermission() {
        Task {
            let granted = await notifications.requestPermissionIfNeeded()
            permissionNote = granted ? nil : "Thông báo đang bị tắt cho Cozyday. Việc vẫn được lưu; bật lại trong Cài đặt iPhone → Cozyday → Thông báo nếu muốn được nhắc."
        }
    }
}

/// Chọn các thứ trong tuần (Thứ hai → Chủ nhật).
struct WeekdayPicker: View {
    @Binding var selection: Set<Int>

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Weekday.displayOrder, id: \.self) { w in
                let on = selection.contains(w)
                Button {
                    if on { selection.remove(w) } else { selection.insert(w) }
                } label: {
                    Text(Weekday.shortLabel(w))
                        .font(Typography.callout.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: HitTarget.min)
                        .foregroundStyle(on ? Palette.onAccent : Palette.ink)
                        .background(on ? Palette.lavender : Palette.surfaceMuted, in: RoundedRectangle(cornerRadius: Radius.s))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Weekday.longLabel(w))
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}
