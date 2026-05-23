import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        AppLockGate {
            if settings.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingFlow()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            ExpenseListView()
                .tabItem { Label("Expenses", systemImage: "doc.text") }

            ClaimsBoardView()
                .tabItem { Label("Claims", systemImage: "tray.full") }

            PrePurchaseCheckerView()
                .tabItem { Label("Check", systemImage: "checkmark.seal") }

            MoreMenuView()
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
        }
    }
}

/// Bundles less-frequently used screens (Reports / Reference / Students / Settings).
struct MoreMenuView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink { ReportsView() } label: {
                    Label("Reports & export", systemImage: "chart.bar.doc.horizontal")
                }
                NavigationLink { ReferenceGuideView() } label: {
                    Label("Reference guide", systemImage: "book")
                }
                NavigationLink { StudentListView() } label: {
                    Label("Students", systemImage: "person.2.fill")
                }
                NavigationLink { SettingsView() } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationTitle("More")
        }
    }
}
