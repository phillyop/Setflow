import SwiftUI

// MARK: - Session Share Card

@MainActor
struct SessionShareCard: View {
    let summary: SessionSummary

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.12),
                         Color(red: 0.08, green: 0.08, blue: 0.18)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            VStack(spacing: 18) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SETFLOW")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.blue.opacity(0.8))
                            .tracking(3)
                        Text(summary.routineName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.18))
                            .frame(width: 48, height: 48)
                        Image(systemName: summary.wasCompleted ? "trophy.fill" : "flag.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(summary.wasCompleted ? .yellow : .orange)
                    }
                }

                // Stats row
                HStack(spacing: 0) {
                    statCell(value: summary.durationText, label: "Duration")
                    Divider().background(Color.white.opacity(0.12)).frame(height: 32)
                    statCell(value: "\(summary.totalSets)", label: "Sets")
                    Divider().background(Color.white.opacity(0.12)).frame(height: 32)
                    statCell(value: "\(summary.totalReps)", label: "Reps")
                    if summary.streak > 0 {
                        Divider().background(Color.white.opacity(0.12)).frame(height: 32)
                        statCell(value: "🔥 \(summary.streak)", label: "Streak")
                    }
                }
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Exercise list
                VStack(spacing: 5) {
                    ForEach(summary.results.prefix(5)) { result in
                        HStack {
                            Circle()
                                .fill(result.completedSets >= result.sets
                                      ? Color.blue : Color.white.opacity(0.2))
                                .frame(width: 5, height: 5)
                            Text(result.exerciseName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                            Spacer()
                            Text("\(result.completedSets)×\(result.reps)")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.45))
                            if result.totalVolume > 0 {
                                Text("· \(volStr(result.totalVolume))")
                                    .font(.system(size: 11))
                                    .foregroundColor(.blue.opacity(0.7))
                            }
                        }
                    }
                }

                // Footer
                HStack {
                    Text(Date().formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2).foregroundColor(.white.opacity(0.3))
                    Spacer()
                    Text("setflow.app")
                        .font(.caption2).foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(22)
        }
        .frame(width: 370, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text(label).font(.caption2).foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    private func volStr(_ vol: Double) -> String {
        vol >= 1000 ? String(format: "%.1fk kg", vol / 1000) : String(format: "%.0f kg", vol)
    }
}

// MARK: - Share Manager

enum ShareManager {

    @MainActor
    static func shareImage(for summary: SessionSummary) -> UIImage? {
        let renderer = ImageRenderer(content: SessionShareCard(summary: summary))
        renderer.scale = 3.0
        return renderer.uiImage
    }

    static func csvExport(sessions: [SessionHistory]) -> String {
        var lines = ["Date,Routine,Exercise,Set,Reps,Weight(kg),Volume(kg·reps),Warmup,Completed"]
        let fmt   = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm"

        for session in sessions.sorted(by: { $0.completedAt > $1.completedAt }) {
            let date    = fmt.string(from: session.completedAt)
            let routine = session.routineName.replacingOccurrences(of: ",", with: ";")
            let done    = session.wasCompleted ? "Yes" : "Partial"

            for result in session.results {
                let ex = result.exerciseName.replacingOccurrences(of: ",", with: ";")
                if result.setLogs.isEmpty {
                    lines.append("\(date),\(routine),\(ex),,\(result.reps),,,No,\(done)")
                } else {
                    for log in result.setLogs {
                        let w      = log.weight.map { String(format: "%.1f", $0) } ?? ""
                        let vol    = log.weight.map { String(format: "%.1f", $0 * Double(log.reps)) } ?? ""
                        let warmup = log.isWarmup ? "Yes" : "No"
                        lines.append("\(date),\(routine),\(ex),\(log.setNumber),\(log.reps),\(w),\(vol),\(warmup),\(done)")
                    }
                }
            }
        }
        return lines.joined(separator: "\n")
    }

    static func csvFileURL(sessions: [SessionHistory]) -> URL? {
        let csv      = csvExport(sessions: sessions)
        let filename = "setflow-export-\(Date().formatted(.iso8601.year().month().day())).csv"
        let url      = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
