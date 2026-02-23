import Foundation
import HealthKit

final class HealthKitManager {

    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    // Types we write
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKQuantityType(.activeEnergyBurned)
    ]

    // MARK: - Authorisation

    /// Requests HealthKit write permission. Safe to call multiple times — HealthKit
    /// only shows the prompt once. If HealthKit is unavailable (iPad without Health),
    /// silently does nothing.
    func requestAuthorisation(completion: @escaping (Bool) -> Void = { _ in }) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }

        store.requestAuthorization(toShare: writeTypes, read: []) { granted, error in
            if let error { print("[Setflow] HealthKit auth error: \(error)") }
            completion(granted)
        }
    }

    // MARK: - Write Workout

    /// Writes a completed session to Apple Health as a HKWorkout.
    /// - Parameters:
    ///   - session: The completed SessionHistory record.
    ///   - completion: Called on the main thread with success/failure.
    func writeWorkout(from session: SessionHistory, completion: @escaping (Bool) -> Void = { _ in }) {
        guard HKHealthStore.isHealthDataAvailable() else { completion(false); return }

        let start    = session.startedAt
        let end      = session.completedAt

        // Estimate active energy: 5 kcal per completed set (conservative strength training estimate)
        let totalSets    = session.results.reduce(0) { $0 + $1.completedSets }
        let kcal         = Double(max(1, totalSets)) * 5.0
        let energyUnit   = HKUnit.kilocalorie()
        let energyQty    = HKQuantity(unit: energyUnit, doubleValue: kcal)

        // Build the workout configuration
        let config               = HKWorkoutConfiguration()
        config.activityType      = .traditionalStrengthTraining
        config.locationType      = .unknown

        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())

        builder.beginCollection(withStart: start) { success, error in
            guard success else {
                print("[Setflow] HealthKit beginCollection failed: \(String(describing: error))")
                DispatchQueue.main.async { completion(false) }
                return
            }

            // Add active energy sample
            let energySample = HKQuantitySample(
                type:      HKQuantityType(.activeEnergyBurned),
                quantity:  energyQty,
                start:     start,
                end:       end
            )

            builder.add([energySample]) { _, error in
                if let error { print("[Setflow] HealthKit add sample failed: \(error)") }

                builder.endCollection(withEnd: end) { success, error in
                    guard success else {
                        print("[Setflow] HealthKit endCollection failed: \(String(describing: error))")
                        DispatchQueue.main.async { completion(false) }
                        return
                    }

                    builder.finishWorkout { workout, error in
                        let ok = workout != nil
                        if let error { print("[Setflow] HealthKit finishWorkout failed: \(error)") }
                        else { print("[Setflow] Wrote workout to Health: \(session.routineName), \(Int(kcal)) kcal") }
                        DispatchQueue.main.async { completion(ok) }
                    }
                }
            }
        }
    }
}
