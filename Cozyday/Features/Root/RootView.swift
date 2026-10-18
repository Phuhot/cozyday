import SwiftUI
import UIKit

struct RootView: View {
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(DayClock.self) private var dayClock
    @Environment(NotificationService.self) private var notifications
    @Environment(CalendarService.self) private var calendarService
    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if store.profile.onboardingCompleted {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .overlay(alignment: .top) { ErrorOverlay() }
        .overlay(alignment: .bottom) {
            if let toast = ui.toast {
                RewardToast(text: toast)
                    .padding(.bottom, 90)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .animation(Motion.quick, value: ui.toast)
        .sheet(isPresented: Binding(get: { ui.showSettings }, set: { ui.showSettings = $0 })) {
            SettingsView()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { appBecameActive() }
        }
        .onChange(of: store.changeCounter) { _, _ in
            notifications.scheduleSync(store: store)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            // Qua nửa đêm, đổi múi giờ hoặc giờ mùa hè khi app đang mở.
            dayClock.refresh()
            ui.run { try store.ensureUpcomingOccurrences() }
            notifications.scheduleSync(store: store)
        }
        .task { appBecameActive() }
    }

    private func appBecameActive() {
        dayClock.refresh()
        calendarService.refreshAccess()
        // Phiên tập trung đã hết giờ khi app ở nền/đóng → chốt đúng một lần.
        var reward: LedgerEntry?
        ui.run { reward = try store.reconcileFocus() }
        ui.reward(reward)
        ui.run { try store.ensureUpcomingOccurrences() }
        notifications.scheduleSync(store: store)
    }
}

struct MainTabView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        TabView(selection: Binding(get: { router.selectedTab }, set: { router.selectedTab = $0 })) {
            TodayView()
                .tabItem { Label("Hôm nay", systemImage: "sun.max") }
                .tag(AppTab.today)
            CornerView()
                .tabItem { Label("Góc nhỏ", systemImage: "pawprint") }
                .tag(AppTab.corner)
            JournalView()
                .tabItem { Label("Nhật ký", systemImage: "book") }
                .tag(AppTab.journal)
            StatsView()
                .tabItem { Label("Tiến bộ", systemImage: "chart.bar") }
                .tag(AppTab.progress)
        }
    }
}

/// Nút mở Cài đặt, đặt trên thanh điều hướng của mọi tab.
struct SettingsButton: View {
    @Environment(UIState.self) private var ui

    var body: some View {
        Button {
            ui.showSettings = true
        } label: {
            Image(systemName: "gearshape")
                .frame(minWidth: HitTarget.min, minHeight: HitTarget.min)
        }
        .accessibilityLabel("Cài đặt")
    }
}

/// Banner lỗi dùng chung (đặt ở gốc và trong các sheet).
struct ErrorOverlay: View {
    @Environment(UIState.self) private var ui

    var body: some View {
        if let message = ui.errorMessage {
            ErrorBanner(message: message) { ui.errorMessage = nil }
                .padding(.top, Spacing.s)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
