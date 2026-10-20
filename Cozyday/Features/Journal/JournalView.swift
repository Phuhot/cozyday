import SwiftUI

/// Mặt cười vẽ bằng code cho mood 1–5 (luôn đi kèm nhãn chữ).
struct MoodFace: View {
    let mood: Mood

    static func color(_ mood: Mood) -> Color {
        switch mood {
        case .veryLow: return Color.dynamic(light: 0xA9A3C9, dark: 0x8F88B5)
        case .low: return Color.dynamic(light: 0xB9C7E6, dark: 0x8FA2CC)
        case .okay: return Color.dynamic(light: 0xE9DCC4, dark: 0xCDBB9A)
        case .good: return Color.dynamic(light: 0xB7D6B0, dark: 0x93BC8B)
        case .great: return Color.dynamic(light: 0xF5C77E, dark: 0xE9B35E)
        }
    }

    var body: some View {
        Canvas { context, size in
            var ctx = context
            ctx.scaleBy(x: size.width / 100, y: size.height / 100)
            ctx.ellipse(4, 4, 92, 92, Self.color(mood))
            let ink = Palette.catInk
            ctx.ellipse(31, 36, 9, 11, ink)
            ctx.ellipse(60, 36, 9, 11, ink)
            // độ cong miệng: -1 (buồn) … +1 (vui)
            let curve: CGFloat = [-1, -0.5, 0, 0.6, 1][mood.rawValue - 1]
            ctx.strokePath(ink, width: 5) { p in
                p.move(to: CGPoint(x: 30, y: 66))
                p.addQuadCurve(to: CGPoint(x: 70, y: 66), control: CGPoint(x: 50, y: 66 + curve * 18))
            }
        }
        .accessibilityHidden(true)
    }
}

struct JournalView: View {
    @Environment(AppStore.self) private var store
    @Environment(DayClock.self) private var dayClock
    @State private var month: (year: Int, month: Int)?
    @State private var editingDay: DayKey?
    @State private var showBreathing = false

