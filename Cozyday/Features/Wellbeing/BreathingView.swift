import SwiftUI

/// Bài thở có hướng dẫn: vòng tròn phồng/xẹp theo nhịp, chữ "Hít vào / Giữ hơi / Thở ra".
/// Hoàn thành đủ thời gian → thưởng một lần mỗi ngày (và nạp năng lượng cho chuyến phiêu lưu).
/// Giảm chuyển động: vòng tròn đứng yên, chỉ đổi chữ và vòng tiến độ.
struct BreathingView: View {
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(DayClock.self) private var dayClock
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pattern = BreathingPattern.calm
    @State private var minutes = 1
    @State private var startedAt: Date?
    @State private var finished = false
    @State private var lastPhase = -1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    if finished {
                        doneView
                    } else if let startedAt {
                        running(since: startedAt)
                    } else {
                        setup
                    }
                }
                .padding(Spacing.l)
            }
            .cozyBackground()
            .navigationTitle("Thở chậm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Đóng") { dismiss() } }
            }
        }
    }

    private var setup: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            PetView(appearance: store.petAppearance, mood: .rest, name: store.profile.displayPetName)
                .frame(width: 110, height: 110)
                .frame(maxWidth: .infinity)
            Text("Chọn nhịp thở")
                .font(Typography.headline)
            ForEach(BreathingPattern.all) { p in
                Button {
                    pattern = p
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.name).font(Typography.body.weight(.semibold)).foregroundStyle(Palette.ink)
                            Text(p.detail).font(Typography.caption).foregroundStyle(Palette.inkMuted)
                        }
                        Spacer()
                        if pattern == p {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.sage)
                        }
                    }
                    .padding(Spacing.m)
                    .frame(minHeight: HitTarget.min)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.m))
                    .overlay(RoundedRectangle(cornerRadius: Radius.m).strokeBorder(pattern == p ? Palette.sage : Palette.line))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(pattern == p ? .isSelected : [])
            }
            Text("Thời gian")
                .font(Typography.headline)
            HStack(spacing: Spacing.s) {
                ForEach([1, 2, 3, 5], id: \.self) { m in
                    ChipToggle(title: "\(m) phút", isOn: minutes == m) { minutes = m }
                }
            }
            Button {
                startedAt = Date()
                lastPhase = -1
            } label: {
                Label("Bắt đầu", systemImage: "wind")
            }
            .buttonStyle(PrimaryButtonStyle(color: Palette.sage))
            Text("Bài thở chỉ để thư giãn, không thay thế tư vấn y tế. Thấy chóng mặt thì dừng lại và thở bình thường.")
                .font(Typography.caption)
                .foregroundStyle(Palette.inkMuted)
        }
    }

    private func running(since start: Date) -> some View {
        let total = Double(minutes * 60)
        return TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(start)
            let state = pattern.phase(at: elapsed)
            let expansion = reduceMotion ? 0.6 : pattern.expansion(at: elapsed)
            let remaining = max(0, Int((total - elapsed).rounded(.up)))
            VStack(spacing: Spacing.xl) {
                ZStack {
                    Circle()
                        .stroke(Palette.line, lineWidth: 6)
                        .frame(width: 260, height: 260)
                    Circle()
                        .trim(from: 0, to: min(1, elapsed / total))
                        .stroke(Palette.sage, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 260, height: 260)
                    Circle()
                        .fill(Palette.sage.opacity(0.25))
                        .frame(width: 110 + 130 * expansion, height: 110 + 130 * expansion)
                    PetView(appearance: store.petAppearance, mood: .rest, name: store.profile.displayPetName)
                        .frame(width: 90, height: 90)
                }
                .accessibilityHidden(true)
                Text(state.phase.label)
                    .font(Typography.largeTitle)
                    .foregroundStyle(Palette.ink)
                    .accessibilityAddTraits(.updatesFrequently)
                Text("Còn \(remaining / 60):\(String(format: "%02d", remaining % 60))")
                    .font(Typography.headline.monospacedDigit())
                    .foregroundStyle(Palette.inkMuted)
                Button("Dừng") {
                    startedAt = nil
                }
                .buttonStyle(SoftButtonStyle(tint: Palette.inkMuted))
                .accessibilityHint("Dừng sớm thì không có thưởng")
            }
            .frame(maxWidth: .infinity)
            .onChange(of: state.index) { _, new in
                if lastPhase != new {
                    lastPhase = new
                    UIAccessibility.post(notification: .announcement, argument: state.phase.label)
                }
            }
            .onChange(of: elapsed >= total) { _, isDone in
                if isDone { finish() }
            }
        }
        .sensoryFeedback(trigger: lastPhase) { _, _ in store.profile.hapticsEnabled ? .impact(weight: .light) : nil }
    }

    private var doneView: some View {
        VStack(spacing: Spacing.l) {
            PetView(appearance: store.petAppearance, mood: .happy, name: store.profile.displayPetName, bounceTrigger: 1)
                .frame(width: 130, height: 130)
            Text("Xong rồi!")
                .font(Typography.title)
            Text("\(minutes) phút thở chậm. \(store.profile.displayPetName) thấy nhẹ nhõm cùng bạn.")
                .font(Typography.callout)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
            Button("Xong") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        startedAt = nil
        var entry: LedgerEntry?
        if ui.run({ entry = try store.completeBreathing(day: dayClock.today) }) {
            ui.reward(entry)
        }
    }
}
