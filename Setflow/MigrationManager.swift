import Foundation
import SwiftData

/// Runs once on first launch after the SwiftData migration.
/// Reads any exercises and history that were previously stored
/// in UserDefaults.shared and inserts them into SwiftData.
/// Marks completion with a UserDefaults flag so it never runs twice.
enum MigrationManager {

    private static let completedKey = "v2_swiftdata_migration_done"

    // Legacy key names (no longer written, only read during migration)
    private static let legacyExercisesKey = "exercises"
    private static let legacyHistoryKey   = "workoutHistory"

    static func migrateIfNeeded(context: ModelContext) {
        guard !UserDefaults.shared.bool(forKey: completedKey) else { return }

        migrateExercises(into: context)
        migrateHistory(into: context)

        try? context.save()

        // Clean up legacy keys
        UserDefaults.shared.removeObject(forKey: legacyExercisesKey)
        UserDefaults.shared.removeObject(forKey: legacyHistoryKey)

        UserDefaults.shared.set(true, forKey: completedKey)
        print("[Setflow] SwiftData migration complete.")
    }

    // MARK: - Private

    private static func migrateExercises(into context: ModelContext) {
        guard
            let data = UserDefaults.shared.data(forKey: legacyExercisesKey)
        else { return }

        struct LegacyExercise: Codable {
            let id: UUID
            var name: String
            var sets: Int
            var reps: Int
            var restSeconds: Int
            var reminders: [ExerciseReminder]
        }

        guard let legacy = try? JSONDecoder().decode([LegacyExercise].self, from: data)
        else { return }

        for (index, ex) in legacy.enumerated() {
            let exercise = Exercise(
                id: ex.id,
                name: ex.name,
                sets: ex.sets,
                reps: ex.reps,
                restSeconds: ex.restSeconds,
                sortOrder: index,
                reminders: ex.reminders
            )
            context.insert(exercise)
        }
    }

    private static func migrateHistory(into context: ModelContext) {
        guard
            let data = UserDefaults.shared.data(forKey: legacyHistoryKey)
        else { return }

        struct LegacyHistory: Codable {
            let id: UUID
            let exerciseName: String
            let completedAt: Date
            let sets: Int
            let reps: Int
        }

        guard let legacy = try? JSONDecoder().decode([LegacyHistory].self, from: data)
        else { return }

        for item in legacy {
            let entry = WorkoutHistory(
                id: item.id,
                exerciseName: item.exerciseName,
                completedAt: item.completedAt,
                sets: item.sets,
                reps: item.reps
            )
            context.insert(entry)
        }
    }
}