    private var shown: (year: Int, month: Int) { month ?? (dayClock.today.year, dayClock.today.month) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    todayCard
                    breathingCard
                    monthHeader
                    calendarGrid
                    legend
                    recentList
                }
                .padding(Spacing.l)
            }
            .cozyBackground()
            .navigationTitle("Nhật ký")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { SettingsButton() } }
            .sheet(isPresented: $showBreathing) { BreathingView() }
            .sheet(item: Binding(get: { editingDay.map(IdentifiedDay.init) }, set: { editingDay = $0?.day })) { item in
                JournalEditor(day: item.day)
                    .presentationDetents([.large])
            }
        }
    }

    private var breathingCard: some View {
        let doneToday = store.ledgerKeys.contains(LedgerKeys.breathing(dayClock.today))
        return Button {
            showBreathing = true
        } label: {
            HStack(spacing: Spacing.m) {
                Image(systemName: "wind")
                    .font(.title2)
                    .foregroundStyle(Palette.sage)
                    .frame(width: 44, height: 44)
                    .background(Palette.sage.opacity(0.15), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Thở chậm một chút")
                        .font(Typography.headline)
                        .foregroundStyle(Palette.ink)
                    Text(doneToday ? "Hôm nay bạn đã thở cùng \(store.profile.displayPetName) rồi." : "1–5 phút, có hướng dẫn. +\(RewardConfig.breathingCoins) xu mỗi ngày.")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.inkMuted)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(Palette.inkMuted).accessibilityHidden(true)
            }
            .padding(Spacing.m)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.l))
            .overlay(RoundedRectangle(cornerRadius: Radius.l).strokeBorder(Palette.line))
        }
        .buttonStyle(.plain)
        .task {
            if PreviewMode.current == .breathing {
                try? await Task.sleep(nanoseconds: 600_000_000)
                showBreathing = true
            } else if PreviewMode.current == .journalEditor {
                try? await Task.sleep(nanoseconds: 600_000_000)
                editingDay = dayClock.today
            }
        }
    }

    private var todayCard: some View {
        let entry = store.journalEntry(for: dayClock.today)
        return CozyCard {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Hôm nay thế nào?")
                    .font(Typography.headline)
                if let entry, let mood = Mood(rawValue: entry.mood) {
                    HStack(spacing: Spacing.m) {
                        MoodFace(mood: mood).frame(width: 44, height: 44)
                        VStack(alignment: .leading) {
                            Text(mood.label).font(Typography.body.weight(.semibold))
                            if !entry.note.isEmpty {
                                Text(entry.note).font(Typography.callout).foregroundStyle(Palette.inkMuted).lineLimit(3)
                            }
                        }
                    }
                    Button("Sửa nhật ký hôm nay") { editingDay = dayClock.today }
                        .buttonStyle(SoftButtonStyle())
                } else {
                    Text("Chọn tâm trạng và viết vài dòng. Nhật ký chỉ lưu trên iPhone này.")
                        .font(Typography.callout)
                        .foregroundStyle(Palette.inkMuted)
                    Button("Viết nhật ký") { editingDay = dayClock.today }
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { shift(-1) } label: {
                Image(systemName: "chevron.left").frame(width: HitTarget.min, height: HitTarget.min)
            }
            .accessibilityLabel("Tháng trước")
            Spacer()
            Text(DateText.monthTitle(year: shown.year, month: shown.month))
                .font(Typography.headline)
            Spacer()
            Button { shift(1) } label: {
                Image(systemName: "chevron.right").frame(width: HitTarget.min, height: HitTarget.min)
            }
            .accessibilityLabel("Tháng sau")
        }
    }

    private var calendarGrid: some View {
        let first = DayKey(year: shown.year, month: shown.month, day: 1)
        let offset = (first.weekday(calendar: store.calendar) + 5) % 7 // Thứ hai = 0
        let daysInMonth = store.calendar.range(of: .day, in: .month, for: first.startDate(in: store.calendar))?.count ?? 30
        let year = shown.year, monthNumber = shown.month
        let cells: [DayKey?] = Array(repeating: nil, count: offset) + (1...daysInMonth).map { Optional(DayKey(year: year, month: monthNumber, day: $0)) }
        let byDay = Dictionary(store.journal.map { ($0.day, $0) }, uniquingKeysWith: { a, _ in a })
        return VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                ForEach(Weekday.displayOrder, id: \.self) { w in
                    Text(Weekday.shortLabel(w))
                        .font(Typography.caption)
                        .foregroundStyle(Palette.inkMuted)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 7), spacing: Spacing.xs) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                    if let d = cell {
                        dayCell(d, entry: byDay[d])
                    } else {
                        Color.clear.frame(height: HitTarget.min)
                    }
                }
            }
        }
    }

    private func dayCell(_ d: DayKey, entry: JournalRecord?) -> some View {
        let future = d > dayClock.today
        let mood = entry.flatMap { Mood(rawValue: $0.mood) }
        return Button {
            editingDay = d
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.s)
                    .fill(mood.map(MoodFace.color) ?? (d == dayClock.today ? Palette.lavenderSoft : Palette.surface))
                Text("\(d.day)")
                    .font(Typography.callout.monospacedDigit())
                    .foregroundStyle(future ? Palette.inkMuted.opacity(0.5) : Palette.ink)
            }
            .frame(minHeight: HitTarget.min)
        }
        .buttonStyle(.plain)
        .disabled(future)
        .accessibilityLabel(Self.cellLabel(d, mood: mood, calendar: store.calendar))
    }

    private static func cellLabel(_ d: DayKey, mood: Mood?, calendar: Calendar) -> String {
        let date = DateText.full(d, calendar: calendar)
        guard let mood else { return date + ", chưa có nhật ký" }
        return date + ", tâm trạng " + mood.label
    }

    private var legend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.m) {
                ForEach(Mood.allCases) { m in
                    HStack(spacing: Spacing.xs) {
                        Circle().fill(MoodFace.color(m)).frame(width: 12, height: 12)
                        Text(m.label).font(Typography.caption).foregroundStyle(Palette.inkMuted)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    private var recentList: some View {
        let recent = store.journal.sorted { $0.day > $1.day }.prefix(10)
        return VStack(alignment: .leading, spacing: Spacing.s) {
            if !recent.isEmpty {
                Text("Gần đây").font(Typography.headline)
                ForEach(Array(recent)) { entry in
                    Button { editingDay = entry.day } label: {
                        HStack(alignment: .top, spacing: Spacing.m) {
                            if let mood = Mood(rawValue: entry.mood) {
                                MoodFace(mood: mood).frame(width: 32, height: 32)
                            }
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(DateText.full(entry.day, calendar: store.calendar))
                                    .font(Typography.caption.weight(.semibold))
                                    .foregroundStyle(Palette.inkMuted)
                                Text(entry.note.isEmpty ? (Mood(rawValue: entry.mood)?.label ?? "") : entry.note)
                                    .font(Typography.callout)
                                    .foregroundStyle(Palette.ink)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(Spacing.m)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.m))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func shift(_ delta: Int) {
        var y = shown.year, m = shown.month + delta
        if m < 1 { m = 12; y -= 1 }
        if m > 12 { m = 1; y += 1 }
        month = (y, m)
    }
}

struct IdentifiedDay: Identifiable {
    let day: DayKey
    var id: String { day.string }
}

struct JournalEditor: View {
    let day: DayKey
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss
    @State private var mood: Mood?
    @State private var note = ""
    @State private var loaded = false
    @State private var confirmDelete = false
    @State private var promptShift = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    let prompt = JournalPrompts.prompt(for: day, shift: promptShift)
                    Text(prompt)
                        .font(Typography.body.italic())
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button {
                            note = note.isEmpty ? prompt + "\n" : note + (note.hasSuffix("\n") ? "" : "\n") + prompt + "\n"
                        } label: {
                            Label("Dùng câu này", systemImage: "text.insert")
                        }
                        .buttonStyle(.borderless)
                        Spacer()
                        Button {
                            promptShift += 1
                        } label: {
                            Label("Câu khác", systemImage: "shuffle")
                        }
                        .buttonStyle(.borderless)
                    }
                    .font(Typography.callout)
                } header: {
                    Text("Gợi ý viết")
                } footer: {
                    Text("Không bắt buộc. Viết gì cũng được, một chữ cũng được.")
                }
                Section("Tâm trạng") {
                    HStack(spacing: Spacing.xs) {
                        ForEach(Mood.allCases) { m in
                            Button { mood = m } label: {
                                VStack(spacing: Spacing.xs) {
                                    MoodFace(mood: m)
                                        .frame(width: 40, height: 40)
                                        .overlay(Circle().strokeBorder(mood == m ? Palette.lavender : .clear, lineWidth: 3).padding(-3))
                                    Text(m.label)
                                        .font(.caption2)
                                        .foregroundStyle(mood == m ? Palette.ink : Palette.inkMuted)
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, minHeight: 72)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(m.rawValue) trên 5, \(m.label)")
                            .accessibilityAddTraits(mood == m ? .isSelected : [])
                        }
                    }
                }
                Section {
                    TextEditor(text: $note)
                        .frame(minHeight: 160)
                        .accessibilityLabel("Ghi chú nhật ký")
                } header: {
                    Text("Ghi chú")
                } footer: {
                    Text("\(note.count)/\(JournalRecord.maxNoteLength) ký tự · lưu dạng chữ thường trên máy, có trong file sao lưu.")
                }
                if store.journalEntry(for: day) != nil {
                    Section {
                        Button("Xóa nhật ký ngày này", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(DateText.full(day, calendar: store.calendar))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { save() }.disabled(mood == nil)
                }
            }
            .confirmationDialog("Xóa nhật ký này?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Xóa", role: .destructive) {
                    if ui.run({ try store.deleteJournal(day: day) }) { dismiss() }
                }
            }
            .overlay(alignment: .top) { ErrorOverlay() }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                if let entry = store.journalEntry(for: day) {
                    mood = Mood(rawValue: entry.mood)
                    note = entry.note
                }
            }
            .onChange(of: note) { _, new in
                if new.count > JournalRecord.maxNoteLength { note = String(new.prefix(JournalRecord.maxNoteLength)) }
            }
        }
    }

    private func save() {
        guard let mood else { return }
        var reward: LedgerEntry?
        if ui.run({ reward = try store.saveJournal(day: day, mood: mood, note: note) }) {
            ui.reward(reward)
            dismiss()
        }
    }
}
