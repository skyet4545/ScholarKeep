import SwiftUI
import SwiftData

@main
struct ScholarKeepApp: App {
    @State private var settings: AppSettings
    private let modelContainer: ModelContainer

    init() {
        // UI-test entry point: --reset wipes UserDefaults and uses an in-memory store
        // so every test starts at a known onboarding state.
        // --demo also forces in-memory and seeds sample data (App Store screenshots,
        // FPEA booth demos) so demo data never touches real records.
        let isDemo = DemoSeed.isActive
        let isUITest = CommandLine.arguments.contains("--reset") || isDemo
        let isScreenshot = CommandLine.arguments.contains("--screenshot")
        if isUITest {
            if let domain = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: domain)
            }
        }
        // Screenshot/demo mode: pre-populate onboarding so capture lands directly in the app.
        if isScreenshot || isDemo {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
        self._settings = State(initialValue: AppSettings(defaults: .standard))
        // First-party Apple crash + diagnostic capture (no third-party SDK).
        _ = CrashDiagnostics.shared
        // Stamp first-launch date so beta testers can be granted Lifetime Pro
        // when public launch happens.
        BetaEntitlement.recordFirstLaunchIfNeeded()
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
            RecurringTask.self,
            ReceiptCandidate.self
        ])
        // v0.7.1: CloudKit sync via the private database. SwiftData syncs
        // automatically when the device is signed in to iCloud. If not
        // signed in, the store behaves as a pure local store — no errors.
        // Tests use in-memory + no CloudKit.
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase =
            isUITest ? .none : .private("iCloud.com.carlosreyes.scholarkeep")
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isUITest,
            allowsSave: true,
            cloudKitDatabase: cloudKitDatabase
        )
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            if isDemo {
                DemoSeed.seed(into: ModelContext(self.modelContainer), settings: self._settings.wrappedValue)
            }
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
