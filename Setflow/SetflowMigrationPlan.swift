import SwiftData

// MARK: - Migration Plan
// Tells SwiftData how to evolve the schema between versions.
// V1 = original UserDefaults era (no SwiftData schema).
// V2 = current schema with trackingType, defaultWeight, setLogs etc.

enum SetflowMigrationPlan: SchemaMigrationPlan {

    static var schemas: [any VersionedSchema.Type] {
        [SetflowSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        // No data to migrate from V1 (it was UserDefaults).
        // Lightweight migration handles new optional/default columns automatically.
        []
    }
}

// MARK: - Current Schema Version

enum SetflowSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Exercise.self, WorkoutHistory.self, WorkoutRoutine.self, SessionHistory.self]
    }
}
