import Foundation

// Reads session state written by the iPhone app via App Group UserDefaults.
// Must match kAppGroup in SetflowSharedData.swift on the phone.
private let kWatchAppGroup = "group.com.theoatuah.Setflow"

struct WatchSessionState: Codable {
    var isActive: Bool
    var routineName: String
    var exerciseName: String
    var currentSet: Int
    var totalSets: Int
    var isResting: Bool
    var restCountdown: Int
    var totalRestSeconds: Int
    var exerciseIndex: Int
    var totalExercises: Int
    var updatedAt: Date
}

enum WatchDataReader {
    private static let key = "watchSessionState"
    static func load() -> WatchSessionState? {
        guard let d = UserDefaults(suiteName: kWatchAppGroup),
              let data = d.data(forKey: key),
              let state = try? JSONDecoder().decode(WatchSessionState.self, from: data)
        else { return nil }
        return state
    }
}

enum WatchDataWriter {
    private static let key = "watchSessionState"
    static func write(_ state: WatchSessionState) {
        guard let d = UserDefaults(suiteName: kWatchAppGroup),
              let data = try? JSONEncoder().encode(state)
        else { return }
        d.set(data, forKey: key)
    }
    static func clear() {
        UserDefaults(suiteName: kWatchAppGroup)?.removeObject(forKey: key)
    }
}
