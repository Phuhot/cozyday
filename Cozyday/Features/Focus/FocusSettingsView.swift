import SwiftUI

/// Cài đặt hẹn giờ Pomodoro: thời lượng, vòng nghỉ dài, tự chạy tiếp, giữ tập trung, âm thanh.
struct FocusSettingsView: View {
    @Environment(FocusCoordinator.self) private var focus
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var focus = focus
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $focus.settings.focusMinutes, in: PomodoroSettings.focusRange, step: 5) {
                        LabeledContent("Tập trung", value: "\(focus.settings.focusMinutes) phút")
                    }
                    Stepper(value: $focus.settings.shortBreakMinutes, in: PomodoroSettings.shortBreakRange) {
                        LabeledContent("Nghỉ ngắn", value: "\(focus.settings.shortBreakMinutes) phút")
                    }
                    Stepper(value: $focus.settings.longBreakMinutes, in: PomodoroSettings.longBreakRange, step: 5) {
                        LabeledContent("Nghỉ dài", value: "\(focus.settings.longBreakMinutes) phút")
                    }
                    Stepper(value: $focus.settings.roundsBeforeLongBreak, in: PomodoroSettings.roundsRange) {
                        LabeledContent("Nghỉ dài sau", value: "\(focus.settings.roundsBeforeLongBreak) phiên")
                    }
                    Stepper(value: $focus.settings.dailyGoal, in: PomodoroSettings.goalRange) {
                        LabeledContent("Mục tiêu mỗi ngày", value: "\(focus.settings.dailyGoal) phiên")
                    }
                } header: {
                    Text("Nhịp Pomodoro")
                } footer: {
                    HStack(spacing: Spacing.s) {
                        ForEach(Self.presets, id: \.label) { p in
                            Button(p.label) {
                                focus.settings.focusMinutes = p.focus
                                focus.settings.shortBreakMinutes = p.short
                                focus.settings.longBreakMinutes = p.long
                            }
                            .buttonStyle(.bordered)
                            .tint(Palette.lavender)
                        }
                    }
                    .padding(.top, Spacing.xs)
                }

                Section {
                    Toggle("Tự bắt đầu giờ nghỉ", isOn: $focus.settings.autoStartBreak)
                    Toggle("Tự bắt đầu phiên tập trung kế tiếp", isOn: $focus.settings.autoStartFocus)
                } header: {
                    Text("Tự chạy tiếp")
                } footer: {
                    Text("Chỉ tự chạy khi phiên vừa hết giờ lúc bạn đang mở app. Mở app sau khi hết giờ đã lâu thì CozyDay chờ bạn bấm.")
                }

                Section {
                    Toggle("Chế độ nghiêm", isOn: $focus.settings.strictMode)
                    Toggle("Nhắc khi rời app", isOn: $focus.settings.nudgeWhenLeaving)
                        .disabled(focus.settings.strictMode)
                    Toggle("Giữ màn hình sáng", isOn: $focus.settings.keepScreenOn)
                } header: {
                    Text("Giữ tập trung")
                } footer: {
                    Text("""
                    Chế độ nghiêm: không có nút tạm dừng, muốn dừng sớm phải giữ nút 3 giây, chuyển sang app khác quá 1 phút thì phiên dừng và không có thưởng.
                    Khóa máy không bị tính là rời app nếu iPhone có đặt mật mã (iOS chỉ báo lúc khóa máy khi có mật mã).
                    Nhắc khi rời app: sau 15 giây ở app khác, \(focusPetName) gửi một thông báo nhắc quay lại (cần bật thông báo).
                    CozyDay không chặn được app khác. Muốn tắt thông báo của app khác, bật chế độ Tập trung của iPhone trong Trung tâm điều khiển.
                    """)
                }

                Section("Âm thanh") {
                    Toggle("Chuông khi hết giờ", isOn: $focus.settings.endChime)
                    Picker("Âm nền", selection: $focus.settings.ambient) {
                        ForEach(FocusAmbient.allCases) { a in
                            Label(a.label, systemImage: a.symbol).tag(a)
                        }
                    }
                    if focus.settings.ambient != .off {
                        HStack {
                            Image(systemName: "speaker.fill").foregroundStyle(Palette.inkMuted)
                            Slider(value: $focus.settings.ambientVolume, in: 0...1)
                                .accessibilityLabel("Âm lượng âm nền")
                            Image(systemName: "speaker.wave.3.fill").foregroundStyle(Palette.inkMuted)
                        }
                        Button {
                            focus.preview(focus.settings.ambient)
                        } label: {
                            Label("Nghe thử", systemImage: "play.circle")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .cozyBackground()
            .navigationTitle("Cài đặt hẹn giờ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Xong") { dismiss() } } }
            .onDisappear { focus.endPreview() }
        }
    }

    private var focusPetName: String { store.profile.displayPetName }

    private static let presets: [(label: String, focus: Int, short: Int, long: Int)] = [
        ("25/5", 25, 5, 15), ("50/10", 50, 10, 20), ("90/15", 90, 15, 30)
    ]
}
