import Foundation

/// Pure streak math, extracted from WorkoutViewModel so it can be unit tested
/// in isolation (timezone boundaries, deload weeks, and the "today" grace day
/// are exactly the cases that are easy to get subtly wrong and hard to verify
/// by eye). Every function here takes its inputs explicitly and touches no
/// shared/observable state.
enum StreakCalculator {

    /// What a given date requires. Resolves the active programme as the
    /// source of truth whenever it actually covers that date — its own
    /// day-by-day plan is more specific and more likely to be current than
    /// a separately-maintained weekly TrainingSchedule, and the two can
    /// easily drift out of sync (e.g. a programme that trains Mon/Wed/Fri
    /// while the saved schedule still says Mon/Tue/Thu/Fri). Falls back to
    /// the saved schedule only when no programme covers the date.
    enum DayRequirement { case rest, training }

    static func requirement(
        for date: Date, schedule: TrainingSchedule, programme: TrainingProgramme?
    ) -> DayRequirement {
        if let programme, let day = programme.programmeDay(on: date) {
            return (day.isRestDay || day.isDeload) ? .rest : .training
        }
        return schedule.isTrainingDay(date) ? .training : .rest
    }

    /// Full result of a streak calculation, not just the headline number —
    /// lets the UI explain itself rather than just showing a count that
    /// silently changed.
    struct StreakResult {
        /// The current streak count.
        let count: Int
        /// The most recent day that genuinely broke the streak — a required
        /// day, missed, with no freeze left to cover it. nil if the streak
        /// is intact back through all available history (or there's no
        /// streak to break).
        let brokenOn: Date?
        /// Required days that were missed but covered by the weekly streak
        /// freeze rather than counted against the streak, newest first.
        let freezesUsed: [Date]
    }

    /// Current consecutive streak, with a weekly freeze: one missed required
    /// day per rolling 7-day window (measured in days walked back from
    /// today) is forgiven rather than breaking the streak outright. Deload
    /// weeks and rest days (from the programme when one covers the date,
    /// otherwise the saved schedule) are skipped entirely — they neither
    /// extend nor threaten the streak. Today gets its own grace: not having
    /// trained yet today never breaks anything, since the day isn't over.
    static func compute(
        history: [WorkoutHistory],
        schedule: TrainingSchedule,
        programme: TrainingProgramme?
    ) -> StreakResult {
        let cal        = Calendar.current
        let today      = cal.startOfDay(for: Date())
        let workedDays = Set(history.map { cal.startOfDay(for: $0.completedAt) })

        var streak        = 0
        var cursor         = today
        var checking       = true
        var brokenOn: Date? = nil
        var freezesUsed: [Date] = []

        var daysWalked     = 0
        var windowIndex     = 0
        var freezeAvailable = true

        while checking {
            let currentWindow = daysWalked / 7
            if currentWindow != windowIndex {
                windowIndex     = currentWindow
                freezeAvailable = true
            }

            switch requirement(for: cursor, schedule: schedule, programme: programme) {
            case .rest:
                break // skip silently — a legitimate day off

            case .training:
                if workedDays.contains(cursor) {
                    streak += 1
                } else if cursor == today {
                    // Grace — today isn't over yet
                } else if freezeAvailable {
                    freezeAvailable = false
                    freezesUsed.append(cursor)
                } else {
                    brokenOn = cursor
                    checking = false
                }
            }

            daysWalked += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            if prev < (workedDays.min() ?? prev) && streak == 0 { break }
            cursor = prev
            if cal.dateComponents([.day], from: cursor, to: today).day ?? 0 > 730 { break }
        }

        return StreakResult(count: streak, brokenOn: brokenOn, freezesUsed: freezesUsed)
    }

    /// Convenience wrapper for call sites that only need the number.
    static func currentStreak(
        history: [WorkoutHistory],
        schedule: TrainingSchedule,
        programme: TrainingProgramme?
    ) -> Int {
        compute(history: history, schedule: schedule, programme: programme).count
    }

    /// Longest run of consecutive worked days anywhere in history (not
    /// schedule/programme-aware — a simple "did they work this calendar day" streak).
    static func longestStreak(history: [WorkoutHistory]) -> Int {
        let cal        = Calendar.current
        let uniqueDays = Array(
            Set(history.map { cal.startOfDay(for: $0.completedAt) })
        ).sorted(by: >)

        guard !uniqueDays.isEmpty else { return 0 }
        var longest = 1, current = 1

        for i in 1..<uniqueDays.count {
            if let exp = cal.date(byAdding: .day, value: -1, to: uniqueDays[i - 1]),
               cal.isDate(uniqueDays[i], inSameDayAs: exp) {
                current += 1; longest = max(longest, current)
            } else { current = 1 }
        }
        return longest
    }

    /// A "real" workout today = a WorkoutHistory entry that isn't a Quick Win.
    static func hasTrainedToday(history: [WorkoutHistory]) -> Bool {
        let cal = Calendar.current
        return history.contains { cal.isDateInToday($0.completedAt) && !$0.isQuickWin }
    }

    static func hasQuickWinToday(history: [WorkoutHistory]) -> Bool {
        let cal = Calendar.current
        return history.contains { cal.isDateInToday($0.completedAt) && $0.isQuickWin }
    }

    static func hasWorkout(on date: Date, history: [WorkoutHistory]) -> Bool {
        let cal = Calendar.current
        return history.contains { cal.isDate($0.completedAt, inSameDayAs: date) }
    }
}
