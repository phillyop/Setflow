import SwiftUI

struct StatsView: View {
    var vm: WorkoutViewModel
    @State private var showExportSheet = false
    @State private var csvURL: URL? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if vm.sessionHistory.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        heroStrip
                            .padding(.horizontal)

                        consistencyCard
                            .padding(.horizontal)

                        volumeCard
                            .padding(.horizontal)

                        activityChart
                            .padding(.horizontal)

                        if !vm.sessionsByRoutine.isEmpty {
                            routineBreakdown
                                .padding(.horizontal)
                        }

                        if let best = vm.bestWeek {
                            bestWeekCard(best)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if let url = ShareManager.csvFileURL(sessions: vm.sessionHistory) {
                        csvURL = url
                        showExportSheet = true
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(vm.sessionHistory.isEmpty)
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = csvURL { ShareSheet(items: [url]) }
        }
    }

    // MARK: - Hero Strip

    private var heroStrip: some View {
        HStack(spacing: 0) {
            heroCell(value: "\(vm.currentStreak)",  label: "Streak",   icon: "flame.fill",  color: .orange)
            heroDivider
            heroCell(value: "\(vm.longestStreak)",  label: "Best",     icon: "bolt.fill",   color: .yellow)
            heroDivider
            heroCell(value: "\(vm.totalWorkouts)",  label: "Sessions", icon: "checkmark.circle.fill", color: .blue)
        }
        .padding(.vertical, 18)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func heroCell(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    private var heroDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 50)
    }

    // MARK: - Consistency Card

    private var consistencyCard: some View {
        let score      = vm.consistencyScore
        let pct        = Int(score * 100)
        let ringColor  = score >= 0.8 ? Color.green : score >= 0.5 ? Color.orange : Color.red

        return HStack(spacing: 20) {
            // Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: score)
                    .stroke(ringColor,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: score)

                VStack(spacing: 2) {
                    Text("\(pct)%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("done")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 6) {
                Text("Consistency")
                    .font(.headline)
                    .foregroundColor(.white)

                Text(consistencyMessage(score))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)

                Text("Last 30 days")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.35))
            }

            Spacer()
        }
        .padding(18)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func consistencyMessage(_ score: Double) -> String {
        switch score {
        case 0.9...: return "Outstanding! You're crushing it."
        case 0.75...: return "Great consistency. Keep it up."
        case 0.5...: return "Good effort. Push for more days."
        case 0.25...: return "Room to grow. Small steps count."
        default: return "Let's build that habit."
        }
    }

    // MARK: - Volume Card

    private var volumeCard: some View {
        let hasVolume = vm.totalVolumeLifted > 0

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Total Volume", systemImage: "scalemass.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("kg · reps")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.3))
            }

            if hasVolume {
                HStack(spacing: 0) {
                    volumeCell(value: volumeString(vm.volumeThisWeek), label: "This Week")
                    volumeDivider
                    volumeCell(value: volumeString(vm.volumeThisMonth), label: "This Month")
                    volumeDivider
                    volumeCell(value: volumeString(vm.totalVolumeLifted), label: "All Time")
                }
            } else {
                Text("Log weighted sets to track volume.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.vertical, 8)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func volumeCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private var volumeDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 36)
    }

    private func volumeString(_ vol: Double) -> String {
        if vol == 0 { return "—" }
        if vol >= 1_000_000 { return String(format: "%.1fM", vol / 1_000_000) }
        if vol >= 1000      { return String(format: "%.1fk", vol / 1000) }
        return String(format: "%.0f", vol)
    }

    // MARK: - Activity Chart (28 days)

    private var activityChart: some View {
        let data    = vm.dailySessionCounts(days: 28)
        let maxCount = max(data.map(\.count).max() ?? 1, 1)
        let cal     = Calendar.current

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("ACTIVITY")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)
                Spacer()
                Text("Last 28 days")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.3))
            }

            // 4 rows of 7 (week rows)
            VStack(spacing: 6) {
                ForEach(0..<4) { week in
                    HStack(spacing: 6) {
                        ForEach(0..<7) { day in
                            let index = week * 7 + day
                            let entry = data[index]
                            let isToday = cal.isDateInToday(entry.date)
                            let hasSession = entry.count > 0
                            let intensity = hasSession
                                ? min(1.0, Double(entry.count) / Double(maxCount))
                                : 0.0

                            RoundedRectangle(cornerRadius: 5)
                                .fill(hasSession
                                      ? Color.blue.opacity(0.3 + intensity * 0.7)
                                      : Color.white.opacity(0.06))
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    isToday
                                    ? RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                                    : nil
                                )
                        }
                    }
                }
            }

            // Day labels
            HStack(spacing: 6) {
                ForEach(["M","T","W","T","F","S","S"], id: \.self) { d in
                    Text(d)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.25))
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Routine Breakdown

    private var routineBreakdown: some View {
        let routines = vm.sessionsByRoutine
        let maxCount = routines.first?.count ?? 1

        return VStack(alignment: .leading, spacing: 14) {
            Text("ROUTINES")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1)

            VStack(spacing: 10) {
                ForEach(routines.prefix(5), id: \.routineName) { item in
                    HStack(spacing: 12) {
                        Text(item.routineName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(width: 120, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.07))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue)
                                    .frame(
                                        width: geo.size.width * CGFloat(item.count) / CGFloat(maxCount),
                                        height: 8
                                    )
                                    .animation(.easeOut(duration: 0.5), value: item.count)
                            }
                        }
                        .frame(height: 8)

                        Text("\(item.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 24, alignment: .trailing)
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Best Week

    private func bestWeekCard(_ best: (start: Date, count: Int)) -> some View {
        let cal = Calendar.current
        let end = cal.date(byAdding: .day, value: 6, to: best.start)!
        let f   = DateFormatter()
        f.dateFormat = "MMM d"
        let range = "\(f.string(from: best.start)) – \(f.string(from: end))"

        return HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Best Week")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.55))
                Text("\(best.count) session\(best.count == 1 ? "" : "s")")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Text(range)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Color.blue.opacity(0.12)).frame(width: 88, height: 88)
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.blue)
            }
            VStack(spacing: 8) {
                Text("No Stats Yet")
                    .font(.title3.bold()).foregroundColor(.white)
                Text("Complete sessions to see your stats here.")
                    .font(.subheadline).foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
