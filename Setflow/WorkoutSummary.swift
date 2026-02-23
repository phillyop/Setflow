import Foundation

// Legacy single-exercise summary (kept for backwards compat)
struct WorkoutSummary: Identifiable {
    let id = UUID()
    let exerciseName: String
    let sets: Int
    let reps: Int
    let completedAt: Date
    var totalReps: Int { sets * reps }
}

// Full session summary shown after completing a routine
struct SessionSummary: Identifiable {
    let id = UUID()
    let routineName: String
    let results: [SessionExerciseResult]
    let durationSeconds: Int
    let wasCompleted: Bool
    let streak: Int

    var totalSets: Int { results.reduce(0) { $0 + $1.completedSets } }
    var totalReps: Int {
        let logged = results.reduce(0) { $0 + $1.totalReps }
        return logged > 0 ? logged : results.reduce(0) { $0 + ($1.completedSets * $1.reps) }
    }

    var durationText: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
}
