import Foundation

// MARK: - Analytics Data Structs
// Used by WorkoutViewModel's weeklyVolume(for:)/personalBest(for:) and
// consumed by ProgressTabView. The view that used to live in this file
// (struct ProgressView: View) was superseded by ProgressTabView and has
// been removed — it shadowed SwiftUI's own ProgressView, which forced a
// workaround (SwiftUI.ProgressView()) elsewhere in the codebase.

struct WeeklyVolume: Identifiable {
    let id = UUID()
    let weekStart: Date
    let volume: Double
    let isWeighted: Bool

    var label: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: weekStart)
    }
}

struct PersonalBest {
    let exerciseName: String
    let weight: Double?
    let reps: Int
    let date: Date
    let isWeighted: Bool

    var displayString: String {
        if let w = weight {
            let wStr = w.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(w))kg" : String(format: "%.1fkg", w)
            return "\(wStr) × \(reps) reps"
        }
        return "\(reps) reps"
    }
}
