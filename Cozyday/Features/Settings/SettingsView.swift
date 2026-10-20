import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(NotificationService.self) private var notifications
    @Environment(CalendarService.self) private var calendarService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var userName = ""
    @State private var petName = ""
    @State private var activeStart = Date()
    @State private var activeEnd = Date()
    @State private var journalTime = Date()
    @State private var loaded = false

    @State private var exportFile: BackupFile?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var pendingRestore: BackupDocument?
    @State private var backupMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Hồ sơ") {
                    LabeledContent("Tên của bạn") {
                        TextField("Không bắt buộc", text: $userName)
                            .textContentType(.givenName)
                            .multilineTextAlignment(.trailing)
                            .onSubmit(saveNames)
                    }
                    LabeledContent("Tên mèo") {
                        TextField(ProfileRecord.defaultPetName, text: $petName)
                            .multilineTextAlignment(.trailing)
                            .onSubmit(saveNames)
                    }
                }

                Section {
                    DatePicker("Bắt đầu ngày", selection: $activeStart, displayedComponents: .hourAndMinute)
                    DatePicker("Kết thúc ngày", selection: $activeEnd, displayedComponents: .hourAndMinute)
                    Toggle("Rung phản hồi khi hoàn thành", isOn: Binding(
                        get: { store.profile.hapticsEnabled },
                        set: { value in ui.run { try store.updateProfile { $0.hapticsEnabled = value } } }
                    ))
                } header: {
                    Text("Ngày của bạn")
                } footer: {
                    Text("Khung giờ hoạt động dùng khi “Sắp xếp lại” các việc trễ giờ.")
                }

                notificationSection
                calendarSection
                backupSection

                Section("Thông tin") {
                    NavigationLink("Quy tắc phần thưởng") { RewardRulesView() }
                    NavigationLink("Dữ liệu & quyền riêng tư") { PrivacyView() }
                    LabeledContent("Phiên bản", value: AppStore.appVersionString)
                    LabeledContent("Bundle ID", value: Bundle.main.bundleIdentifier ?? "?")
                }
            }
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") {
                        saveAll()
                        dismiss()
                    }
                }
            }
            .overlay(alignment: .top) { ErrorOverlay() }
            .onAppear(perform: load)
            .task { await notifications.refreshPermission() }
            .fileExporter(
                isPresented: $showExporter,
                document: exportFile,
                contentType: .json,
                defaultFilename: BackupFile.suggestedName(for: store.today)
            ) { result in
                switch result {
                case .success: backupMessage = "Đã lưu file sao lưu. Hãy giữ file ở nơi an toàn (ví dụ iCloud Drive hoặc máy tính)."
                case .failure(let error): backupMessage = "Không lưu được file: \(error.localizedDescription)"
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                handleImport(result)
            }
            .sheet(item: Binding(get: { pendingRestore.map(RestorePreview.init) }, set: { if $0 == nil { pendingRestore = nil } })) { preview in
                RestoreConfirmSheet(document: preview.document) { confirmed in
                    if confirmed { performRestore(preview.document) }
                    pendingRestore = nil
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: Lịch iPhone

    private var calendarSection: some View {
        Section {
            Toggle("Hiện sự kiện từ app Lịch", isOn: Binding(
                get: { calendarService.isActive },
                set: { value in
                    if value {
                        Task { _ = await calendarService.enable() }
                    } else {
                        calendarService.isEnabled = false
                    }
                }
            ))
            if calendarService.access == .denied {
                Text("CozyDay chưa được phép đọc lịch. Bật lại trong Cài đặt iPhone → CozyDay → Lịch → Toàn quyền truy cập.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.inkMuted)
                Button("Mở Cài đặt iPhone") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
        } header: {
            Text("Lịch iPhone")
        } footer: {
            Text("Chỉ đọc để hiện cạnh việc trên timeline và để “Sắp xếp lại” tránh giờ bận. Sự kiện không được lưu vào CozyDay và không có trong bản sao lưu.")
        }
    }

    // MARK: Thông báo

    private var notificationSection: some View {
        Section {
            switch notifications.permission {
            case .authorized:
                Label("Đã cho phép thông báo", systemImage: "bell.badge")
            case .denied:
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Label("Thông báo đang tắt", systemImage: "bell.slash")
                    Text("App vẫn dùng bình thường, chỉ không có nhắc nhở.")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.inkMuted)
                }
                Button("Mở Cài đặt iPhone") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            case .notDetermined, .unknown:
                Text("CozyDay sẽ xin quyền khi bạn bật nhắc việc đầu tiên.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.inkMuted)
            }
            Toggle("Nhắc viết nhật ký mỗi ngày", isOn: Binding(
                get: { store.profile.journalReminderEnabled },
                set: { value in
                    ui.run { try store.updateProfile { $0.journalReminderEnabled = value } }
                    if value { Task { await notifications.requestPermissionIfNeeded() } }
                }
            ))
            if store.profile.journalReminderEnabled {
                DatePicker("Giờ nhắc", selection: $journalTime, displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("Thông báo")
        } footer: {
            Text("Nhắc việc được lên lịch cho 7 ngày tới và làm mới mỗi khi bạn mở app. iOS có thể trì hoãn hoặc ẩn thông báo theo chế độ Tập trung và cài đặt của bạn, nên đừng dùng nó thay chuông báo thức.")
        }
    }

    // MARK: Sao lưu

    private var backupSection: some View {
        Section {
            Button {
                exportBackup()
            } label: {
                Label("Xuất sao lưu…", systemImage: "square.and.arrow.up")
            }
            Button {
                showImporter = true
            } label: {
                Label("Khôi phục từ sao lưu…", systemImage: "arrow.counterclockwise")
            }
            if let backupMessage {
                Text(backupMessage)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.inkMuted)
            }
        } header: {
            Text("Sao lưu")
        } footer: {
            Text("File sao lưu (JSON) chứa toàn bộ dữ liệu: việc, lịch lặp, xu, sổ thưởng, đồ đạc, phiên tập trung và nhật ký. File ở dạng chữ đọc được, KHÔNG mã hóa, đừng chia sẻ công khai. Gỡ app sẽ xóa dữ liệu trên máy; gia hạn chữ ký không phải là sao lưu.")
        }
    }

    private func exportBackup() {
        do {
            let data = try BackupCodec.encode(store.makeBackup())
            exportFile = BackupFile(data: data)
            showExporter = true
        } catch {
            backupMessage = "Không tạo được file sao lưu: \(error.localizedDescription)"
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .failure(let error):
            backupMessage = "Không mở được file: \(error.localizedDescription)"
        case .success(let url):
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                if size > BackupCodec.maxBytes {
                    throw BackupError.tooLarge(bytes: size, limit: BackupCodec.maxBytes)
                }
                let data = try Data(contentsOf: url)
                pendingRestore = try BackupCodec.decodeAndValidate(data)
                backupMessage = nil
            } catch let error as BackupError {
                backupMessage = "Không khôi phục: \(error.message) Dữ liệu hiện tại không bị thay đổi."
            } catch {
                backupMessage = "Không đọc được file: \(error.localizedDescription). Dữ liệu hiện tại không bị thay đổi."
            }
        }
    }

    private func performRestore(_ document: BackupDocument) {
        if ui.run({ try store.restore(document) }) {
            backupMessage = "Đã khôi phục dữ liệu từ bản sao lưu ngày \(DateText.dateTime(document.exportedAt, calendar: store.calendar))."
            loaded = false
            load()
        } else {
            backupMessage = "Khôi phục thất bại. Dữ liệu cũ vẫn được giữ nguyên."
        }
    }

    // MARK: Hồ sơ

    private func load() {
        guard !loaded else { return }
        loaded = true
        userName = store.profile.userName
        petName = store.profile.petName
        let today = store.today
        activeStart = today.date(atMinute: store.profile.activeStartMinute, in: store.calendar)
        activeEnd = today.date(atMinute: min(store.profile.activeEndMinute, 24 * 60 - 1), in: store.calendar)
        journalTime = today.date(atMinute: store.profile.journalReminderMinute, in: store.calendar)
    }

    private func saveNames() {
        let user = String(userName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
        let pet = String(petName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(30))
        guard user != store.profile.userName || (pet != store.profile.petName && !pet.isEmpty) else { return }
        ui.run {
            try store.updateProfile {
                $0.userName = user
                if !pet.isEmpty { $0.petName = pet }
            }
        }
    }

    private func saveAll() {
        saveNames()
        let start = store.calendar.minuteOfDay(activeStart)
        let end = store.calendar.minuteOfDay(activeEnd)
        let journal = store.calendar.minuteOfDay(journalTime)
        let p = store.profile
        guard start != p.activeStartMinute || end != p.activeEndMinute || journal != p.journalReminderMinute else { return }
        ui.run {
            try store.updateProfile {
                $0.activeStartMinute = start
                $0.activeEndMinute = end
                $0.journalReminderMinute = journal
            }
        }
    }
}

struct RestorePreview: Identifiable {
    let document: BackupDocument
    var id: Date { document.exportedAt }
}

struct RestoreConfirmSheet: View {
    let document: BackupDocument
    let onFinish: (Bool) -> Void
    @Environment(AppStore.self) private var store

    var body: some View {
        let c = document.counts
        NavigationStack {
            List {
                Section {
                    Text("Khôi phục sẽ THAY THẾ toàn bộ dữ liệu hiện có bằng nội dung file này. Nên xuất một bản sao lưu của dữ liệu hiện tại trước.")
                        .foregroundStyle(Palette.danger)
                }
                Section("Nội dung file") {
                    LabeledContent("Xuất lúc", value: DateText.dateTime(document.exportedAt, calendar: store.calendar))
                    LabeledContent("Phiên bản app", value: document.appVersion)
                    LabeledContent("Việc", value: "\(c.occurrences)")
                    LabeledContent("Mẫu lặp", value: "\(c.templates)")
                    LabeledContent("Dòng sổ thưởng", value: "\(c.ledger)")
                    LabeledContent("Xu / XP", value: "\(c.coins) / \(c.xp)")
                    LabeledContent("Đồ đã có", value: "\(c.ownedItems)")
                    LabeledContent("Phiên tập trung", value: "\(c.focusSessions)")
                    LabeledContent("Nhật ký", value: "\(c.journal)")
                    LabeledContent("Đồ ăn trong khay", value: document.foodStock == nil ? "chưa có (bản sao lưu cũ)" : "\(c.food)")
                    LabeledContent("Lượt Sân chơi", value: "\(c.minigames)")
                }
                Section("Dữ liệu hiện tại") {
                    LabeledContent("Việc", value: "\(store.occurrences.filter { !$0.isRemoved }.count)")
                    LabeledContent("Xu / XP", value: "\(store.wallet.coins) / \(store.wallet.xp)")
                    LabeledContent("Nhật ký", value: "\(store.journal.count)")
                }
            }
            .navigationTitle("Xác nhận khôi phục")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Hủy") { onFinish(false) } }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Thay thế", role: .destructive) { onFinish(true) }
                }
            }
        }
    }
}

struct RewardRulesView: View {
    var body: some View {
        List {
            Section {
                ForEach(RewardConfig.rulesText, id: \.self) { Text($0) }
            } footer: {
                Text("Mỗi phần thưởng gắn với đúng một việc / phiên / ngày trong sổ cái, nên bấm nhanh hay mở lại app không nhận trùng.")
            }
            Section("Chăm thú cưng") {
                ForEach(CareConfig.rulesText, id: \.self) { Text($0) }
            }
            Section {
                ForEach(MinigameConfig.rulesText, id: \.self) { Text($0) }
            } header: {
                Text("Sân chơi")
            } footer: {
                Text("App chạy offline: đổi ngày giờ của máy sẽ làm hạn mức theo ngày đổi theo. CozyDay không chống được điều đó tuyệt đối.")
            }
        }
        .navigationTitle("Quy tắc phần thưởng")
    }
}

struct PrivacyView: View {
    var body: some View {
        List {
            Text("Mọi dữ liệu chỉ nằm trên iPhone này (SwiftData, không đồng bộ iCloud). CozyDay không có tài khoản, máy chủ, quảng cáo hay analytics.")
            Text("Thông báo là thông báo cục bộ do iPhone tự hiển thị, không gửi qua Internet.")
            Text("Gỡ app hoặc cài lại với bundle ID khác có thể làm mất dữ liệu. Hãy xuất sao lưu định kỳ và trước mỗi lần cập nhật.")
            Text("File sao lưu không mã hóa: ai mở được file sẽ đọc được tên việc và nhật ký.")
        }
        .navigationTitle("Dữ liệu & quyền riêng tư")
    }
}
