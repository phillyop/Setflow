import ActivityKit
import Foundation

nonisolated struct SetflowLiveActivityAttributes: ActivityAttributes {

    public nonisolated struct ContentState: Codable, Hashable {
        var exerciseName: String
        var currentSet: Int
        var totalSets: Int
        var secondsRemaining: Int
        var totalRestSeconds: Int   // needed to draw the arc progress
        var isPaused: Bool

        // Absolute wall-clock time the rest ends. Lets the Live Activity animate
        // the countdown + ring continuously ON-DEVICE (via Text(timerInterval:)
        // and ProgressView(timerInterval:)) instead of ratcheting once per push.
        var endDate: Date
        // When the rest started — the other end of the timer interval.
        var startDate: Date
    }

    var workoutName: String
}
