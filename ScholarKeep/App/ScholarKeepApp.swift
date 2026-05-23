import SwiftUI
import SwiftData

@main
struct ScholarKeepApp: App {
    @State private var settings = AppSettings.shared
    private let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            Student.self,
            Expense.self,
            LineItem.self,
            Attachment.self,
            Claim.self,
            StatusEvent.self,
            DevicePurchase.self
        ])
        // iCloud sync requires a CloudKit-compatible schema (no .unique ids,
        // all properties optional or defaulted) and a provisioned iCloud container.
        // Tracked as a v0.2 task; for v0.1 the toggle persists the preference only.
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Fall back to in-memory so the app doesn't crash on schema mismatch — surfaces in Settings as a warning.
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
