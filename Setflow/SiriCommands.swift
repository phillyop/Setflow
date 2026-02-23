import Foundation

// MARK: - Siri Command Bus

enum SiriCommand: String, Codable {
    case pauseRest    = "pauseRest"
    case skipRest     = "skipRest"
    case completeSet  = "completeSet"
    case endWorkout   = "endWorkout"
    case startRoutine = "startRoutine"
}

enum SiriCommandBus {

    // Keys defined as local constants inside each function
    // so nonisolated functions can access them without actor issues.
    private static let group = "group.com.theoatuah.Setflow"

    nonisolated static func post(_ command: SiriCommand, routineName: String? = nil) {
        let commandKey   = "siriCommand"
        let routineKey   = "siriRoutineName"
        let timestampKey = "siriCommandTimestamp"

        let d = UserDefaults(suiteName: "group.com.theoatuah.Setflow") ?? .standard
        d.set(command.rawValue, forKey: commandKey)
        d.set(Date().timeIntervalSince1970, forKey: timestampKey)
        if let name = routineName {
            d.set(name, forKey: routineKey)
        } else {
            d.removeObject(forKey: routineKey)
        }
    }

    @MainActor
    static func consume() -> (command: SiriCommand, routineName: String?)? {
        let commandKey   = "siriCommand"
        let routineKey   = "siriRoutineName"
        let timestampKey = "siriCommandTimestamp"

        let d = UserDefaults.shared
        guard
            let raw       = d.string(forKey: commandKey),
            let command   = SiriCommand(rawValue: raw),
            let timestamp = d.object(forKey: timestampKey) as? Double
        else { return nil }

        guard Date().timeIntervalSince1970 - timestamp < 10 else {
            clearInternal(d: d, commandKey: commandKey, routineKey: routineKey, timestampKey: timestampKey)
            return nil
        }

        let routineName = d.string(forKey: routineKey)
        clearInternal(d: d, commandKey: commandKey, routineKey: routineKey, timestampKey: timestampKey)
        return (command, routineName)
    }

    nonisolated static func clear() {
        let d = UserDefaults(suiteName: "group.com.theoatuah.Setflow") ?? .standard
        d.removeObject(forKey: "siriCommand")
        d.removeObject(forKey: "siriRoutineName")
        d.removeObject(forKey: "siriCommandTimestamp")
    }

    private static func clearInternal(d: UserDefaults,
                                      commandKey: String,
                                      routineKey: String,
                                      timestampKey: String) {
        d.removeObject(forKey: commandKey)
        d.removeObject(forKey: routineKey)
        d.removeObject(forKey: timestampKey)
    }
}
