import Foundation
import WidgetKit

// MARK: - App Group identifier
// Must exactly match the App Group in Xcode:
//   Each target → Signing & Capabilities → App Groups → group.com.theoatuah.Setflow
let kAppGroup = "group.com.theoatuah.Setflow"

// MARK: - Shared UserDefaults
extension UserDefaults {
    static var shared: UserDefaults {
        UserDefaults(suiteName: kAppGroup) ?? .standard
    }
}

// MARK: - Persistence keys
// widgetSnapshot is the only key written here.
// Exercises and history are stored in SwiftData (main app only).
enum SharedKey {
    static let widgetSnapshot = "widgetSnapshot"
}

// MARK: - WidgetSnapshot
// Plain Codable struct — safe to use in both the main app and widget targets.
struct WidgetSnapshot: Codable {
    struct ExerciseRow: Codable {
        let name: String
        let sets: Int
        let reps: Int
        let doneToday: Bool
    }

    let streak: Int
    let completedToday: Int
    let exercises: [ExerciseRow]   // up to 4
    let updatedAt: Date
}

// MARK: - Writer (main app only — calls WidgetCenter which isn't available in widget extension)
enum SharedDataWriter {
    static func writeSnapshot(exercises: [Exercise],
                              history: [WorkoutHistory],
                              streak: Int) {
        let calendar = Calendar.current

        let completedToday = history.filter {
            calendar.isDateInToday($0.completedAt)
        }.count

        let completedNames = Set(
            history
                .filter { calendar.isDateInToday($0.completedAt) }
                .map { $0.exerciseName }
        )

        let rows = exercises.prefix(4).map { ex in
            WidgetSnapshot.ExerciseRow(
                name: ex.name,
                sets: ex.sets,
                reps: ex.reps,
                doneToday: completedNames.contains(ex.name)
            )
        }

        let snapshot = WidgetSnapshot(
            streak: streak,
            completedToday: completedToday,
            exercises: Array(rows),
            updatedAt: Date()
        )

        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.shared.set(data, forKey: SharedKey.widgetSnapshot)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Reader (widget extension uses this)
enum SharedDataReader {
    static func loadSnapshot() -> WidgetSnapshot {
        guard
            let data     = UserDefaults.shared.data(forKey: SharedKey.widgetSnapshot),
            let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else {
            return WidgetSnapshot(
                streak: 0,
                completedToday: 0,
                exercises: [
                    .init(name: "Push-ups",      sets: 4, reps: 12, doneToday: false),
                    .init(name: "Russian Twists", sets: 4, reps: 10, doneToday: false)
                ],
                updatedAt: Date()
            )
        }
        return snapshot
    }
}
