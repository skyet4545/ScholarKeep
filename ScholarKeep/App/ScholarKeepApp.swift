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
        if isUITest {
            if let domain = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: domain)
            }
        }
        self._settings = State(initialValue: AppSettings(defaults: .standard))

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
            BalanceEntry.self
        ])
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
