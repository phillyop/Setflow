import Foundation

/// The daily habit nudge — Setflow's take on Duolingo-style reminders, built to
/// be effective (smart timing, specificity, variety, back-off) WITHOUT the guilt.
/// Every line builds the user up or offers a low-friction path; none shame.
enum HabitNudge {

    // MARK: - Copy pools
    // Rotated so the user never sees the same line twice in a row (variety
    // prevents "banner blindness"). Split by context so the message is specific.

    /// User has an active streak worth protecting. Encouraging, identity-based.
    static let streakActive: [(title: String, body: String)] = [
        ("Keep it rolling 🔥",      "You're on a %d-day streak. Today keeps it alive."),
        ("You've got momentum",     "%d days strong. Ready for the next one?"),
        ("Same time, same you",     "Your %d-day streak is waiting. Let's go."),
        ("Consistency looks good",  "%d days in a row. Add one more today."),
        ("You're building something","A %d-day streak isn't luck — it's you. Keep going.")
    ]

    /// No current streak — invite a fresh start, no blame for the gap.
    static let freshStart: [(title: String, body: String)] = [
        ("Today's a good day to train", "A short session is all it takes to start."),
        ("Ready when you are",          "No streak yet — today's the day it begins."),
        ("One session in",              "Start now and you're already on a streak tomorrow."),
        ("Let's get moving",            "Your next workout is the first of the next streak."),
        ("Small start, real habit",     "Even a few sets today counts. Begin?")
    ]

    /// Late in the day and still not trained — offer the low-friction escape
    /// hatch (the Quick Win) rather than piling on pressure.
    static let quickWinRescue: [(title: String, body: String)] = [
        ("Short on time?",         "A 4-minute Quick Win still keeps your streak."),
        ("Still time today",       "No full workout? A Quick Win counts — 4 minutes."),
        ("Wind-down option",       "A gentle Quick Win keeps the habit alive tonight."),
        ("Four minutes is enough", "A Quick Win today protects your streak. Try it?")
    ]

    /// After a completed workout — celebrate, reinforce identity.
    static let afterWorkout: [(title: String, body: String)] = [
        ("Logged 💪",         "That's another one in the books. Nice work."),
        ("Streak secured",    "Today's done. You showed up — that's the whole game."),
        ("Strong finish",     "Session saved. Recovery is part of the plan too.")
    ]

    // MARK: - Selection

    /// Picks a line from a pool, avoiding immediate repeats via a stored index.
    private static let lastIndexKey = "habitNudgeLastIndex"

    static func pick(from pool: [(title: String, body: String)], streak: Int = 0) -> (title: String, body: String) {
        guard !pool.isEmpty else { return ("Time to train", "Your workout is waiting.") }

        let last = UserDefaults.shared.integer(forKey: lastIndexKey)
        var idx  = Int.random(in: 0..<pool.count)
        if pool.count > 1 && idx == last { idx = (idx + 1) % pool.count }
        UserDefaults.shared.set(idx, forKey: lastIndexKey)

        let chosen = pool[idx]
        // Fill %d with the streak count where the copy expects it.
        let body = chosen.body.contains("%d")
            ? String(format: chosen.body, streak)
            : chosen.body
        return (chosen.title, body)
    }
}
