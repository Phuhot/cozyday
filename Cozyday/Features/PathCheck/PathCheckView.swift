import SwiftUI
import SwiftData

/// Ghi chú duy nhất của bản kiểm chứng. Lưu trong file riêng `PathCheck.store`
/// để bản Cozyday đầy đủ sau này không đụng vào dữ liệu thử nghiệm này.
@Model
final class PathCheckNote {
    var text: String
    var updatedAt: Date

    init(text: String, updatedAt: Date) {
        self.text = text
        self.updatedAt = updatedAt
    }
}

enum PathCheckStore {
    static func makeContainer() throws -> ModelContainer {
        let folder = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        )
        let schema = Schema([PathCheckNote.self])
        let config = ModelConfiguration(
            schema: schema,
            url: folder.appendingPathComponent("PathCheck.store"),
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}

struct PathCheckView: View {
    @Environment(\.modelContext) private var context
    @Query private var notes: [PathCheckNote]
    @State private var draft = ""
    @State private var status: String?

    private var bundleInfo: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "?"
        let build = info["CFBundleVersion"] as? String ?? "?"
        return "Phiên bản \(version) (\(build)) · \(Bundle.main.bundleIdentifier ?? "?")"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Nếu bạn thấy màn hình này trên iPhone, đường cài IPA đã chạy. Hãy viết một ghi chú, bấm Lưu, tắt hẳn app rồi mở lại để kiểm tra dữ liệu còn nguyên.")
                        .font(.callout)
                }
                Section("Ghi chú thử") {
                    TextField("Viết gì đó…", text: $draft, axis: .vertical)
                        .lineLimit(3...6)
                    Button("Lưu ghi chú") { save() }
                        .frame(minHeight: 44)
                    if let status {
                        Text(status)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                if let note = notes.first {
                    Section("Đã lưu lần cuối") {
                        Text(note.text)
                        Text(note.updatedAt.formatted(date: .abbreviated, time: .standard))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Section {
                    Text(bundleInfo)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Cozyday")
            .onAppear { draft = notes.first?.text ?? "" }
        }
    }

    private func save() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if let note = notes.first {
            note.text = trimmed
            note.updatedAt = .now
        } else {
            context.insert(PathCheckNote(text: trimmed, updatedAt: .now))
        }
        do {
            try context.save()
            status = "Đã lưu."
        } catch {
            context.rollback()
            status = "Lưu thất bại: \(error.localizedDescription)"
        }
    }
}
