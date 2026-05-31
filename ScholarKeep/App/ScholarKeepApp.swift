import SwiftUI
import SwiftData

@main
struct ScholarKeepApp: App {
    @State private var settings: AppSettings
    private let modelContainer: ModelContainer

    init() {
        // UI-test entry point: --reset wipes UserDefaults and uses an in-memory store
        // so every test starts at a known onboarding state.
        let isUITest = CommandLine.arguments.contains("--reset")
        let isScreenshot = CommandLine.arguments.contains("--screenshot")
        if isUITest {
            if let domain = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: domain)
            }
        }
        // Screenshot mode: pre-populate onboarding so capture lands directly on the app.
        if isScreenshot {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
        self._settings = State(initialValue: AppSettings(defaults: .standard))
        // First-party Apple crash + diagnostic capture (no third-party SDK).
        _ = CrashDiagnostics.shared
        // Background-refresh the ruleset from the public URL. Fails silently.
        if !isUITest {
            Task.detached(priority: .background) {
                _ = await RulesetLoader.shared.fetchRemote()
            }
        }

        let schema = Schema([
            Student.self,
            Expense.self,
            LineItem.self,
            Attachment.self,
            Claim.self,
            StatusEvent.self,
            DevicePurchase.self,
            Provider.self,
            PreAuthorization.self,
            Refund.self,
            BalanceEntry.self,
            RecurringTask.self
        ])
        // v0.7.0 prep: model declarations are now CloudKit-compatible
        // (all properties have default values, all relationships have
        // inverses). The remaining blocker for enabling CloudKit is making
        // every to-many array optional [Type]? — which cascades into 60+
        // call sites that read `expenses.count` / `expenses.first`. Doing
        // that refactor + testing two-device sync correctly = its own
        // dedicated build (v0.7.1). For now, ship the foundation work and
        // keep cloudKitDatabase: .none so existing local data continues to
        // work without any sync behaviour.
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isUITest,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Fall back to in-memory so the app doesn't crash on schema mismatch.
            self.modelContainer = try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
        }
        .modelContainer(modelContainer)
    }
}
