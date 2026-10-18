import SwiftUI

/// Timeline dọc của một ngày.
///
/// Quy ước hiển thị: chiều cao tỉ lệ với thời lượng, nhưng mỗi khối cao tối thiểu đủ cho một
/// dòng tiêu đề + giờ. Việc quá ngắn được kéo dài khi vẽ (giờ thật vẫn ghi trên khối). Các khối
/// chồng nhau về hiển thị được chia cột cạnh nhau, không đè chữ; việc trùng giờ thật có biểu tượng cảnh báo.
struct DayTimeline: View {
    let tasks: [TaskOccurrenceRecord]
    let isToday: Bool
    let activeStart: Int
    let activeEnd: Int
    /// Sự kiện từ app Lịch (chỉ đọc), không gồm sự kiện cả ngày.
    var events: [CalendarEvent] = []
    @Binding var sheet: TodaySheet?

    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @ScaledMetric(relativeTo: .body) private var hourHeight: CGFloat = 76
    /// Khối đang được kéo bằng tay nắm (id + quãng kéo dọc, điểm ảnh).
    @State private var drag: (id: UUID, dy: CGFloat)?
    @ScaledMetric(relativeTo: .body) private var minBlockHeight: CGFloat = 46
    private let labelWidth: CGFloat = 46

    private var pointsPerMinute: CGFloat { hourHeight / 60 }

    private var range: (start: Int, end: Int) {
        let starts = tasks.compactMap(\.startMinute) + events.map(\.startMinute)
        let ends = tasks.compactMap(\.endMinute) + events.map { $0.startMinute + $0.durationMinutes }
        let nowMinute = store.calendar.minuteOfDay(store.now)
        // Không vẽ các giờ trống trước việc đầu tiên: mở app buổi chiều vẫn thấy ngay việc sắp tới.
        // Hôm nay: bắt đầu tối đa 1 giờ trước "bây giờ" (hoặc sớm hơn nếu có việc sớm hơn).
        var lo = starts.min() ?? (isToday ? nowMinute - 60 : activeStart)
        var hi = max(activeEnd, ends.max() ?? activeEnd)
        if isToday {
            lo = max(0, min(lo, nowMinute - 60))
            hi = max(hi, nowMinute + 1)
        }
        lo = (lo / 60) * 60
        hi = min(TimeOfDay.minutesPerDay, ((hi + 59) / 60) * 60)
        return (lo, max(hi, lo + 60))
    }

