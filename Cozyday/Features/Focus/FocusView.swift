import SwiftUI

/// Hẹn giờ tập trung. Nguồn sự thật là phiên đã lưu (mốc thời gian); đồng hồ trên màn hình
/// chỉ để vẽ. Đóng app/ khóa máy vẫn tính đúng khi mở lại.
struct FocusView: View {
    var preselectedTaskID: UUID?

    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(NotificationService.self) private var notifications
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var focusMinutes = 25
    @State private var restMinutes = 5
    @State private var taskID: UUID?
    @State private var finished: FocusSessionRecord?
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    if let session = store.activeFocus {
                        running(session)
                    } else if let finished {
                        finishedView(finished)
                    } else {
                        setup
                    }
                }
                .padding(Spacing.l)
            }
            .cozyBackground()
            .navigationTitle("Tập trung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Đóng") { dismiss() } } }
            .overlay(alignment: .top) { ErrorOverlay() }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                taskID = preselectedTaskID
            }
        }
    }

    // MARK: Thiết lập

    private var setup: some View {
        let todaysOpen = store.tasks(on: store.today).filter { $0.status == .open }
        return VStack(alignment: .leading, spacing: Spacing.l) {
            PetView(appearance: store.petAppearance, mood: .focus, name: store.profile.displayPetName)
                .frame(width: 120, height: 120)
                .frame(maxWidth: .infinity)

            Text("Chọn nhịp")
                .font(Typography.headline)
            HStack(spacing: Spacing.s) {
                ForEach(FocusPresets.all) { preset in
                    ChipToggle(title: preset.label, isOn: focusMinutes == preset.focus && restMinutes == preset.rest) {
                        focusMinutes = preset.focus
                        restMinutes = preset.rest
                    }
                    .accessibilityLabel("\(preset.focus) phút tập trung, \(preset.rest) phút nghỉ")
                }
            }
            Stepper(value: $focusMinutes, in: FocusPresets.customRange, step: 5) {
                LabeledContent("Tập trung", value: "\(focusMinutes) phút")
            }
            Stepper(value: $restMinutes, in: 5...30, step: 5) {
                LabeledContent("Nghỉ sau đó", value: "\(restMinutes) phút")
            }

            Picker("Gắn với việc", selection: $taskID) {
                Text("Không gắn việc").tag(UUID?.none)
                ForEach(todaysOpen) { t in
                    Text(t.title).tag(UUID?.some(t.id))
                }
                if let id = taskID, !todaysOpen.contains(where: { $0.id == id }), let t = store.occurrence(id) {
                    Text(t.title).tag(UUID?.some(id))
                }
            }
            .pickerStyle(.menu)

            Button {
                start(kind: .focus, minutes: focusMinutes)
            } label: {
                Label("Bắt đầu \(focusMinutes) phút", systemImage: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            policyNote
        }
    }

    private var policyNote: some View {
        let reward = RewardConfig.focusReward(plannedMinutes: focusMinutes)
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(reward.xp > 0
                 ? "Chạy hết \(focusMinutes) phút: +\(reward.xp) XP, +\(reward.coins) xu."
                 : "Phiên dưới \(RewardConfig.focusMinMinutesForReward) phút không có thưởng.")
            Text("Tạm dừng không tính vào phút tập trung. Kết thúc sớm không có thưởng nhưng số phút đã tập trung vẫn được ghi lại. Cozyday không chặn ứng dụng khác.")
        }
        .font(Typography.caption)
        .foregroundStyle(Palette.inkMuted)
    }

    // MARK: Đang chạy

    private func running(_ session: FocusSessionRecord) -> some View {
        VStack(spacing: Spacing.l) {
            if let id = session.occurrenceID, let task = store.occurrence(id) {
                Label(task.title, systemImage: "checklist")
                    .font(Typography.headline)
                    .foregroundStyle(Palette.inkMuted)
            }
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let remaining = session.remaining(at: context.date)
                let progress = 1 - remaining / Double(max(1, session.plannedSeconds))
                ZStack {
                    Circle().stroke(Palette.surfaceMuted, lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(session.kind == .focus ? Palette.lavender : Palette.sage, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: Spacing.xs) {
                        Text(Self.clock(remaining))
                            .font(.system(size: 54, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(Palette.ink)
                        Text(session.isPaused ? "Đang tạm dừng" : session.kind.label)
                            .font(Typography.callout)
                            .foregroundStyle(Palette.inkMuted)
                    }
                }
                .frame(width: 250, height: 250)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(session.kind.label), còn \(Int(remaining / 60)) phút \(Int(remaining) % 60) giây\(session.isPaused ? ", đang tạm dừng" : "")")
                .onChange(of: remaining <= 0.5) { _, reached in
                    if reached { reconcile() }
                }
            }

            PetView(appearance: store.petAppearance, mood: session.kind == .focus ? .focus : .rest, name: store.profile.displayPetName)
                .frame(width: 90, height: 90)

            HStack(spacing: Spacing.m) {
                if session.isPaused {
                    Button {
                        ui.run { try store.resumeFocus() }
                    } label: { Label("Tiếp tục", systemImage: "play.fill") }
                    .buttonStyle(PrimaryButtonStyle())
                } else {
                    Button {
                        ui.run { try store.pauseFocus() }
                    } label: { Label("Tạm dừng", systemImage: "pause.fill") }
                    .buttonStyle(PrimaryButtonStyle(color: Palette.inkMuted))
                }
                Button {
                    endEarly()
                } label: { Label("Kết thúc", systemImage: "stop.fill") }
                .buttonStyle(SoftButtonStyle(tint: Palette.danger))
            }
            Text("Bạn có thể khóa máy hoặc chuyển app. Nếu đã bật thông báo, Cozyday sẽ báo khi hết giờ.")
                .font(Typography.caption)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
        }
        .task {
            if notifications.permission == .notDetermined || notifications.permission == .unknown {
                await notifications.requestPermissionIfNeeded()
                notifications.syncFocus(store: store)
            }
        }
    }

    // MARK: Kết thúc

    private func finishedView(_ session: FocusSessionRecord) -> some View {
        VStack(spacing: Spacing.l) {
            PetView(appearance: store.petAppearance, mood: session.status == .completed ? .happy : .idle,
                    name: store.profile.displayPetName, bounceTrigger: session.status == .completed ? 1 : 0)
                .frame(width: 130, height: 130)
            Text(session.status == .completed ? "Xong rồi!" : "Đã kết thúc sớm")
                .font(Typography.title)
            Text(session.kind == .focus
                 ? "Bạn đã tập trung \(Int(session.focusedSeconds / 60)) phút."
                 : "Hết giờ nghỉ.")
                .foregroundStyle(Palette.inkMuted)
            if session.kind == .focus {
                Button {
                    start(kind: .rest, minutes: restMinutes)
                } label: { Label("Nghỉ \(restMinutes) phút", systemImage: "cup.and.saucer") }
                .buttonStyle(PrimaryButtonStyle(color: Palette.sage))
                if let id = session.occurrenceID, let task = store.occurrence(id), task.status == .open {
                    Button {
                        var reward: LedgerEntry?
                        ui.run { reward = try store.setStatus(id: id, to: .done) }
                        ui.reward(reward)
                    } label: { Label("Đánh dấu \"\(task.title)\" đã xong", systemImage: "checkmark") }
                    .buttonStyle(SoftButtonStyle())
                }
            }
            Button("Phiên mới") { finished = nil }
                .buttonStyle(SoftButtonStyle())
        }
    }

    // MARK: Hành động

    private func start(kind: FocusKind, minutes: Int) {
        finished = nil
        let linked = kind == .focus ? taskID : nil
        ui.run { try store.startFocus(kind: kind, minutes: minutes, occurrenceID: linked) }
    }

    private func reconcile() {
        let id = store.activeFocus?.id
        var reward: LedgerEntry?
        ui.run { reward = try store.reconcileFocus() }
        ui.reward(reward)
        if let id { finished = store.focusSessions.first { $0.id == id && !$0.isActive } }
    }

    private func endEarly() {
        let id = store.activeFocus?.id
        var reward: LedgerEntry?
        ui.run { reward = try store.endFocusEarly() }
        ui.reward(reward)
        if let id { finished = store.focusSessions.first { $0.id == id } }
    }

    static func clock(_ seconds: Double) -> String {
        let s = max(0, Int(seconds.rounded(.up)))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}
