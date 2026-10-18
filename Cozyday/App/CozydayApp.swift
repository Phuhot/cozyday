import SwiftUI
import SwiftData

/// Mốc A: app tối giản để kiểm chứng đường build → IPA → Sideloadly → iPhone.
/// Một màn hình, một ghi chú lưu bền vững bằng SwiftData (CloudKit tắt tường minh).
@main
struct CozydayApp: App {
    private let container: ModelContainer?
    private let loadError: String?

    init() {
        do {
            container = try PathCheckStore.makeContainer()
            loadError = nil
        } catch {
            container = nil
            loadError = String(describing: error)
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                PathCheckView()
                    .modelContainer(container)
            } else {
                VStack(spacing: 12) {
                    Text("Không mở được dữ liệu")
                        .font(.headline)
                    Text(loadError ?? "")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
    }
}
