import SwiftUI
import SwiftData

@main
struct CozydayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var boot: AppBoot

    init() {
        _boot = State(initialValue: AppBoot.start())
    }

    var body: some Scene {
        WindowGroup {
            switch boot {
            case .ready(let env):
                RootView()
                    .environment(env.store)
                    .environment(env.ui)
                    .environment(env.dayClock)
                    .environment(env.notifications)
                    .environment(AppRouter.shared)
                    .tint(Palette.lavender)
            case .failed(let message):
                StorageErrorView(message: message)
            case .testHost:
                Text("Cozyday test host")
            }
        }
    }
}

struct AppEnvironment {
    let store: AppStore
    let ui: UIState
    let dayClock: DayClock
    let notifications: NotificationService
}

enum AppBoot {
    case ready(AppEnvironment)
    case failed(String)

    case testHost

    @MainActor
    static func start() -> AppBoot {
        // Khi Xcode chạy unit test, app chỉ làm "vỏ" cho test: không mở database thật, không dựng UI.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return .testHost
        }
        #if DEBUG
        if let screen = PreviewMode.current {
            do {
                return .ready(try PreviewMode.makeEnvironment(for: screen))
            } catch {
                return .failed("Không tạo được dữ liệu xem trước: \(error)")
            }
        }
        #endif
        do {
            let container = try PersistenceController.makeContainer()
            let store = try AppStore(container: container)
            return .ready(AppEnvironment(store: store, ui: UIState(), dayClock: DayClock(), notifications: NotificationService()))
        } catch {
            return .failed((error as? LocalizedError)?.errorDescription ?? String(describing: error))
        }
    }
}

/// Màn hình khi không mở được dữ liệu. Không xóa hay ghi đè database.
struct StorageErrorView: View {
    let message: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                PetArt(mood: .rest)
                    .frame(width: 120, height: 120)
                    .frame(maxWidth: .infinity)
                Text("Không mở được dữ liệu")
                    .font(Typography.title)
                Text("Cozyday không đọc được kho dữ liệu trên máy. App KHÔNG xóa hay tạo lại dữ liệu để tránh mất những gì bạn đã lưu.")
                Text("Hãy thử: tắt hẳn app rồi mở lại; kiểm tra iPhone còn dung lượng trống. Nếu vẫn lỗi, gửi nội dung bên dưới khi nhờ hỗ trợ (không chứa nội dung nhật ký).")
                    .foregroundStyle(Palette.inkMuted)
                Text(message)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
                    .padding(Spacing.m)
                    .background(Palette.surfaceMuted, in: RoundedRectangle(cornerRadius: Radius.m))
            }
            .padding(Spacing.xl)
        }
        .cozyBackground()
    }
}
