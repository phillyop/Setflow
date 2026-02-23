import Foundation

/// Controls the daily habit nudge. The user owns this dial — opting in to a
/// firmer push is respectful; deciding it for them is not.
enum NotificationTone: String, Codable, CaseIterable, Identifiable {
    case off
    case gentle
    case standard

    var id: String { rawValue }

    var label: String {
        switch self {
        case .off:      return "Off"
        case .gentle:   return "Gentle"
        case .standard: return "Standard"
        }
    }

    var detail: String {
        switch self {
        case .off:      return "No daily reminders"
        case .gentle:   return "A soft nudge, only when you haven't trained"
        case .standard: return "A daily reminder at your usual training time"
        }
    }
}

struct NotificationPreference: Codable, Equatable {
    var tone: NotificationTone = .standard
    /// The training hour the user picked during onboarding. Used to seed nudge
    /// timing before there's real workout history to learn from. nil = never set.
    var seedHour: Int? = nil

    private static let key = "notificationPreference"

    static func load() -> NotificationPreference {
        guard
            let data = UserDefaults.shared.data(forKey: key),
            let pref = try? JSONDecoder().decode(NotificationPreference.self, from: data)
        else { return NotificationPreference() }
        return pref
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.shared.set(data, forKey: Self.key)
        }
    }
}
