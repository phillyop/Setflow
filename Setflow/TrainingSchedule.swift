import Foundation

// MARK: - TrainingSchedule
// Stores which weekdays the user plans to train.
// 1 = Sunday, 2 = Monday ... 7 = Saturday (Calendar.current weekday convention)

struct TrainingSchedule: Codable, Equatable {

    /// Weekdays the user intends to train. Empty = every day (default).
    var scheduledWeekdays: Set<Int>

    /// Whether schedule-aware streak is enabled.
    /// When false, behaviour is identical to old daily streak.
    var isEnabled: Bool

    static let `default` = TrainingSchedule(scheduledWeekdays: [], isEnabled: false)

    /// Returns true if the given date is a planned training day.
    ///
    /// When no schedule has been configured, this used to return true for
    /// every single day — meaning an unconfigured user's streak broke the
    /// moment they took ANY day off, since nothing was ever treated as a
    /// legitimate rest day. Nobody trains 7 days a week, so that default
    /// was effectively punishing people for not having visited Settings.
    /// Falling back to a conventional 6-day week (every day but Sunday)
    /// gives everyone at least one guaranteed rest day out of the box,
    /// without requiring onboarding to ask a new question up front.
    func isTrainingDay(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        guard isEnabled, !scheduledWeekdays.isEmpty else {
            return weekday != 1 // 1 = Sunday
        }
        return scheduledWeekdays.contains(weekday)
    }

    /// Ordered weekdays for display (Mon–Sun)
    static let weekdayLabels: [(Int, String)] = [
        (2, "Mon"), (3, "Tue"), (4, "Wed"),
        (5, "Thu"), (6, "Fri"), (7, "Sat"), (1, "Sun")
    ]
}

// MARK: - Persistence

extension TrainingSchedule {
    private static let key = "trainingSchedule"

    static func load() -> TrainingSchedule {
        guard
            let data     = UserDefaults.shared.data(forKey: key),
            let schedule = try? JSONDecoder().decode(TrainingSchedule.self, from: data)
        else { return .default }
        return schedule
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.shared.set(data, forKey: Self.key)
        }
    }
}
