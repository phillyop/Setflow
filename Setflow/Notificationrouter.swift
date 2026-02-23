import UserNotifications
import Foundation

/// Handles taps on notifications and records a pending action the app routes
/// when it next becomes active. Reuses the App Group UserDefaults pattern
/// already used for Siri commands, so no AppDelegate plumbing is required.
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationRouter()

    private let pendingKey = "pendingNotificationAction"

    enum Action: String {
        case startToday       // daily nudge → start today's workout
        case startQuickWin    // rescue nudge → start a Quick Win
        case openExercise     // per-exercise reminder → that exercise
    }

    func register() {
        UNUserNotificationCenter.current().delegate = self
    }

    // Show banners even while the app is foregrounded.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // Record which action the tapped notification implies.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let id       = response.notification.request.identifier
        let userInfo = response.notification.request.content.userInfo

        let action: Action
        if id.contains("rescue") {
            action = .startQuickWin
        } else if id.contains("habit-nudge") {
            action = .startToday
        } else if userInfo["exerciseID"] is String {
            action = .openExercise
        } else {
            action = .startToday
        }

        var payload: [String: String] = ["action": action.rawValue]
        if let exID = userInfo["exerciseID"] as? String {
            payload["exerciseID"] = exID
        }
        UserDefaults.shared.set(payload, forKey: pendingKey)

        completionHandler()
    }

    /// Consumes the pending action (if any). Called by the app when it becomes active.
    func consumePendingAction() -> (action: Action, exerciseID: String?)? {
        guard
            let payload = UserDefaults.shared.dictionary(forKey: pendingKey) as? [String: String],
            let raw     = payload["action"],
            let action  = Action(rawValue: raw)
        else { return nil }

        UserDefaults.shared.removeObject(forKey: pendingKey)
        return (action, payload["exerciseID"])
    }
}
