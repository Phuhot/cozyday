import SwiftUI
import Charts

/// Tab "Tiến bộ": chỉ hiển thị dữ liệu thật. Không suy luận gì về tâm lý từ mood.
struct StatsView: View {
    @Environment(AppStore.self) private var store
    @Environment(DayClock.self) private var dayClock
    @State private var range = 7
    @State private var metric = 0

    var body: some View {
        let today = dayClock.today
        let days = today.adding(days: -(range - 1), calendar: store.calendar).through(today, calendar: store.calendar)
        let summary = StatsCalculator.summary(
            days: days, occurrences: store.occurrences, focusSessions: store.focusSessions,
            journal: store.journal, calendar: store.calendar
        )
        let allActive = Set(StatsCalculator.summary(
            days: today.adding(days: -365, calendar: store.calendar).through(today, calendar: store.calendar),
            occurrences: store.occurrences, focusSessions: store.focusSessions,
            journal: store.journal, calendar: store.calendar
        ).days.filter(\.isActive).map(\.day))
        let streak = StatsCalculator.currentStreak(activeDays: allActive, today: today, calendar: store.calendar)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    HStack(spacing: Spacing.m) {
                        Picker("Khoảng thời gian", selection: $range) {
                            Text("7 ngày").tag(7)
                            Text("30 ngày").tag(30)
                        }
                        .pickerStyle(.segmented)
                        CoinBadge(coins: store.wallet.coins)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.m) {
                        StatTile(value: "\(summary.completedTasks)", label: "việc đã xong", symbol: "checkmark.circle", tint: Palette.sage)
                        StatTile(value: "\(summary.focusMinutes)", label: "phút tập trung", symbol: "timer", tint: Palette.lavender)
                        StatTile(value: "\(summary.activeDays)/\(range)", label: "ngày có hoạt động", symbol: "calendar", tint: Palette.peach)
                        StatTile(value: "\(streak)", label: "ngày liên tiếp", symbol: "flame", tint: Palette.honey)
                    }

                    CozyCard {
                        VStack(alignment: .leading, spacing: Spacing.m) {
                            Picker("Biểu đồ", selection: $metric) {
                                Text("Việc xong").tag(0)
                                Text("Phút tập trung").tag(1)
                            }
                            .pickerStyle(.segmented)
                            if summary.completedTasks == 0 && summary.focusMinutes == 0 {
                                Text("Chưa có dữ liệu trong khoảng này. Biểu đồ sẽ hiện khi bạn hoàn thành việc hoặc phiên tập trung.")
                                    .font(Typography.callout)
                                    .foregroundStyle(Palette.inkMuted)
                                    .frame(minHeight: 120)
                            } else {
                                Chart(summary.days) { d in
                                    BarMark(
                                        x: .value("Ngày", d.day.startDate(in: store.calendar), unit: .day),
                                        y: .value(metric == 0 ? "Việc" : "Phút", metric == 0 ? d.completedTasks : d.focusMinutes)
                                    )
                                    .foregroundStyle(metric == 0 ? Palette.sage : Palette.lavender)
                                    .cornerRadius(4)
                                }
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .day, count: range == 7 ? 1 : 7)) { value in
                                        AxisGridLine()
                                        AxisValueLabel {
                                            if let date = value.as(Date.self) {
                                                Text(DateText.short(DayKey(date, calendar: store.calendar)))
                                            }
                                        }
                                    }
                                }
                                .frame(height: 200)
                                .accessibilityLabel(metric == 0 ? "Biểu đồ số việc đã xong mỗi ngày" : "Biểu đồ phút tập trung mỗi ngày")
                            }
                        }
                    }

                    Text("\"Việc đã xong\" phản ánh trạng thái hiện tại: bỏ đánh dấu hoàn thành thì thống kê giảm, nhưng xu/XP đã nhận được giữ nguyên.")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.inkMuted)

                    ledgerSection
                }
                .padding(Spacing.l)
            }
            .cozyBackground()
            .navigationTitle("Tiến bộ")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { SettingsButton() }
            }
        }
    }

    private var ledgerSection: some View {
        let entries = store.ledger.sorted { $0.createdAt > $1.createdAt }.prefix(60)
        return VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Lịch sử xu & vật phẩm").font(Typography.headline)
            if entries.isEmpty {
                Text("Chưa có giao dịch nào.")
                    .font(Typography.callout)
                    .foregroundStyle(Palette.inkMuted)
            }
            ForEach(Array(entries)) { e in
                HStack(spacing: Spacing.m) {
                    Image(systemName: icon(e.kind))
                        .foregroundStyle(e.kind == .purchase ? Palette.peach : Palette.sage)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(e.kind == .purchase ? "Mua \(e.memo)" : e.kind.label)
                            .font(Typography.callout.weight(.medium))
                        Text(subtitle(e))
                            .font(Typography.caption)
                            .foregroundStyle(Palette.inkMuted)
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: Spacing.xxs) {
                        Text(e.coins == 0 ? "0 xu" : (e.coins > 0 ? "+\(e.coins) xu" : "\(e.coins) xu"))
                            .font(Typography.callout.weight(.semibold).monospacedDigit())
                            .foregroundStyle(e.coins < 0 ? Palette.danger : Palette.ink)
                        if e.xp > 0 {
                            Text("+\(e.xp) XP").font(Typography.caption.monospacedDigit()).foregroundStyle(Palette.inkMuted)
                        }
                    }
                }
                .padding(Spacing.m)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.m))
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func icon(_ kind: LedgerKind) -> String {
        switch kind {
        case .taskCompleted: return "checkmark.circle"
        case .focusCompleted: return "timer"
        case .journalWritten: return "book"
        case .purchase: return "bag"
        }
    }

    private func subtitle(_ e: LedgerEntry) -> String {
        let when = DateText.dateTime(e.createdAt, calendar: store.calendar)
        switch e.kind {
        case .taskCompleted, .focusCompleted: return "\(when) · \(e.memo)"
        default: return when
        }
    }
}

struct StatTile: View {
    let value: String
    let label: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Image(systemName: symbol).foregroundStyle(tint).accessibilityHidden(true)
            Text(value)
                .font(Typography.numeric)
                .foregroundStyle(Palette.ink)
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(Palette.inkMuted)
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.l))
        .accessibilityElement(children: .combine)
    }
}
