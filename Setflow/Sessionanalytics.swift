import Foundation

/// Pure read-only calculations over session history — volume trends, personal
/// bests, consistency, recent sets. Extracted from WorkoutViewModel: none of
/// this touches observable/session state, it just transforms
/// `[SessionHistory]` (and occasionally a schedule) into numbers and structs
/// the UI displays. Kept separate so it's testable on its own and so
/// WorkoutViewModel isn't the only place this logic can be exercised.
enum SessionAnalytics {

    /// All unique exercise names that appear in session history.
    static func trackedExerciseNames(sessionHistory: [SessionHistory]) -> [String] {
        let names = sessionHistory.flatMap { $0.results.map(\.exerciseName) }
        return Array(Set(names)).sorted()
    }

    /// Weekly volume data for one exercise — last `weeks` weeks, oldest first.
    /// Warm-up sets are excluded; they'd distort the working-volume trend.
    static func weeklyVolume(
        for exerciseName: String,
        weeks: Int = 8,
        sessionHistory: [SessionHistory]
    ) -> [WeeklyVolume] {
        let cal = Calendar.current
        let now = Date()

        return (0..<weeks).reversed().compactMap { offset -> WeeklyVolume? in
            let refDate = cal.date(byAdding: .weekOfYear, value: -offset, to: now) ?? now
            guard let interval = cal.dateInterval(of: .weekOfYear, for: refDate) else { return nil }
            let start = interval.start
            let end   = interval.end

            let results = sessionHistory
                .filter { $0.completedAt >= start && $0.completedAt < end }
                .flatMap { $0.results }
                .filter { $0.exerciseName == exerciseName }

            let allLogs   = results.flatMap(\.setLogs).filter { !$0.isWarmup }
            let hasWeight = allLogs.contains { $0.weight != nil }
            let volume: Double = hasWeight
                ? allLogs.reduce(0) { $0 + (($1.weight ?? 0) * Double($1.reps)) }
                : Double(allLogs.reduce(0) { $0 + $1.reps })

            return WeeklyVolume(weekStart: start, volume: volume, isWeighted: hasWeight)
        }
    }

    /// Personal best set for an exercise. Warm-up sets never count toward a
    /// PR — a heavy warm-up shouldn't falsely register as a personal record.
    static func personalBest(for exerciseName: String, sessionHistory: [SessionHistory]) -> PersonalBest? {
        let allLogs: [(log: SetLog, date: Date)] = sessionHistory.flatMap { session in
            session.results
                .filter { $0.exerciseName == exerciseName }
                .flatMap { result in
                    result.setLogs.filter { !$0.isWarmup }.map { (log: $0, date: session.completedAt) }
                }
        }

        if let best = allLogs.filter({ $0.log.weight != nil })
            .max(by: { ($0.log.weight ?? 0) < ($1.log.weight ?? 0) }) {
            return PersonalBest(exerciseName: exerciseName, weight: best.log.weight,
                                reps: best.log.reps, date: best.date, isWeighted: true)
        }
        if let best = allLogs.max(by: { $0.log.reps < $1.log.reps }) {
            return PersonalBest(exerciseName: exerciseName, weight: nil,
                                reps: best.log.reps, date: best.date, isWeighted: false)
        }
        return nil
    }

    /// Recent set logs for an exercise, newest first.
    static func recentSetLogs(
        for exerciseName: String,
        limit: Int = 10,
        sessionHistory: [SessionHistory]
    ) -> [(log: SetLog, date: Date, sessionName: String)] {
        let all = sessionHistory.flatMap { session in
            session.results
                .filter { $0.exerciseName == exerciseName }
                .flatMap { result in
                    result.setLogs.map { (log: $0, date: session.completedAt, sessionName: session.routineName) }
                }
        }
        return Array(all.sorted { $0.date > $1.date }.prefix(limit))
    }

    /// Total sessions that included a given exercise.
    static func sessionCount(for exerciseName: String, sessionHistory: [SessionHistory]) -> Int {
        sessionHistory.filter { $0.results.contains { $0.exerciseName == exerciseName } }.count
    }

    /// Total kg·reps volume lifted across all sessions.
    static func totalVolumeLifted(sessionHistory: [SessionHistory]) -> Double {
        sessionHistory.flatMap(\.results).reduce(0) { $0 + $1.totalVolume }
    }

    /// Volume lifted this calendar month.
    static func volumeThisMonth(sessionHistory: [SessionHistory]) -> Double {
        let cal = Calendar.current
        let now = Date()
        return sessionHistory
            .filter { cal.isDate($0.completedAt, equalTo: now, toGranularity: .month) }
            .flatMap(\.results)
            .reduce(0) { $0 + $1.totalVolume }
    }

    /// Volume lifted this calendar week.
    static func volumeThisWeek(sessionHistory: [SessionHistory]) -> Double {
        let cal = Calendar.current
        let now = Date()
        return sessionHistory
            .filter { cal.isDate($0.completedAt, equalTo: now, toGranularity: .weekOfYear) }
            .flatMap(\.results)
            .reduce(0) { $0 + $1.totalVolume }
    }

    /// Sessions per day for the last `days` days, ordered oldest → newest.
    static func dailySessionCounts(days: Int = 28, sessionHistory: [SessionHistory]) -> [(date: Date, count: Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            let count = sessionHistory.filter { cal.isDate($0.completedAt, inSameDayAs: day) }.count
            return (date: day, count: count)
        }
    }

    /// % of scheduled training days in the last 30 days that had a workout.
    /// Falls back to raw days-worked / 30 if there's no schedule.
    static func consistencyScore(sessionHistory: [SessionHistory], schedule: TrainingSchedule) -> Double {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let days = (0..<30).map { cal.date(byAdding: .day, value: -$0, to: today)! }

        let scheduledDays = days.filter { schedule.isTrainingDay($0) }
        guard !scheduledDays.isEmpty else {
            let worked = days.filter { d in sessionHistory.contains { cal.isDate($0.completedAt, inSameDayAs: d) } }.count
            return Double(worked) / 30.0
        }

        let workedScheduledDays = scheduledDays.filter { d in
            sessionHistory.contains { cal.isDate($0.completedAt, inSameDayAs: d) }
        }.count

        return Double(workedScheduledDays) / Double(scheduledDays.count)
    }

    /// Routine session counts, sorted descending.
    static func sessionsByRoutine(sessionHistory: [SessionHistory]) -> [(routineName: String, count: Int)] {
        let grouped = Dictionary(grouping: sessionHistory, by: { $0.routineName })
        return grouped.map { (routineName: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    /// The week with the highest number of sessions.
    static func bestWeek(sessionHistory: [SessionHistory]) -> (start: Date, count: Int)? {
        let cal = Calendar.current
        guard !sessionHistory.isEmpty else { return nil }

        let grouped = Dictionary(grouping: sessionHistory) { session -> Date in
            cal.dateInterval(of: .weekOfYear, for: session.completedAt)?.start ?? session.completedAt
        }

        return grouped
            .map { (start: $0.key, count: $0.value.count) }
            .max { $0.count < $1.count }
    }
}
