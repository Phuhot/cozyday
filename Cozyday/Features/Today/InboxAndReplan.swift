import SwiftUI

/// Hộp chờ: việc chưa có ngày. Xếp lịch bằng form rõ ràng.
struct InboxView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var sheet: TodaySheet?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    let items = store.inbox
                    if items.isEmpty {
                        EmptyStateView(
                            symbol: "tray",
                            title: "Hộp chờ trống",
                            message: "Ghi nhanh những việc chưa biết làm lúc nào. Khi rảnh, chạm vào việc để xếp lịch."
                        )
                    } else {
                        ForEach(items) { task in
                            TaskRow(task: task, sheet: $sheet)
                        }
                    }
                }
                .padding(Spacing.l)
            }
            .cozyBackground()
            .navigationTitle("Hộp chờ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Đóng") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        sheet = .newTask(day: nil, startMinute: nil)
                    } label: {
                        Label("Thêm vào Hộp chờ", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $sheet) { item in
                switch item {
                case .newTask(let day, let start):
                    TaskEditorView(mode: .create(day: day, startMinute: start))
                case .edit(let id):
                    TaskEditorView(mode: .edit(id))
                case .detail(let id):
                    TaskDetailSheet(taskID: id, sheet: $sheet)
                        .presentationDetents([.medium, .large])
                case .move(let id):
                    MoveTaskSheet(taskID: id)
                        .presentationDetents([.medium, .large])
                case .focus(let id):
                    FocusView(preselectedTaskID: id)
                case .inbox, .replan:
                    EmptyView()
                }
            }
            .overlay(alignment: .top) { ErrorOverlay() }
        }
    }
}

/// Xem trước kết quả sắp xếp lại trước khi áp dụng. Có thể hủy.
struct ReplanSheet: View {
    let plan: Replanner.Plan
    let day: DayKey
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("CozyDay chỉ dời các việc chưa xong đã trễ giờ vào khoảng trống từ bây giờ tới \(TimeOfDay.label(plan.windowEnd)). Việc cố định, việc đã xong và việc sắp tới giữ nguyên; thời lượng không đổi.")
                        .font(Typography.callout)
                        .foregroundStyle(Palette.inkMuted)
                }
                if !plan.moves.isEmpty {
                    Section("Sẽ dời") {
                        ForEach(plan.moves, id: \.id) { move in
                            if let task = store.occurrence(move.id) {
                                HStack {
                                    Text(task.title).lineLimit(2)
                                    Spacer()
                                    Text("\(move.from.map(TimeOfDay.label) ?? "—") → \(TimeOfDay.label(move.to))")
                                        .monospacedDigit()
                                        .foregroundStyle(Palette.lavender)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                }
                if !plan.unplaced.isEmpty {
                    Section {
                        ForEach(plan.unplaced, id: \.self) { id in
                            if let task = store.occurrence(id) {
                                Text("\(task.title) · \(TimeOfDay.durationLabel(task.durationMinutes))")
                            }
                        }
                    } header: {
                        Text("Không đủ chỗ hôm nay")
                    } footer: {
                        Text("Những việc này giữ nguyên. Bạn có thể chuyển sang ngày mai hoặc rút ngắn thời lượng.")
                    }
                }
            }
            .navigationTitle("Sắp xếp lại")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Áp dụng") {
                        if ui.run({ try store.applyReplan(plan) }) { dismiss() }
                    }
                    .disabled(plan.moves.isEmpty)
                }
            }
        }
    }
}
