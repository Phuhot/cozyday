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
    @Binding var sheet: TodaySheet?

    @Environment(AppStore.self) private var store
    @ScaledMetric(relativeTo: .body) private var hourHeight: CGFloat = 76
    @ScaledMetric(relativeTo: .body) private var minBlockHeight: CGFloat = 46
    private let labelWidth: CGFloat = 46

    private var pointsPerMinute: CGFloat { hourHeight / 60 }

    private var range: (start: Int, end: Int) {
        let starts = tasks.compactMap(\.startMinute)
        let ends = tasks.compactMap(\.endMinute)
        let nowMinute = store.calendar.minuteOfDay(store.now)
        var lo = min(activeStart, starts.min() ?? activeStart)
        var hi = max(activeEnd, ends.max() ?? activeEnd)
        if isToday {
            lo = min(lo, nowMinute)
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
            tasks.compactMap { t in t.startMinute.map { TimelineLayout.Item(id: t.id, start: $0, duration: t.durationMinutes) } },
            minDisplayMinutes: minMinutes
        )
        let byID = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
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
                        TaskBlock(task: task, placement: p, sheet: $sheet)
                            .frame(width: max(0, laneWidth - Spacing.xs),
                                   height: max(minBlockHeight, CGFloat(p.displayEnd - p.displayStart) * pointsPerMinute - 2))
                            .offset(x: labelWidth + Spacing.xs + CGFloat(p.lane) * laneWidth,
                                    y: CGFloat(p.displayStart - r.start) * pointsPerMinute + 1)
                    }
                }

                if isToday {
                    let now = store.calendar.minuteOfDay(store.now)
                    if now >= r.start && now <= r.end {
                        HStack(spacing: 0) {
                            Circle().fill(Palette.nowLine).frame(width: 9, height: 9)
                            Rectangle().fill(Palette.nowLine).frame(height: 2)
                        }
                        .offset(x: labelWidth - 4, y: CGFloat(now - r.start) * pointsPerMinute - 4.5)
                        .allowsHitTesting(false)
                        .accessibilityElement()
                        .accessibilityLabel("Bây giờ là \(TimeOfDay.label(now))")
                    }
                }
            }
        }
        .frame(height: height + 8)
        .padding(.top, 8)
    }
}

/// Khối việc trên timeline.
struct TaskBlock: View {
    let task: TaskOccurrenceRecord
    let placement: TimelineLayout.Placement
    @Binding var sheet: TodaySheet?

    var body: some View {
        let done = task.status == .done
        let skipped = task.status == .skipped
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(task.category.color)
                .frame(width: 4)
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
