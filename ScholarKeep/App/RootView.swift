import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppSettings.self) private var settings

    private var bypassAuth: Bool {
        CommandLine.arguments.contains("--reset") ||
        CommandLine.arguments.contains("--skip-auth") ||
        CommandLine.arguments.contains("--screenshot")
    }

    private var showPaywallOnLaunch: Bool {
        CommandLine.arguments.contains("--showpaywall")
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
            if showPaywallOnLaunch {
                PaywallView()
            } else if settings.hasCompletedOnboarding {
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
        // v0.5.0: 4 clean tabs (no FAB — Jony Ive principle).
        // Expenses list moves under More; primary scan action is Home's top-right "+".
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            PrePurchaseCheckerView()
                .tabItem { Label("Check", systemImage: "bubble.left.and.bubble.right.fill") }

            ClaimsBoardView()
                .tabItem { Label("Claims", systemImage: "tray.full.fill") }

            MoreMenuView()
                .tabItem { Label("More", systemImage: "ellipsis.circle") }

            if isDevTools {
                DevOCRTesterView()
                    .tabItem { Label("DevOCR", systemImage: "wrench.and.screwdriver") }
            }
        }
    }
}

/// v0.5.0: Real hub — 2×2 tile grid for primary destinations + reference list.
struct MoreMenuView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.lg) {
                    StudentStripView()
                    primaryGrid
                    secondarySection
                    referenceSection
                    versionFooter
                }
                .padding(.bottom, DS.xxl)
            }
            .background(DS.canvas.ignoresSafeArea())
            .navigationTitle("More")
        }
    }

    private var primaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: DS.sm),
                            GridItem(.flexible(), spacing: DS.sm)],
                  spacing: DS.sm) {
            NavigationLink { StudentListView() } label: {
                moreTile(title: "Students", subtitle: "Profiles & details", symbol: "person.2.fill")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("moreTileStudents")
            NavigationLink { RecurringTaskListView() } label: {
                moreTile(title: "Recurring", subtitle: "Reviews & reminders", symbol: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("moreTileRecurring")
            NavigationLink { ReportsView() } label: {
                moreTile(title: "Reports", subtitle: "Export & summaries", symbol: "chart.bar.doc.horizontal")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("moreTileReports")
            NavigationLink { SettingsView() } label: {
                moreTile(title: "Settings", subtitle: "Privacy, backup, Pro", symbol: "gearshape.fill")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("moreTileSettings")
        }
        .padding(.horizontal, DS.base)
    }

    private var secondarySection: some View {
        VStack(alignment: .leading, spacing: DS.sm) {
            sectionHeader("Records")
            VStack(spacing: 0) {
                NavigationLink { ExpenseListView() } label: {
                    moreRow(title: "All receipts", symbol: "doc.text.fill")
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 56)
                NavigationLink { BalanceLedgerView() } label: {
                    moreRow(title: "Balance ledger", symbol: "dollarsign.circle.fill")
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 56)
                NavigationLink { ProviderListView() } label: {
                    moreRow(title: "Providers", symbol: "person.text.rectangle.fill")
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 56)
                NavigationLink { PreAuthListView() } label: {
                    moreRow(title: "Pre-authorizations", symbol: "checkmark.shield.fill")
                }
                .buttonStyle(.plain)
            }
            .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
            .padding(.horizontal, DS.base)
        }
    }

    private var referenceSection: some View {
        VStack(alignment: .leading, spacing: DS.sm) {
            sectionHeader("Reference")
            VStack(spacing: 0) {
                NavigationLink { ReferenceGuideView() } label: {
                    moreRow(title: "Reference guide", subtitle: "FES-UA, FES-EO, PEP rules", symbol: "book.fill")
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("moreRowReferenceGuide")
            }
            .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
            .padding(.horizontal, DS.base)
        }
    }

    private var versionFooter: some View {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return Text("ScholarKeep \(version) (build \(build))")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, DS.lg)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, DS.base + DS.xs)
    }

    private func moreTile(title: String, subtitle: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: DS.xs) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(DS.accent)
                .frame(width: 36, height: 36)
                .background(DS.accentSoft, in: RoundedRectangle(cornerRadius: 12))
                .padding(.bottom, DS.xs)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .padding(DS.base)
        .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
    }

    private func moreRow(title: String, subtitle: String? = nil, symbol: String) -> some View {
        HStack(spacing: DS.md) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DS.accent)
                .frame(width: 32, height: 32)
                .background(DS.accentSoft, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, DS.base)
        .padding(.vertical, DS.md)
    }
}
