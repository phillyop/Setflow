import SwiftUI
import SwiftData
import AppIntents

@main
struct SetFlowApp: App {

    let container: ModelContainer

    init() {
        NotificationManager.shared.requestPermission()
        NotificationRouter.shared.register()
        HealthKitManager.shared.requestAuthorisation()
        SetflowShortcuts.updateAppShortcutParameters()
        container = Self.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }

    // MARK: - Container Factory

    private static func makeContainer() -> ModelContainer {
        let models: [any PersistentModel.Type] = [
            Exercise.self, WorkoutHistory.self,
            WorkoutRoutine.self, SessionHistory.self,
            TrainingProgramme.self, BodyMetric.self
        ]

        // Try CloudKit-backed store first (requires iCloud entitlement in Xcode:
        // Signing & Capabilities → + iCloud → CloudKit → container "iCloud.com.yourname.Setflow")
        let cloudConfig = ModelConfiguration(
            schema: Schema(models),
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        if let c = try? ModelContainer(for: Schema(models), configurations: [cloudConfig]) {
            print("[Setflow] Using CloudKit-backed store.")
            return c
        }

        // CloudKit unavailable (no iCloud account, entitlement missing, etc.)
        // Fall back to local store silently.
        print("[Setflow] CloudKit unavailable — falling back to local store.")
        if let c = try? ModelContainer(for: Schema(models)) {
            return c
        }

        // Schema mismatch — wipe and recreate locally.
        print("[Setflow] Schema mismatch — resetting local store.")
        deleteStoreFiles()
        do {
            return try ModelContainer(for: Schema(models))
        } catch {
            fatalError("[Setflow] Could not create ModelContainer after reset: \(error)")
        }
    }

    private static func deleteStoreFiles() {
        guard let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        else { return }

        let extensions = ["store", "store-shm", "store-wal"]
        for ext in extensions {
            let url = appSupport.appendingPathComponent("default.\(ext)")
            try? FileManager.default.removeItem(at: url)
        }
    }
}
