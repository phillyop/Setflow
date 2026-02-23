import Foundation
import SwiftData

// MARK: - ProgrammeDay
// One day in a programme week — either a rest day or assigned to a routine.

struct ProgrammeDay: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var weekday: Int          // 1=Mon … 7=Sun (display order, not Calendar weekday)
    var routineID: UUID?      // nil = rest day
    var routineName: String   // snapshot for display, avoids fetch
    var isDeload: Bool = false

    var isRestDay: Bool { routineID == nil }

    static func rest(weekday: Int) -> ProgrammeDay {
        ProgrammeDay(weekday: weekday, routineID: nil, routineName: "Rest")
    }
}

// MARK: - ProgrammeWeek

struct ProgrammeWeek: Identifiable, Codable, Equatable {
    var id: UUID    = UUID()
    var weekNumber: Int
    var label: String         // e.g. "Week 1", "Deload Week"
    var isDeload: Bool = false
    var days: [ProgrammeDay]  // 7 days, indexed 0=Mon … 6=Sun

    static func make(weekNumber: Int, label: String? = nil, isDeload: Bool = false, days: [ProgrammeDay]) -> ProgrammeWeek {
        ProgrammeWeek(
            weekNumber: weekNumber,
            label: label ?? (isDeload ? "Deload Week" : "Week \(weekNumber)"),
            isDeload: isDeload,
            days: days
        )
    }
}

// MARK: - TrainingProgramme

@Model
final class TrainingProgramme {
    // Defaults required for CloudKit compatibility (see note on Exercise).
    var id: UUID = UUID()
    var name: String = ""
    var goal: String = ""           // e.g. "Build Strength", "Lose Weight"
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var isActive: Bool = false         // only one programme active at a time

    // Start date — used to calculate current week/day
    var startedAt: Date?

    private var _weeksData: Data = Data()

    var weeks: [ProgrammeWeek] {
        get { (try? JSONDecoder().decode([ProgrammeWeek].self, from: _weeksData)) ?? [] }
        set { _weeksData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var totalWeeks: Int { weeks.count }
    var trainingDaysPerWeek: Int {
        weeks.first?.days.filter { !$0.isRestDay }.count ?? 0
    }

    // MARK: - Current day calculation

    /// Returns the current week index (0-based) and day index (0-based, 0=Mon)
    func currentPosition() -> (weekIndex: Int, dayIndex: Int)? {
        guard let start = startedAt, !weeks.isEmpty else { return nil }
        let cal          = Calendar.current
        let daysSinceStart = cal.dateComponents([.day], from: cal.startOfDay(for: start),
                                                 to: cal.startOfDay(for: Date())).day ?? 0
        let weekIndex    = min(daysSinceStart / 7, weeks.count - 1)
        let rawWeekday   = cal.component(.weekday, from: Date()) // 1=Sun…7=Sat
        // Convert to Mon=0 … Sun=6
        let dayIndex     = (rawWeekday + 5) % 7
        return (weekIndex, dayIndex)
    }

    /// Today's programme day, if a programme is active and started
    func todayProgrammeDay() -> ProgrammeDay? {
        guard let pos = currentPosition() else { return nil }
        guard pos.weekIndex < weeks.count,
              pos.dayIndex  < weeks[pos.weekIndex].days.count
        else { return nil }
        return weeks[pos.weekIndex].days[pos.dayIndex]
    }

    /// The programme day for an arbitrary date, if this programme actually
    /// covers that date (on or after startedAt, within totalWeeks). Unlike
    /// todayProgrammeDay()/currentPosition(), this does NOT clamp to the
    /// final week — a date past the programme's end returns nil, same as a
    /// date before it started. Used by StreakCalculator so a date it's
    /// walking through can defer to "what did the active programme actually
    /// ask for that day" rather than a separately-maintained schedule.
    func programmeDay(on date: Date) -> ProgrammeDay? {
        guard let start = startedAt, !weeks.isEmpty else { return nil }
        let cal = Calendar.current
        let daysSinceStart = cal.dateComponents([.day], from: cal.startOfDay(for: start),
                                                 to: cal.startOfDay(for: date)).day ?? 0
        guard daysSinceStart >= 0 else { return nil }
        let weekIndex = daysSinceStart / 7
        guard weekIndex < weeks.count else { return nil }
        let rawWeekday = cal.component(.weekday, from: date) // 1=Sun…7=Sat
        let dayIndex   = (rawWeekday + 5) % 7                // Mon=0…Sun=6
        guard dayIndex < weeks[weekIndex].days.count else { return nil }
        return weeks[weekIndex].days[dayIndex]
    }

    /// Progress fraction (0.0 – 1.0) through the full programme
    func progressFraction() -> Double {
        guard let start = startedAt, totalWeeks > 0 else { return 0 }
        let cal  = Calendar.current
        let days = cal.dateComponents([.day], from: start, to: Date()).day ?? 0
        return min(1.0, Double(days) / Double(totalWeeks * 7))
    }

    init(id: UUID = UUID(), name: String, goal: String = "",
         sortOrder: Int = 0, weeks: [ProgrammeWeek] = []) {
        self.id        = id
        self.name      = name
        self.goal      = goal
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.isActive  = false
        self._weeksData = (try? JSONEncoder().encode(weeks)) ?? Data()
    }
}
