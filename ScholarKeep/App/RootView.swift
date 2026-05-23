import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppSettings.self) private var settings

    private var bypassAuth: Bool {
        CommandLine.arguments.contains("--reset") ||
        CommandLine.arguments.contains("--skip-auth")
    }

    var body: some View {
        Group {
            if bypassAuth {
                gatedContent
            } else {
                SignInGate { gatedContent }
            }
        }
    }

    @ViewBuilder
    private var gatedContent: some View {
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
    private var isDevTools: Bool {
        CommandLine.arguments.contains("--devtools")
    }

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

            if isDevTools {
                DevOCRTesterView()
                    .tabItem { Label("DevOCR", systemImage: "wrench.and.screwdriver") }
            }
        }
    }
}

/// Bundles less-frequently used screens (Reports / Reference / Students / Settings).
struct MoreMenuView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink { BalanceLedgerView() } label: {
                    Label("Balance", systemImage: "dollarsign.circle")
                }
                NavigationLink { ProviderListView() } label: {
                    Label("Providers", systemImage: "person.text.rectangle")
                }
                NavigationLink { PreAuthListView() } label: {
                    Label("Pre-authorizations", systemImage: "checkmark.shield")
                }
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
