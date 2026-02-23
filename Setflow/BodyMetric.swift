import Foundation
import SwiftData

@Model
final class BodyMetric {
    // Defaults required for CloudKit compatibility (see note on Exercise).
    var id: UUID = UUID()
    var date: Date = Date()
    var weightKg: Double = 0
    var notes: String = ""

    init(id: UUID = UUID(), date: Date = Date(), weightKg: Double, notes: String = "") {
        self.id       = id
        self.date     = date
        self.weightKg = weightKg
        self.notes    = notes
    }
}
