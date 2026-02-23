import UIKit

// MARK: - Haptic Vocabulary
// Each method maps to a specific moment in the workout experience.
// Generators are pre-warmed where latency matters.

enum Haptics {

    // MARK: - Core

    /// Light tap — form confirmations, stepper ticks, minor UI actions
    static func light() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        g.impactOccurred()
    }

    /// Medium impact — completing a set, confirming a log entry
    static func medium() {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.prepare()
        g.impactOccurred()
    }

    /// Heavy impact — exercise complete, rest timer fired
    static func heavy() {
        let g = UIImpactFeedbackGenerator(style: .heavy)
        g.prepare()
        g.impactOccurred()
    }

    /// Selection tick — day chips, goal/equipment cards, tab switches
    static func selection() {
        let g = UISelectionFeedbackGenerator()
        g.prepare()
        g.selectionChanged()
    }

    // MARK: - Semantic moments

    /// Set confirmed — medium impact, feels like marking something done
    static func setConfirmed() {
        medium()
    }

    /// Rest timer ended — heavy impact, immediate wake-up signal
    static func restEnded() {
        heavy()
    }

    /// Exercise complete (all sets done) — double heavy with a short gap
    static func exerciseComplete() {
        heavy()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { heavy() }
    }

    /// Session fully complete — success notification + heavy impact for ceremony
    static func sessionComplete() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { heavy() }
    }

    /// Session ended early — warning notification, communicates incompleteness
    static func sessionEndedEarly() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.warning)
    }

    /// Countdown tick — light impact, called for each of the final N seconds of rest
    static func countdownTick() {
        light()
    }

    /// Form save — light confirmation, not a celebration
    static func saved() {
        light()
    }

    /// Error / invalid action
    static func error() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.error)
    }

    // MARK: - Legacy alias (kept so existing call sites compile during transition)
    static func success() { sessionComplete() }
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let g = UIImpactFeedbackGenerator(style: style)
        g.prepare()
        g.impactOccurred()
    }
}
