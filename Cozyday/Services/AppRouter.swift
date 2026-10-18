import Foundation
import Observation

enum AppTab: Hashable {
    case today
    case corner
    case journal
    case progress
}

/// Điều hướng toàn app — dùng khi bấm thông báo.
@MainActor
@Observable
final class AppRouter {
    static let shared = AppRouter()

    var selectedTab: AppTab = .today
    /// Task cần mở sau khi bấm thông báo nhắc việc.
    var pendingTaskID: UUID?
    var showFocus = false

    func handle(route: String) {
        if route == "focus" {
            selectedTab = .today
            showFocus = true
        } else if route == "journal" {
            selectedTab = .journal
        } else if route.hasPrefix("task:"), let id = UUID(uuidString: String(route.dropFirst(5))) {
            selectedTab = .today
            pendingTaskID = id
        } else {
            selectedTab = .today
        }
    }
}
