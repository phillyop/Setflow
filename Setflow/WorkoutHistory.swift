import Foundation
import SwiftData

@Model
final class WorkoutHistory {
    // Defaults required for CloudKit compatibility.
    var id: UUID = UUID()
    var exerciseName: String = ""
    var completedAt: Date = Date()
    var sets: Int = 0
    var reps: Int = 0
    // Marks a lightweight "Quick Win" (mobility / minimum activity) day. Counts
    // toward the streak but is excluded from volume/PR/session statistics.
    var isQuickWin: Bool = false

    init(
        id: UUID = UUID(),
        exerciseName: String,
        completedAt: Date = Date(),
        sets: Int,
        reps: Int,
        isQuickWin: Bool = false
    ) {
        self.id           = id
        self.exerciseName = exerciseName
        self.completedAt  = completedAt
        self.sets         = sets
        self.reps         = reps
        self.isQuickWin   = isQuickWin
    }
}
