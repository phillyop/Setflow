import Foundation
import SwiftData

// MARK: - ExerciseReminder

struct ExerciseReminder: Identifiable, Codable, Equatable {
    var id: UUID        = UUID()
    var weekdays: Set<Int> = []
    var hour: Int       = 16
    var minute: Int     = 30
    var isEnabled: Bool = true
}

// MARK: - ExerciseTrackingType

enum ExerciseTrackingType: String, Codable, CaseIterable {
    case bodyweight = "bodyweight"
    case weighted   = "weighted"

    var label: String {
        switch self {
        case .bodyweight: return "Bodyweight"
        case .weighted:   return "Weighted"
        }
    }

    var icon: String {
        switch self {
        case .bodyweight: return "figure.walk"
        case .weighted:   return "dumbbell.fill"
        }
    }
}

// MARK: - SetLog
// Records what actually happened in a single set.

struct SetLog: Identifiable, Codable, Equatable {
    var id: UUID      = UUID()
    var setNumber: Int
    var reps: Int
    var weight: Double?    // nil for bodyweight exercises
    var customRest: Int?   // nil = use exercise default rest
    var isWarmup: Bool = false   // excluded from PRs/volume stats, shown distinctly in history
    var rpe: Int? = nil    // optional Rate of Perceived Exertion, 1–10. nil = not logged.
}

// MARK: - Exercise

@Model
final class Exercise {
    // Every stored property has a default value. This is REQUIRED for SwiftData's
    // CloudKit-backed store: CloudKit forbids non-optional attributes without a
    // default, so without these the CloudKit container init throws and the app
    // silently falls back to a local-only store (sync never works).
    var id: UUID = UUID()
    var name: String = ""
    var sets: Int = 3
    var reps: Int = 10
    var restSeconds: Int = 60
    var sortOrder: Int = 0
    var trackingType: String = ExerciseTrackingType.bodyweight.rawValue
    var defaultWeight: Double = 0  // last used / default weight in kg
    var warmupSets: Int = 0    // how many leading sets in a session auto-tag as warm-up

    private var _remindersData: Data = Data()

    var reminders: [ExerciseReminder] {
        get { (try? JSONDecoder().decode([ExerciseReminder].self, from: _remindersData)) ?? [] }
        set { _remindersData = (try? JSONEncoder().encode(Array(newValue.prefix(2)))) ?? Data() }
    }

    var tracking: ExerciseTrackingType {
        get { ExerciseTrackingType(rawValue: trackingType) ?? .bodyweight }
        set { trackingType = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        sets: Int,
        reps: Int,
        restSeconds: Int,
        sortOrder: Int = 0,
        trackingType: ExerciseTrackingType = .bodyweight,
        defaultWeight: Double = 0,
        reminders: [ExerciseReminder] = [],
        warmupSets: Int = 0
    ) {
        self.id            = id
        self.name          = name
        self.sets          = sets
        self.reps          = reps
        self.restSeconds   = restSeconds
        self.sortOrder     = sortOrder
        self.trackingType  = trackingType.rawValue
        self.defaultWeight = defaultWeight
        self.warmupSets    = warmupSets
        self._remindersData = (try? JSONEncoder().encode(Array(reminders.prefix(2)))) ?? Data()
    }
}
