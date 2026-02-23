import Foundation
import SwiftData

// MARK: - RoutineExercise
// A snapshot of an exercise as it exists when added to a routine.
// Intentionally denormalised — editing the source Exercise won't
// silently mutate saved routines.

struct RoutineExercise: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var exerciseID: UUID
    var name: String
    var sets: Int
    var reps: Int
    var restSeconds: Int
    var sortOrder: Int
    var trackingType: String   // ExerciseTrackingType.rawValue
    var defaultWeight: Double
    var warmupSets: Int = 0    // leading sets in this exercise auto-tagged as warm-up

    var tracking: ExerciseTrackingType {
        ExerciseTrackingType(rawValue: trackingType) ?? .bodyweight
    }
}

// MARK: - WorkoutRoutine

@Model
final class WorkoutRoutine {
    // Defaults required for CloudKit compatibility (see note on Exercise).
    var id: UUID = UUID()
    var name: String = ""
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    // Exercises stored as JSON Data — same pattern as Exercise.reminders
    private var _exercisesData: Data = Data()

    var exercises: [RoutineExercise] {
        get {
            (try? JSONDecoder().decode([RoutineExercise].self, from: _exercisesData)) ?? []
        }
        set {
            _exercisesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    // Derived: total estimated minutes (sum of sets * restSeconds + ~30s per set)
    var estimatedMinutes: Int {
        let totalSeconds = exercises.reduce(0) { acc, ex in
            acc + (ex.sets * (ex.restSeconds + 30))
        }
        return max(1, totalSeconds / 60)
    }

    var exerciseCount: Int { exercises.count }

    init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int = 0,
        exercises: [RoutineExercise] = []
    ) {
        self.id        = id
        self.name      = name
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self._exercisesData = (try? JSONEncoder().encode(exercises)) ?? Data()
    }
}

// MARK: - SessionExerciseResult
// Records what actually happened for one exercise in a session.

struct SessionExerciseResult: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var exerciseID: UUID
    var exerciseName: String
    var sets: Int
    var reps: Int
    var completedSets: Int
    var setLogs: [SetLog]       // one entry per completed set, warm-up and working both included

    /// Working sets only — what actually counts toward volume, PRs, and progress.
    private var workingLogs: [SetLog] { setLogs.filter { !$0.isWarmup } }

    var warmupLogs: [SetLog] { setLogs.filter(\.isWarmup) }
    var completedWorkingSets: Int { workingLogs.count }
    var completedWarmupSets: Int { warmupLogs.count }

    /// "3 working + 2 warm-up" style summary for history display.
    var completionSummary: String {
        guard completedWarmupSets > 0 else { return "\(completedWorkingSets) of \(sets) sets" }
        return "\(completedWorkingSets) working + \(completedWarmupSets) warm-up"
    }

    var totalReps: Int { workingLogs.reduce(0) { $0 + $1.reps } }
    var totalVolume: Double {   // kg × reps, 0 for bodyweight — warm-ups excluded
        workingLogs.reduce(0) { $0 + (($1.weight ?? 0) * Double($1.reps)) }
    }
    var averageWeight: Double? {
        let weighted = workingLogs.compactMap(\.weight)
        guard !weighted.isEmpty else { return nil }
        return weighted.reduce(0, +) / Double(weighted.count)
    }

    /// True if a working set fell short of this exercise's target rep count
    /// for the session. Warm-ups are never flagged — they're not held to the
    /// working target. Uses `reps`, the target already snapshotted on this
    /// result, so no new storage is needed.
    func missedTarget(_ log: SetLog) -> Bool {
        !log.isWarmup && log.reps < reps
    }

    /// Count of working sets that missed target — handy for a session-level summary.
    var targetMissCount: Int { workingLogs.filter { $0.reps < reps }.count }
}

// MARK: - SessionHistory
// One completed (or abandoned) session.

@Model
final class SessionHistory {
    // Defaults required for CloudKit compatibility (see note on Exercise).
    var id: UUID = UUID()
    var routineName: String = "Workout"
    var startedAt: Date = Date()
    var completedAt: Date = Date()
    var wasCompleted: Bool = true      // false if user ended early

    private var _resultsData: Data = Data()

    var results: [SessionExerciseResult] {
        get {
            (try? JSONDecoder().decode([SessionExerciseResult].self, from: _resultsData)) ?? []
        }
        set {
            _resultsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var durationSeconds: Int {
        Int(completedAt.timeIntervalSince(startedAt))
    }

    var totalSets: Int {
        results.reduce(0) { $0 + $1.completedSets }
    }

    init(
        id: UUID = UUID(),
        routineName: String,
        startedAt: Date = Date(),
        completedAt: Date = Date(),
        wasCompleted: Bool = true,
        results: [SessionExerciseResult] = []
    ) {
        self.id           = id
        self.routineName  = routineName
        self.startedAt    = startedAt
        self.completedAt  = completedAt
        self.wasCompleted = wasCompleted
        self._resultsData = (try? JSONEncoder().encode(results)) ?? Data()
    }
}
