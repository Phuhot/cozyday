import SwiftUI

/// Hẹn giờ Pomodoro. Nguồn sự thật là phiên đã lưu (mốc thời gian); đồng hồ trên màn hình chỉ để vẽ.
/// Đóng app / khóa máy vẫn tính đúng khi mở lại. Dùng làm tab "Tập trung" và làm sheet khi mở từ một việc.
struct FocusView: View {
    var preselectedTaskID: UUID?
    /// Mở dạng sheet (từ một việc) thì có nút Đóng; dạng tab thì không.
    var isSheet = true

    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(FocusCoordinator.self) private var focus
    @Environment(NotificationService.self) private var notifications
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Loại phiên sẽ bắt đầu khi bấm nút (khi chưa có phiên chạy).
    @State private var mode: StartMode = .focus
    @State private var showSettings = false
    @State private var showFullScreen = false
    @State private var showThought = false
    @State private var thought = ""
    @State private var confirmEnd = false
    @State private var loaded = false

    enum StartMode: Hashable { case focus, shortBreak, longBreak }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    if let notice = focus.awayNotice {
                        noticeBanner(notice)
                    }
                    if let session = store.activeFocus {
                        running(session)
                    } else if let finished = focus.lastFinished {
                        finishedView(finished)
                    } else {
                        setup
                    }
                    dayCard
                    ambientCard
                    policyNote
                }
                .padding(Spacing.l)
                .padding(.bottom, Spacing.xl)
            }
            .cozyBackground()
            .navigationTitle("Tập trung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .frame(minWidth: HitTarget.min, minHeight: HitTarget.min)
                    }
                    .accessibilityLabel("Cài đặt hẹn giờ")
                }
                if isSheet {
                    ToolbarItem(placement: .confirmationAction) { Button("Đóng") { dismiss() } }
                } else {
                    ToolbarItem(placement: .topBarTrailing) { SettingsButton() }
                }
            }
            .overlay(alignment: .top) { ErrorOverlay() }
            .sheet(isPresented: $showSettings) { FocusSettingsView() }
            .fullScreenCover(isPresented: $showFullScreen) { FocusFullScreenView() }
            .alert("Ghi nhanh ý nghĩ chen ngang", isPresented: $showThought) {
                TextField("Ví dụ: gọi lại cho mẹ", text: $thought)
                Button("Lưu vào Hộp chờ") {
                    if focus.captureThought(thought) { ui.showReward("Đã cất vào Hộp chờ. Xong phiên rồi xử lý nhé.") }
                    thought = ""
                }
                Button("Hủy", role: .cancel) { thought = "" }
            } message: {
                Text("Ghi lại rồi quay về việc đang làm. Ý nghĩ này nằm trong Hộp chờ ở tab Hôm nay.")
            }
            .confirmationDialog("Kết thúc phiên này?", isPresented: $confirmEnd, titleVisibility: .visible) {
                Button("Kết thúc sớm", role: .destructive) { focus.endEarly() }
                Button("Tiếp tục tập trung", role: .cancel) {}
            } message: {
                Text("Kết thúc sớm không có thưởng. Số phút đã tập trung vẫn được ghi lại.")
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                if let preselectedTaskID { focus.selectedTaskID = preselectedTaskID }
                #if DEBUG
                if PreviewMode.current == .focusSettings { showSettings = true }
                if PreviewMode.current == .focusFull { showFullScreen = true }
                #endif
            }
        }
    }

    // MARK: Hôm nay

    private var dayCard: some View {
        let day = focus.day
        let rounds = focus.settings.roundsBeforeLongBreak
        return CozyCard(padding: Spacing.m) {
            HStack(alignment: .center, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Hôm nay")
                        .font(Typography.caption.weight(.semibold))
                        .foregroundStyle(Palette.inkMuted)
                    Text("\(day.completedFocus)/\(day.goal) phiên · \(day.focusedMinutes) phút")
                        .font(Typography.headline.monospacedDigit())
                        .foregroundStyle(Palette.ink)
                    if day.goalReached {
                        Text("Đủ mục tiêu hôm nay")
                            .font(Typography.caption.weight(.semibold))
                            .foregroundStyle(Palette.sage)
                    }
                }
                Spacer(minLength: Spacing.s)
                // Mỗi chấm là một phiên trong vòng; đủ vòng thì tới giờ nghỉ dài.
                HStack(spacing: 6) {
                    ForEach(0..<rounds, id: \.self) { i in
                        Image(systemName: i < day.roundInCycle ? "circle.fill" : "circle")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(i < day.roundInCycle ? Palette.peach : Palette.line)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Đã xong \(day.roundInCycle) trên \(rounds) phiên trước giờ nghỉ dài")
            }
        }
    }

    private func noticeBanner(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            Image(systemName: "eye.trianglebadge.exclamationmark")
                .foregroundStyle(Palette.peach)
            Text(text)
                .font(Typography.callout)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button {
                focus.awayNotice = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .frame(minWidth: HitTarget.min, minHeight: HitTarget.min)
            }
            .accessibilityLabel("Ẩn thông báo")
        }
        .padding(.leading, Spacing.m)
        .background(Palette.peach.opacity(0.14), in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
    }

    // MARK: Chưa chạy

    private var startMinutes: Int {
        switch mode {
        case .focus: return focus.settings.focusMinutes
        case .shortBreak: return focus.settings.shortBreakMinutes
        case .longBreak: return focus.settings.longBreakMinutes
        }
    }

    private var setup: some View {
        let todaysOpen = store.tasks(on: store.today).filter { $0.status == .open }
        return VStack(spacing: Spacing.l) {
            Picker("Loại phiên", selection: $mode) {
                Text("Tập trung").tag(StartMode.focus)
                Text("Nghỉ ngắn").tag(StartMode.shortBreak)
                Text("Nghỉ dài").tag(StartMode.longBreak)
            }
            .pickerStyle(.segmented)

            ZStack {
                TimerRing(progress: 0, tint: mode == .focus ? Palette.lavender : Palette.sage)
                VStack(spacing: Spacing.xs) {
                    PetView(appearance: store.petAppearance, mood: mode == .focus ? .focus : .rest, name: store.profile.displayPetName)
                        .frame(width: 92, height: 92)
                    Text(FocusView.clock(Double(startMinutes * 60)))
                        .font(.system(size: 52, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Palette.ink)
                        .minimumScaleFactor(0.6)
                    Text(mode == .focus ? "Sẵn sàng" : "Giờ nghỉ")
                        .font(Typography.callout)
                        .foregroundStyle(Palette.inkMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(Spacing.xl)
            }
            .frame(width: 290, height: 290)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(startMinutes) phút \(mode == .focus ? "tập trung" : "nghỉ")")

            if mode == .focus {
                Picker("Gắn với việc", selection: Binding(get: { focus.selectedTaskID }, set: { focus.selectedTaskID = $0 })) {
                    Text("Không gắn việc").tag(UUID?.none)
                    ForEach(todaysOpen) { t in
                        Text(t.title).tag(UUID?.some(t.id))
                    }
                    if let id = focus.selectedTaskID, !todaysOpen.contains(where: { $0.id == id }), let t = store.occurrence(id) {
                        Text(t.title).tag(UUID?.some(id))
                    }
                }
                .pickerStyle(.menu)
                .tint(Palette.ink)
            }

            Button {
                focus.start(kind: mode == .focus ? .focus : .rest, minutes: startMinutes)
                requestNotificationsIfNeeded()
            } label: {
                Label("Bắt đầu \(startMinutes) phút", systemImage: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle(color: mode == .focus ? Palette.lavender : Palette.sage))

            Text("Nhịp \(focus.settings.focusMinutes)/\(focus.settings.shortBreakMinutes) phút, nghỉ dài \(focus.settings.longBreakMinutes) phút sau \(focus.settings.roundsBeforeLongBreak) phiên\(focus.settings.strictMode ? " · chế độ nghiêm" : "")")
                .font(Typography.caption)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: Đang chạy

    private func running(_ session: FocusSessionRecord) -> some View {
        // Phiên đang tạm dừng (từ trước khi bật chế độ nghiêm) vẫn có nút Tiếp tục.
        let strictFocus = focus.settings.strictMode && session.kind == .focus && !session.isPaused
        return VStack(spacing: Spacing.l) {
            if session.kind == .rest, let done = focus.lastFinished {
                recap(done)
            }
            if let id = session.occurrenceID, let task = store.occurrence(id) {
                Label(task.title, systemImage: "checklist")
                    .font(Typography.headline)
                    .foregroundStyle(Palette.inkMuted)
                    .lineLimit(2)
            }
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let remaining = session.remaining(at: context.date)
                let progress = 1 - remaining / Double(max(1, session.plannedSeconds))
                ZStack {
                    TimerRing(progress: progress, tint: session.kind == .focus ? Palette.lavender : Palette.sage)
                    VStack(spacing: Spacing.xs) {
                        PetView(appearance: store.petAppearance, mood: session.kind == .focus ? .focus : .rest,
                                name: store.profile.displayPetName)
                            .frame(width: 92, height: 92)
                        Text(Self.clock(remaining))
                            .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(Palette.ink)
                            .minimumScaleFactor(0.6)
                            .contentTransition(.numericText(countsDown: true))
                        Text(session.isPaused ? "Đang tạm dừng" : statusLabel(session))
                            .font(Typography.callout)
                            .foregroundStyle(Palette.inkMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .padding(Spacing.xl)
                }
                .frame(width: 290, height: 290)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(statusLabel(session)), còn \(Int(remaining / 60)) phút \(Int(remaining) % 60) giây\(session.isPaused ? ", đang tạm dừng" : "")")
            }

            controls(session, strict: strictFocus)

            HStack(spacing: Spacing.m) {
                if session.kind == .focus {
                    Button {
                        showThought = true
                    } label: {
                        Label("Ghi nhanh", systemImage: "square.and.pencil")
                    }
                    .buttonStyle(SoftButtonStyle())
                }
                Button {
                    showFullScreen = true
                } label: {
                    Label("Toàn màn hình", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(SoftButtonStyle())
            }

            Text(strictFocus
                 ? "Chế độ nghiêm: không tạm dừng được. Khóa máy thì không sao, nhưng chuyển sang app khác quá 1 phút thì phiên dừng và không có thưởng."
                 : "Bạn có thể khóa máy. Nếu đã bật thông báo, CozyDay sẽ báo khi hết giờ.")
                .font(Typography.caption)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
        }
    }

    private func statusLabel(_ session: FocusSessionRecord) -> String {
        guard session.kind == .rest else {
            let round = focus.day.roundInCycle + 1
            return "Tập trung · phiên \(round)/\(focus.settings.roundsBeforeLongBreak)"
        }
        return session.plannedMinutes >= focus.settings.longBreakMinutes && focus.settings.longBreakMinutes > focus.settings.shortBreakMinutes
            ? "Nghỉ dài" : "Nghỉ ngắn"
    }

    @ViewBuilder
    private func controls(_ session: FocusSessionRecord, strict: Bool) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.m)) : AnyLayout(HStackLayout(spacing: Spacing.m))
        layout {
            if session.kind == .rest {
                Button {
                    focus.skipBreak()
                } label: { Label("Bỏ qua giờ nghỉ", systemImage: "forward.fill") }
                .buttonStyle(PrimaryButtonStyle(color: Palette.sage))
            } else if !strict {
                if session.isPaused {
                    Button {
                        focus.resume()
                    } label: { Label("Tiếp tục", systemImage: "play.fill") }
                    .buttonStyle(PrimaryButtonStyle())
                } else {
                    Button {
                        focus.pause()
                    } label: { Label("Tạm dừng", systemImage: "pause.fill") }
                    .buttonStyle(PrimaryButtonStyle(color: Palette.inkMuted))
                }
            }
            if strict {
                HoldToEndButton { focus.endEarly() }
            } else {
                Button {
                    if session.kind == .rest { focus.endEarly() } else { confirmEnd = true }
                } label: { Label("Kết thúc", systemImage: "stop.fill") }
                .buttonStyle(SoftButtonStyle(tint: Palette.danger))
            }
        }
    }

    /// Tổng kết gọn phiên vừa xong, hiện trong lúc giờ nghỉ tự chạy.
    private func recap(_ done: FocusSessionRecord) -> some View {
        let away = focus.awayCount(for: done.id)
        return CozyCard(padding: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Label("Xong phiên \(Int(done.focusedSeconds / 60)) phút", systemImage: "checkmark.seal.fill")
                    .font(Typography.headline)
                    .foregroundStyle(Palette.sage)
                Text(away == 0 ? "Không rời app lần nào." : "Rời app \(away) lần trong phiên.")
                    .font(Typography.callout)
                    .foregroundStyle(Palette.inkMuted)
                if let id = done.occurrenceID, let task = store.occurrence(id), task.status == .open {
                    Button {
                        var reward: LedgerEntry?
                        ui.run { reward = try store.setStatus(id: id, to: .done) }
                        ui.reward(reward)
                    } label: { Label("Đánh dấu “\(task.title)” đã xong", systemImage: "checkmark") }
                    .buttonStyle(SoftButtonStyle(tint: Palette.sage))
                }
            }
        }
    }

    // MARK: Kết thúc

    private func finishedView(_ session: FocusSessionRecord) -> some View {
        let next = focus.suggestedNext(after: .focus)
        let away = focus.awayCount(for: session.id)
        return VStack(spacing: Spacing.l) {
            PetView(appearance: store.petAppearance, mood: session.status == .completed ? .happy : .idle,
                    name: store.profile.displayPetName, bounceTrigger: session.status == .completed ? 1 : 0)
                .frame(width: 130, height: 130)
            Text(session.status == .completed ? "Xong một phiên!" : "Đã kết thúc sớm")
                .font(Typography.title)
            VStack(spacing: Spacing.xs) {
                Text("Bạn đã tập trung \(Int(session.focusedSeconds / 60)) phút.")
                Text(away == 0 ? "Không rời app lần nào." : "Rời app \(away) lần trong phiên.")
            }
            .font(Typography.callout)
            .foregroundStyle(Palette.inkMuted)

            Button {
                focus.start(kind: .rest, minutes: next.minutes)
            } label: {
                Label("\(next.isLongBreak ? "Nghỉ dài" : "Nghỉ") \(next.minutes) phút", systemImage: "cup.and.saucer")
            }
            .buttonStyle(PrimaryButtonStyle(color: Palette.sage))

            Button {
                focus.startNextFocus()
            } label: {
                Label("Tập trung tiếp \(focus.settings.focusMinutes) phút", systemImage: "play.fill")
            }
            .buttonStyle(SoftButtonStyle())

            if let id = session.occurrenceID, let task = store.occurrence(id), task.status == .open {
                Button {
                    var reward: LedgerEntry?
                    ui.run { reward = try store.setStatus(id: id, to: .done) }
                    ui.reward(reward)
                } label: { Label("Đánh dấu “\(task.title)” đã xong", systemImage: "checkmark") }
                .buttonStyle(SoftButtonStyle(tint: Palette.sage))
            }
            Button("Về màn hẹn giờ") { focus.lastFinished = nil }
                .font(Typography.callout)
                .foregroundStyle(Palette.inkMuted)
        }
    }

    // MARK: Âm nền

    private var ambientCard: some View {
        CozyCard(padding: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Âm nền khi tập trung")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(Palette.inkMuted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.s) {
                        ForEach(FocusAmbient.allCases) { a in
                            Button {
                                focus.settings.ambient = a
                            } label: {
                                Label(a.label, systemImage: a.symbol)
                                    .font(Typography.callout.weight(.medium))
                                    .padding(.horizontal, Spacing.m)
                                    .frame(minHeight: HitTarget.min)
                                    .foregroundStyle(focus.settings.ambient == a ? Palette.onAccent : Palette.ink)
                                    .background(focus.settings.ambient == a ? Palette.lavender : Palette.surfaceMuted, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(focus.settings.ambient == a ? .isSelected : [])
                        }
                    }
                }
                Text("Chỉ phát trong lúc tập trung, kể cả khi khóa máy. Không ngắt nhạc bạn đang nghe.")
                    .font(Typography.caption2)
                    .foregroundStyle(Palette.inkMuted)
            }
        }
    }

    private var policyNote: some View {
        let minutes = focus.settings.focusMinutes
        let reward = RewardConfig.focusReward(plannedMinutes: minutes)
        return Text(reward.xp > 0
                    ? "Phiên \(minutes) phút chạy hết giờ: +\(reward.xp) XP, +\(reward.coins) xu. Tạm dừng không tính vào phút tập trung, kết thúc sớm không có thưởng. CozyDay không chặn được app khác (iOS không cho app thường làm vậy)."
                    : "Phiên dưới \(RewardConfig.focusMinMinutesForReward) phút không có thưởng.")
            .font(Typography.caption)
            .foregroundStyle(Palette.inkMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func requestNotificationsIfNeeded() {
        Task {
            if notifications.permission == .notDetermined || notifications.permission == .unknown {
                await notifications.requestPermissionIfNeeded()
            }
            notifications.syncFocus(store: store)
        }
    }

    static func clock(_ seconds: Double) -> String {
        let s = max(0, Int(seconds.rounded(.up)))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}

/// Vòng tiến độ dày, có vạch phút nhạt phía sau.
struct TimerRing: View {
    var progress: Double
    var tint: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().fill(Palette.surface)
                .shadow(color: Palette.shadow.opacity(0.12), radius: 18, y: 8)
            Circle().stroke(tint.opacity(0.14), lineWidth: 18)
                .padding(9)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(9)
                .animation(reduceMotion ? nil : .linear(duration: 0.9), value: progress)
        }
    }
}

/// Chế độ nghiêm: phải giữ nút 3 giây mới kết thúc được, tránh bấm bỏ theo phản xạ.
struct HoldToEndButton: View {
    let action: () -> Void
    @State private var holding = false
    @State private var fill: CGFloat = 0

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                .fill(Palette.danger.opacity(0.14))
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                    .fill(Palette.danger.opacity(0.35))
                    .frame(width: geo.size.width * fill)
            }
            Label(holding ? "Giữ tiếp…" : "Giữ 3 giây để dừng", systemImage: "hand.raised.fill")
                .font(Typography.headline)
                .foregroundStyle(Palette.danger)
                .frame(maxWidth: .infinity)
        }
        .frame(minHeight: HitTarget.min + 6)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
        .onLongPressGesture(minimumDuration: 3, maximumDistance: 40) {
            fill = 0
            holding = false
            action()
        } onPressingChanged: { pressing in
            holding = pressing
            withAnimation(pressing ? .linear(duration: 3) : .easeOut(duration: 0.2)) { fill = pressing ? 1 : 0 }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dừng phiên sớm")
        .accessibilityHint("Chế độ nghiêm: giữ 3 giây. Dừng sớm không có thưởng.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { action() }
    }
}

/// Toàn màn hình, nền tối dịu: chỉ còn đồng hồ, thú cưng và một nút thoát. Màn hình được giữ sáng nếu bạn bật.
struct FocusFullScreenView: View {
    @Environment(AppStore.self) private var store
    @Environment(FocusCoordinator.self) private var focus
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.10, blue: 0.16).ignoresSafeArea()
            if let session = store.activeFocus {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let remaining = session.remaining(at: context.date)
                    let progress = 1 - remaining / Double(max(1, session.plannedSeconds))
                    VStack(spacing: Spacing.xl) {
                        Spacer()
                        PetView(appearance: store.petAppearance, mood: session.kind == .focus ? .focus : .rest,
                                name: store.profile.displayPetName)
                            .frame(width: 130, height: 130)
                        Text(FocusView.clock(remaining))
                            .font(.system(size: 88, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(.white.opacity(0.92))
                            .minimumScaleFactor(0.5)
                        ProgressView(value: progress)
                            .tint(session.kind == .focus ? Color(red: 0.72, green: 0.65, blue: 0.94) : Color(red: 0.61, green: 0.76, blue: 0.62))
                            .frame(maxWidth: 240)
                        Text(session.isPaused ? "Đang tạm dừng" : (session.kind == .focus ? "Đang tập trung" : "Đang nghỉ"))
                            .font(Typography.callout)
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Còn \(Int(remaining / 60)) phút \(Int(remaining) % 60) giây")
                }
            } else {
                VStack(spacing: Spacing.l) {
                    PetView(appearance: store.petAppearance, mood: .happy, name: store.profile.displayPetName)
                        .frame(width: 130, height: 130)
                    Text("Hết phiên rồi")
                        .font(Typography.title)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 56, height: 56)
            }
            .accessibilityLabel("Thu nhỏ")
            .padding(Spacing.m)
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }
}

/// Đồng hồ nhỏ nổi phía trên thanh tab khi đang có phiên và bạn ở tab khác. Chạm để quay lại.
struct FocusMiniBar: View {
    let session: FocusSessionRecord
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let remaining = session.remaining(at: context.date)
                let progress = 1 - remaining / Double(max(1, session.plannedSeconds))
                let tint = session.kind == .focus ? Palette.lavender : Palette.sage
                HStack(spacing: Spacing.s) {
                    ZStack {
                        Circle().stroke(tint.opacity(0.2), lineWidth: 4)
                        Circle().trim(from: 0, to: max(0.001, progress))
                            .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Image(systemName: session.kind == .focus ? "brain.head.profile" : "cup.and.saucer.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(tint)
                    }
                    .frame(width: 26, height: 26)
                    Text(session.isPaused ? "Tạm dừng" : FocusView.clock(remaining))
                        .font(Typography.headline.monospacedDigit())
                        .foregroundStyle(Palette.ink)
                }
                .padding(.leading, Spacing.s)
                .padding(.trailing, Spacing.m)
                .frame(minHeight: HitTarget.min)
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 1))
                .shadow(color: Palette.shadow.opacity(0.18), radius: 10, y: 4)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(session.kind == .focus ? "Đang tập trung" : "Đang nghỉ"), còn \(Int(remaining / 60)) phút. Chạm để mở hẹn giờ")
            }
        }
        .buttonStyle(.plain)
    }
}
