import SwiftUI
import SwiftData

@main
struct ScholarKeepApp: App {
    @State private var settings = AppSettings.shared

    let modelContainer: ModelContainer = {
        let schema = Schema([Student.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
        }
        .modelContainer(modelContainer)
    }
}
