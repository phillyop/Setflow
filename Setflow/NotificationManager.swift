import UserNotifications

final class NotificationManager {

    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleReminders(for exercise: Exercise) {
        removeReminders(for: exercise)

        for (slotIndex, reminder) in exercise.reminders.prefix(2).enumerated() {
            guard reminder.isEnabled, !reminder.weekdays.isEmpty else { continue }

            for weekday in reminder.weekdays.sorted() {
                var components    = DateComponents()
                components.weekday = weekday
                components.hour   = reminder.hour
                components.minute = reminder.minute

                let content       = UNMutableNotificationContent()
                content.title     = "Workout Time"
                content.body      = "\(exercise.name) — \(exercise.sets)×\(exercise.reps)"
                content.sound     = .default
                content.userInfo  = ["exerciseID": exercise.id.uuidString]

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: components, repeats: true
                )
                let requestID = "\(exercise.id.uuidString)-slot-\(slotIndex)-wd-\(weekday)"
                UNUserNotificationCenter.current().add(
                    UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
                )
            }
        }
    }

    // MARK: - Daily Habit Nudge (smart timing + back-off, no guilt)

    private let habitMorningID = "habit-nudge-primary"
    private let habitRescueID  = "habit-nudge-rescue"

    /// Schedules the daily habit nudge based on the user's real behaviour.
    /// - Parameters:
    ///   - tone: user's chosen intensity (off disables entirely).
    ///   - usualHour: the hour the user most often trains (smart timing).
    ///   - streak: current streak, for specific copy.
    ///   - trainedToday: if already trained, we skip today and let tomorrow's fire.
    ///   - daysSinceLastActivity: for back-off — go quiet after prolonged disengagement.
    func scheduleHabitNudge(tone: NotificationTone,
                            usualHour: Int,
                            streak: Int,
                            trainedToday: Bool,
                            daysSinceLastActivity: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [habitMorningID, habitRescueID])

        // Off → no nudges at all.
        guard tone != .off else { return }

        // Back-off: if the user has clearly disengaged (a week+ away), stop the
        // daily push entirely. Hammering someone who left is both unkind and,
        // in the data, counterproductive. They can re-engage on their own terms.
        guard daysSinceLastActivity < 7 else { return }

        // Gentle tone only nudges once disengagement starts (2+ days off), so a
        // consistent user is left in peace.
        if tone == .gentle && daysSinceLastActivity < 2 { return }

        // Primary nudge at the user's usual training hour (clamped to a sane
        // waking window so a 3am outlier session doesn't set a 3am reminder).
        let hour = min(max(usualHour, 8), 20)

        if !trainedToday {
            let copy = streak > 0
                ? HabitNudge.pick(from: HabitNudge.streakActive, streak: streak)
                : HabitNudge.pick(from: HabitNudge.freshStart)

            scheduleDaily(id: habitMorningID, hour: hour, minute: 0,
                          title: copy.title, body: copy.body)
        }

        // Standard tone adds an evening Quick Win rescue if still untrained,
        // offering the low-friction path rather than piling on pressure.
        if tone == .standard {
            let rescue = HabitNudge.pick(from: HabitNudge.quickWinRescue)
            let rescueHour = max(hour + 4, 19)
            scheduleDaily(id: habitRescueID, hour: min(rescueHour, 21), minute: 0,
                          title: rescue.title, body: rescue.body)
        }
    }

    private func scheduleDaily(id: String, hour: Int, minute: Int, title: String, body: String) {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute

        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        )
    }

    func cancelHabitNudge() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [habitMorningID, habitRescueID])
    }

    func removeReminders(for exercise: Exercise) {
        var ids: [String] = []
        for slot in 0..<2 {
            for weekday in 1...7 {
                ids.append("\(exercise.id.uuidString)-slot-\(slot)-wd-\(weekday)")
            }
        }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Called after a session finishes. Removes any pending reminders for today
    /// that haven't fired yet — the user already trained. Reschedules so they
    /// return next week automatically.
    func suppressTodayReminders(for exerciseNames: [String], in exercises: [Exercise]) {
        let cal     = Calendar.current
        let weekday = cal.component(.weekday, from: Date())
        let hour    = cal.component(.hour,    from: Date())

        let matching = exercises.filter { exerciseNames.contains($0.name) }
        var toRemove: [String] = []

        for ex in matching {
            for (slotIndex, reminder) in ex.reminders.prefix(2).enumerated() {
                guard reminder.isEnabled,
                      reminder.weekdays.contains(weekday),
                      reminder.hour >= hour
                else { continue }
                toRemove.append("\(ex.id.uuidString)-slot-\(slotIndex)-wd-\(weekday)")
            }
        }

        guard !toRemove.isEmpty else { return }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: toRemove)

        // Reschedule so they fire again next week
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            for ex in matching { self.scheduleReminders(for: ex) }
        }
    }
}
