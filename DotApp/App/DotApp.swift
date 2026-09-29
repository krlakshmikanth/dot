import SwiftData
import SwiftUI

@main
struct DotApp: App {
    private let modelContainer: ModelContainer = {
        let schema = Schema([
            Profile.self,
            Medication.self,
            DoseLog.self,
            PlannedDose.self
        ])

        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: ProcessInfo.processInfo.arguments.contains("-dot-ui-testing")
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to open dot's local data store: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(modelContainer)
    }
}