    var body: some View {
        let r = range
        let minMinutes = Int((minBlockHeight / pointsPerMinute).rounded(.up))
        let placements = TimelineLayout.layout(
            tasks.compactMap { t in t.startMinute.map { TimelineLayout.Item(id: t.id, start: $0, duration: t.durationMinutes) } }
                + events.map { TimelineLayout.Item(id: $0.id, start: $0.startMinute, duration: $0.durationMinutes) },
            minDisplayMinutes: minMinutes
        )
        let byID = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
        let eventsByID = Dictionary(events.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let height = CGFloat(r.end - r.start) * pointsPerMinute

        GeometryReader { geo in
            let laneArea = geo.size.width - labelWidth - Spacing.xs
            ZStack(alignment: .topLeading) {
                // Lưới giờ
                ForEach(Array(stride(from: r.start, through: r.end, by: 60)), id: \.self) { minute in
                    let y = CGFloat(minute - r.start) * pointsPerMinute
                    HStack(alignment: .center, spacing: Spacing.xs) {
                        Text(TimeOfDay.label(minute))
                            .font(Typography.caption.monospacedDigit())
                            .foregroundStyle(Palette.inkMuted)
                            .frame(width: labelWidth, alignment: .leading)
                        Rectangle().fill(Palette.line).frame(height: 1)
                    }
                    .frame(height: 16)
                    .offset(y: y - 8)
                    .accessibilityHidden(true)
                }

                ForEach(placements, id: \.id) { p in
                    if let task = byID[p.id] {
                        let laneWidth = laneArea / CGFloat(p.laneCount)
                        let dragging = drag?.id == task.id
                        let dy = dragging ? (drag?.dy ?? 0) : 0
                        TaskBlock(
                            task: task, placement: p, sheet: $sheet,
                            dragPreview: dragging ? snappedStart(task, dy: dy).map(TimeOfDay.label) : nil,
                            onDrag: { drag = (task.id, $0) },
                            onDrop: { commitDrag(task, dy: $0) }
                        )
                        .frame(width: max(0, laneWidth - Spacing.xs),
                               height: max(minBlockHeight, CGFloat(p.displayEnd - p.displayStart) * pointsPerMinute - 2))
                        .offset(x: labelWidth + Spacing.xs + CGFloat(p.lane) * laneWidth,
                                y: CGFloat(p.displayStart - r.start) * pointsPerMinute + 1 + dy)
                        .zIndex(dragging ? 1 : 0)
                        .shadow(color: Color.black.opacity(dragging ? 0.18 : 0), radius: 8, y: 4)
                    } else if let event = eventsByID[p.id] {
                        let laneWidth = laneArea / CGFloat(p.laneCount)
                        EventBlock(event: event)
                            .frame(width: max(0, laneWidth - Spacing.xs),
                                   height: max(minBlockHeight, CGFloat(p.displayEnd - p.displayStart) * pointsPerMinute - 2))
                            .offset(x: labelWidth + Spacing.xs + CGFloat(p.lane) * laneWidth,
                                    y: CGFloat(p.displayStart - r.start) * pointsPerMinute + 1)
                    }
                }

                if isToday {
                    // Chỉ đường "bây giờ" được vẽ lại mỗi phút.
                    TimelineView(.everyMinute) { context in
                        let now = store.calendar.minuteOfDay(context.date)
                        if now >= r.start && now <= r.end {
                            HStack(spacing: 0) {
                                Circle().fill(Palette.nowLine).frame(width: 9, height: 9)
                                Rectangle().fill(Palette.nowLine).frame(height: 2)
                            }
                            .offset(x: labelWidth - 4, y: CGFloat(now - r.start) * pointsPerMinute - 4.5)
                            .accessibilityElement()
                            .accessibilityLabel("Bây giờ là \(TimeOfDay.label(now))")
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
        }
        .frame(height: height + 8)
        .padding(.top, 8)
    }

    /// Giờ bắt đầu mới khi kéo `dy` điểm ảnh: làm tròn 5 phút, không ra ngoài ngày.
    private func snappedStart(_ task: TaskOccurrenceRecord, dy: CGFloat) -> Int? {
        guard let start = task.startMinute else { return nil }
        let raw = Double(start) + Double(dy / pointsPerMinute)
        let snapped = Int((raw / 5).rounded()) * 5
        return min(max(0, snapped), TimeOfDay.minutesPerDay - task.durationMinutes)
    }

    private func commitDrag(_ task: TaskOccurrenceRecord, dy: CGFloat) {
        drag = nil
        guard let new = snappedStart(task, dy: dy), new != task.startMinute else { return }
        ui.run { try store.moveTask(id: task.id, to: task.day, startMinute: new) }
    }
}

/// Khối việc trên timeline.
struct TaskBlock: View {
    let task: TaskOccurrenceRecord
    let placement: TimelineLayout.Placement
    @Binding var sheet: TodaySheet?
    /// Giờ mới đang hiển thị khi kéo (nil = không kéo).
    var dragPreview: String?
    var onDrag: ((CGFloat) -> Void)?
    var onDrop: ((CGFloat) -> Void)?

    private var draggable: Bool { task.status == .open && task.startMinute != nil && onDrag != nil }

    var body: some View {
        let done = task.status == .done
        let skipped = task.status == .skipped
        HStack(alignment: .top, spacing: 0) {
            if draggable {
                // Tay nắm: kéo lên/xuống để đổi giờ (làm tròn 5 phút). VoiceOver dùng thao tác "Đổi ngày hoặc giờ".
                ZStack {
                    task.category.color
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 9, weight: .bold))
                        .rotationEffect(.degrees(90))
                        .foregroundStyle(Color.white.opacity(0.9))
                }
                .frame(width: 16)
                .contentShape(Rectangle())
                .highPriorityGesture(
                    DragGesture(minimumDistance: 3, coordinateSpace: .global)
                        .onChanged { onDrag?($0.translation.height) }
                        .onEnded { onDrop?($0.translation.height) }
                )
                .accessibilityHidden(true)
            } else {
                Rectangle()
                    .fill(task.category.color)
                    .frame(width: 4)
            }
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(task.title)
                    .font(Typography.callout.weight(.semibold))
                    .strikethrough(done || skipped)
                    .foregroundStyle(Palette.ink.opacity(done || skipped ? 0.55 : 1))
                    .lineLimit(placement.laneCount > 2 ? 1 : 2)
                HStack(spacing: Spacing.xs) {
                    Text(TimeOfDay.rangeLabel(start: task.startMinute ?? 0, duration: task.durationMinutes))
                        .font(Typography.caption.monospacedDigit())
                    if placement.overlapsRealTime {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(Palette.peach)
                            .accessibilityLabel("Trùng giờ")
                    }
                    if let progress = Subtasks.progressLabel(task.checklist) {
                        Text(progress).monospacedDigit()
                    }
                    if task.isRecurring { Image(systemName: "repeat").accessibilityHidden(true) }
                    if task.reminderOffsetMinutes != nil { Image(systemName: "bell").accessibilityHidden(true) }
                    if task.isFixed { Image(systemName: "pin").accessibilityHidden(true) }
                }
                .font(Typography.caption)
                .foregroundStyle(Palette.inkMuted)
                .lineLimit(1)
            }
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.xs + 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            CompleteButton(task: task)
        }
        .background(task.category.softColor)
        .clipShape(RoundedRectangle(cornerRadius: Radius.s, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.s, style: .continuous)
                .strokeBorder(placement.overlapsRealTime ? Palette.peach : Color.clear, lineWidth: 1.5)
        )
        .overlay(alignment: .topTrailing) {
            if let dragPreview {
                Text(dragPreview)
                    .font(Typography.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(Palette.onAccent)
                    .padding(.horizontal, Spacing.s)
                    .padding(.vertical, 2)
                    .background(Palette.lavender, in: Capsule())
                    .offset(x: -4, y: -10)
            }
        }
        .sensoryFeedback(.selection, trigger: dragPreview)
        .contentShape(Rectangle())
        .onTapGesture { sheet = .detail(task.id) }
        .contextMenu { TaskContextMenu(task: task, sheet: $sheet) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(TaskAccessibility.label(task, overlaps: placement.overlapsRealTime))
        .accessibilityHint("Chạm hai lần để xem chi tiết")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { sheet = .detail(task.id) }
        .modifier(TaskAccessibilityActions(task: task, sheet: $sheet))
    }
}

/// Sự kiện từ app Lịch trên timeline: chỉ để xem, viền nét đứt để phân biệt với việc của Cozyday.
struct EventBlock: View {
    let event: CalendarEvent

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Label(event.title, systemImage: "calendar")
                .font(Typography.callout.weight(.semibold))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
            Text(TimeOfDay.rangeLabel(start: event.startMinute, duration: event.durationMinutes) + (event.calendarTitle.isEmpty ? "" : " · \(event.calendarTitle)"))
                .font(Typography.caption.monospacedDigit())
                .foregroundStyle(Palette.inkMuted)
                .lineLimit(1)
        }
        .padding(.horizontal, Spacing.s)
        .padding(.vertical, Spacing.xs + 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.surfaceMuted.opacity(0.8), in: RoundedRectangle(cornerRadius: Radius.s, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.s, style: .continuous)
                .strokeBorder(Palette.inkMuted.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sự kiện trong app Lịch: \(event.title), từ \(TimeOfDay.label(event.startMinute)) đến \(TimeOfDay.label(event.startMinute + event.durationMinutes))")
    }
}
