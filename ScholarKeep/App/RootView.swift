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

            StudentListView()
                .tabItem { Label("Students", systemImage: "person.2.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
