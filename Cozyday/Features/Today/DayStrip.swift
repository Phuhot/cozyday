import SwiftUI

/// Thanh chọn ngày theo tuần (Thứ hai → Chủ nhật), có nút về hôm nay và mở lịch.
struct DayStrip: View {
    let selected: DayKey
    let today: DayKey
    let calendar: Calendar
    let onSelect: (DayKey) -> Void
    let onPickDate: () -> Void

    private var weekDays: [DayKey] {
        // Lùi về Thứ hai của tuần chứa ngày đang chọn.
        let weekday = selected.weekday(calendar: calendar) // 1 = CN
        let offsetFromMonday = (weekday + 5) % 7
        let monday = selected.adding(days: -offsetFromMonday, calendar: calendar)
        return (0..<7).map { monday.adding(days: $0, calendar: calendar) }
    }

    var body: some View {
        VStack(spacing: Spacing.s) {
            HStack {
                Button {
                    onSelect(selected.adding(days: -7, calendar: calendar))
                } label: {
                    Image(systemName: "chevron.left").frame(width: HitTarget.min, height: HitTarget.min)
                }
                .accessibilityLabel("Tuần trước")

                Button(action: onPickDate) {
                    HStack(spacing: Spacing.xs) {
                        Text(DateText.monthTitle(year: selected.year, month: selected.month))
                            .font(Typography.headline)
                        Image(systemName: "calendar")
                    }
                    .frame(minHeight: HitTarget.min)
                }
                .accessibilityLabel("Chọn ngày, đang xem \(DateText.full(selected, calendar: calendar))")

                Spacer()

                if selected != today {
                    Button("Hôm nay") { onSelect(today) }
                        .font(Typography.callout.weight(.semibold))
                        .frame(minHeight: HitTarget.min)
                }

                Button {
                    onSelect(selected.adding(days: 7, calendar: calendar))
                } label: {
                    Image(systemName: "chevron.right").frame(width: HitTarget.min, height: HitTarget.min)
                }
                .accessibilityLabel("Tuần sau")
            }
            .foregroundStyle(Palette.ink)

            HStack(spacing: Spacing.xs) {
                ForEach(weekDays, id: \.self) { d in
                    let isSelected = d == selected
                    let isToday = d == today
                    Button { onSelect(d) } label: {
                        VStack(spacing: Spacing.xxs) {
                            Text(Weekday.shortLabel(d.weekday(calendar: calendar)))
                                .font(Typography.caption)
                            Text("\(d.day)")
                                .font(Typography.headline.monospacedDigit())
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .foregroundStyle(isSelected ? Palette.onAccent : (isToday ? Palette.lavender : Palette.ink))
                        .background(
                            RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                                .fill(isSelected ? Palette.lavender : (isToday ? Palette.lavenderSoft : Palette.surface))
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(DateText.full(d, calendar: calendar) + (isToday ? ", hôm nay" : ""))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }
}

struct DayPickerSheet: View {
    let selected: DayKey
    let calendar: Calendar
    let onPick: (DayKey) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            DatePicker("Ngày", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .environment(\.calendar, calendar)
                .environment(\.locale, Locale(identifier: "vi_VN"))
                .padding()
                .navigationTitle("Chọn ngày")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Hủy") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Xem") {
                            onPick(DayKey(date, calendar: calendar))
                            dismiss()
                        }
                    }
                }
        }
        .onAppear { date = selected.date(atMinute: 12 * 60, in: calendar) }
    }
}
