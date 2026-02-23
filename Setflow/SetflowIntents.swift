import AppIntents
import SwiftUI

// MARK: - App Shortcuts Provider

struct SetflowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PauseRestIntent(),
            phrases: [
                "Pause rest in \(.applicationName)",
                "Pause timer in \(.applicationName)",
                "Resume rest in \(.applicationName)"
            ],
            shortTitle: "Pause Rest",
            systemImageName: "pause.fill"
        )
        AppShortcut(
            intent: SkipRestIntent(),
            phrases: [
                "Skip rest in \(.applicationName)",
                "End rest in \(.applicationName)",
                "Next set in \(.applicationName)"
            ],
            shortTitle: "Skip Rest",
            systemImageName: "forward.fill"
        )
        AppShortcut(
            intent: CompleteSetIntent(),
            phrases: [
                "Complete set in \(.applicationName)",
                "Done with set in \(.applicationName)",
                "Log set in \(.applicationName)"
            ],
            shortTitle: "Complete Set",
            systemImageName: "checkmark.circle.fill"
        )
        AppShortcut(
            intent: EndWorkoutIntent(),
            phrases: [
                "End workout in \(.applicationName)",
                "Finish workout in \(.applicationName)",
                "Stop workout in \(.applicationName)"
            ],
            shortTitle: "End Workout",
            systemImageName: "xmark.circle.fill"
        )
    }
}

// MARK: - 1. Start Routine
// Not in AppShortcuts (requires entity parameter) — available in Shortcuts app manually.

struct StartRoutineIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Routine"
    static var description = IntentDescription("Start a Setflow workout routine by name.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Routine Name", description: "The name of the routine to start")
    var routineName: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        SiriCommandBus.post(.startRoutine, routineName: routineName)
        return .result(dialog: "Starting \(routineName). Let's go!")
    }
}

// MARK: - 2. Pause Rest

struct PauseRestIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Rest"
    static var description = IntentDescription("Pause or resume the rest timer in Setflow.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        SiriCommandBus.post(.pauseRest)
        return .result(dialog: "Rest timer toggled.")
    }
}

// MARK: - 3. Skip Rest

struct SkipRestIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip Rest"
    static var description = IntentDescription("Skip the rest timer and go to the next set.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        SiriCommandBus.post(.skipRest)
        return .result(dialog: "Skipping rest. Next set!")
    }
}

// MARK: - 4. Complete Set

struct CompleteSetIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Set"
    static var description = IntentDescription("Mark the current set as complete in Setflow.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        SiriCommandBus.post(.completeSet)
        return .result(dialog: "Set logged.")
    }
}

// MARK: - 5. End Workout

struct EndWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "End Workout"
    static var description = IntentDescription("End the current Setflow workout and save progress.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        SiriCommandBus.post(.endWorkout)
        return .result(dialog: "Workout saved. Great work!")
    }
}
