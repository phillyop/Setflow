import SwiftUI

struct ProgressTabView: View {
    var vm: WorkoutViewModel
    @State private var selectedSegment: ProgressSegment = .overview

    enum ProgressSegment: String, CaseIterable {
        case overview  = "Overview"
        case exercises = "Exercises"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.setflowBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segment picker
                    segmentPicker
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    // Content
                    switch selectedSegment {
                    case .overview:  StatsContent(vm: vm)
                    case .exercises: ExercisesContent(vm: vm)
                    }
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedSegment == .overview {
                        Button {
                            if let url = ShareManager.csvFileURL(sessions: vm.sessionHistory) {
                                exportURL = url
                                showExport = true
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Export history as CSV")
                        .disabled(vm.sessionHistory.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showExport) {
                if let url = exportURL { ShareSheet(items: [url]) }
            }
        }
    }

    @State private var showExport  = false
    @State private var exportURL: URL? = nil

    private var segmentPicker: some View {
        HStack(spacing: 0) {
            ForEach(ProgressSegment.allCases, id: \.self) { seg in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedSegment = seg }
                    Haptics.selection()
                } label: {
                    Text(seg.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(selectedSegment == seg ? .white : .primary.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            selectedSegment == seg
                            ? RoundedRectangle(cornerRadius: 10).fill(Color.setflowAccent)
                            : RoundedRectangle(cornerRadius: 10).fill(Color.clear)
                        )
                        .padding(3)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Overview (was StatsView content)

private struct StatsContent: View {
    var vm: WorkoutViewModel

    var body: some View {
        if vm.sessionHistory.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    heroStrip.padding(.horizontal)
                    consistencyCard.padding(.horizontal)
                    volumeCard.padding(.horizontal)
                    activityChart.padding(.horizontal)
                    if !vm.sessionsByRoutine.isEmpty { routineBreakdown.padding(.horizontal) }
                    if let best = vm.bestWeek { bestWeekCard(best).padding(.horizontal) }
                }
                .padding(.vertical, 16)
            }
        }
    }

    // Hero strip
    private var heroStrip: some View {
        HStack(spacing: 0) {
            heroCell("\(vm.currentStreak)", "Streak", "flame.fill", .orange)
            heroDivider
            heroCell("\(vm.longestStreak)", "Best", "bolt.fill", .yellow)
            heroDivider
            heroCell("\(vm.totalWorkouts)", "Sessions", "checkmark.circle.fill", .setflowAccent)
        }
        .padding(.vertical, 18)
        .setflowCard()
    }

    private func heroCell(_ value: String, _ label: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
            Text(value).font(.system(.title2, design: .rounded).bold()).foregroundColor(.primary)
            Text(label).font(.caption).foregroundColor(.primary.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    private var heroDivider: some View {
        Rectangle().fill(Color.primary.opacity(0.08)).frame(width: 1, height: 50)
    }

    // Consistency ring
    private var consistencyCard: some View {
        let score = vm.consistencyScore
        let pct   = Int(score * 100)
        let ringColor: Color = score >= 0.8 ? .setflowSuccess : score >= 0.5 ? .setflowRest : .red

        return HStack(spacing: 20) {
            ZStack {
                Circle().stroke(Color.primary.opacity(0.1), lineWidth: 10)
                Circle().trim(from: 0, to: score)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: score)
                VStack(spacing: 2) {
                    Text("\(pct)%").font(.system(.title3, design: .rounded).bold()).foregroundColor(.primary)
                    Text("done").font(.caption2.weight(.medium)).foregroundColor(.primary.opacity(0.45))
                }
                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            }
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 6) {
                Text("Consistency").font(.headline).foregroundColor(.primary)
                Text(consistencyMsg(score)).font(.subheadline).foregroundColor(.primary.opacity(0.6))
                Text("Last 30 days").font(.caption2).foregroundColor(.primary.opacity(0.35))
            }
            Spacer()
        }
        .padding(18)
        .setflowCard()
    }

    private func consistencyMsg(_ s: Double) -> String {
        switch s {
        case 0.9...: return "Outstanding. You're crushing it."
        case 0.75...: return "Great consistency. Keep it up."
        case 0.5...: return "Good effort. Push for more days."
        default: return "Let's build that habit."
        }
    }

    // Volume card
    private var volumeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Total Volume", systemImage: "scalemass.fill").font(.headline).foregroundColor(.primary)
                Spacer()
                Text("kg·reps").font(.caption2).foregroundColor(.primary.opacity(0.3))
            }
            if vm.totalVolumeLifted > 0 {
                HStack(spacing: 0) {
                    volCell(volStr(vm.volumeThisWeek), "This Week")
                    Rectangle().fill(Color.primary.opacity(0.08)).frame(width: 1, height: 36)
                    volCell(volStr(vm.volumeThisMonth), "This Month")
                    Rectangle().fill(Color.primary.opacity(0.08)).frame(width: 1, height: 36)
                    volCell(volStr(vm.totalVolumeLifted), "All Time")
                }
            } else {
                Text("Log weighted sets to track volume.")
                    .font(.subheadline).foregroundColor(.primary.opacity(0.4)).padding(.vertical, 8)
            }
        }
        .padding(18)
        .setflowCard()
    }

    private func volCell(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(.title3, design: .rounded).bold()).foregroundColor(.primary)
            Text(label).font(.caption2).foregroundColor(.primary.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private func volStr(_ vol: Double) -> String {
        if vol == 0 { return "—" }
        if vol >= 1_000_000 { return String(format: "%.1fM", vol / 1_000_000) }
        if vol >= 1000 { return String(format: "%.1fk", vol / 1000) }
        return String(format: "%.0f", vol)
    }

    // Activity grid
    private var activityChart: some View {
        let data     = vm.dailySessionCounts(days: 28)
        let maxCount = max(data.map(\.count).max() ?? 1, 1)
        let cal      = Calendar.current

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("ACTIVITY").font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.4)).tracking(1)
                Spacer()
                Text("Last 28 days").font(.caption2).foregroundColor(.primary.opacity(0.3))
            }

            VStack(spacing: 6) {
                ForEach(0..<4) { week in
                    HStack(spacing: 6) {
                        ForEach(0..<7) { day in
                            let idx    = week * 7 + day
                            let entry  = data[idx]
                            let isToday = cal.isDateInToday(entry.date)
                            let intensity = entry.count > 0 ? min(1.0, Double(entry.count) / Double(maxCount)) : 0.0

                            RoundedRectangle(cornerRadius: 5)
                                .fill(entry.count > 0
                                      ? Color.setflowAccent.opacity(0.3 + intensity * 0.7)
                                      : Color.primary.opacity(0.06))
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(isToday
                                         ? RoundedRectangle(cornerRadius: 5).stroke(Color.primary.opacity(0.6), lineWidth: 1.5)
                                         : nil)
                        }
                    }
                }
            }

            HStack(spacing: 6) {
                ForEach(Array(["M","T","W","T","F","S","S"].enumerated()), id: \.offset) { _, d in
                    Text(d).font(.caption2.weight(.medium)).foregroundColor(.primary.opacity(0.25)).frame(maxWidth: .infinity)
                }
            }
        }
        .padding(18)
        .setflowCard()
    }

    // Routine breakdown
    private var routineBreakdown: some View {
        let routines = vm.sessionsByRoutine
        let maxCount = routines.first?.count ?? 1

        return VStack(alignment: .leading, spacing: 14) {
            Text("ROUTINES").font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.4)).tracking(1)
            VStack(spacing: 10) {
                ForEach(routines.prefix(5), id: \.routineName) { item in
                    HStack(spacing: 12) {
                        Text(item.routineName)
                            .font(.subheadline.weight(.semibold)).foregroundColor(.primary)
                            .lineLimit(1).frame(width: 120, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.07)).frame(height: 8)
                                RoundedRectangle(cornerRadius: 4).fill(Color.setflowAccent)
                                    .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(maxCount), height: 8)
                                    .animation(.easeOut(duration: 0.5), value: item.count)
                            }
                        }
                        .frame(height: 8)
                        Text("\(item.count)").font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.5)).frame(width: 24, alignment: .trailing)
                    }
                }
            }
        }
        .padding(18)
        .setflowCard()
    }

    // Best week
    private func bestWeekCard(_ best: (start: Date, count: Int)) -> some View {
        let cal = Calendar.current
        let end = cal.date(byAdding: .day, value: 6, to: best.start)!
        let f   = DateFormatter(); f.dateFormat = "MMM d"
        let range = "\(f.string(from: best.start)) – \(f.string(from: end))"

        return HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Color.yellow.opacity(0.15)).frame(width: 52, height: 52)
                Image(systemName: "trophy.fill").font(.title2).foregroundColor(.yellow)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Best Week").font(.subheadline).foregroundColor(.primary.opacity(0.55))
                Text("\(best.count) session\(best.count == 1 ? "" : "s")").font(.title3.bold()).foregroundColor(.primary)
                Text(range).font(.caption).foregroundColor(.primary.opacity(0.4))
            }
            Spacer()
        }
        .padding(16)
        .setflowCard()
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Color.setflowAccent.opacity(0.12)).frame(width: 88, height: 88)
                Image(systemName: "chart.bar.fill").font(.system(size: 32, weight: .semibold)).foregroundColor(.setflowAccent)
            }
            VStack(spacing: 8) {
                Text("No Stats Yet").font(.title3.bold()).foregroundColor(.primary)
                Text("Complete sessions to see your stats here.").font(.subheadline).foregroundColor(.primary.opacity(0.6)).multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Exercises (was ProgressView content)

private struct ExercisesContent: View {
    var vm: WorkoutViewModel
    @State private var selectedExercise: String = ""

    var body: some View {
        if vm.trackedExerciseNames.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    exercisePicker.padding(.horizontal)
                    if !selectedExercise.isEmpty {
                        exerciseDetail(for: selectedExercise)
                    }
                }
                .padding(.vertical, 16)
            }
            .onAppear {
                if selectedExercise.isEmpty, let first = vm.trackedExerciseNames.first {
                    selectedExercise = first
                }
            }
        }
    }

    private var exercisePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.trackedExerciseNames, id: \.self) { name in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedExercise = name }
                    } label: {
                        Text(name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(selectedExercise == name ? .white : .primary.opacity(0.5))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(selectedExercise == name ? Color.setflowAccent : Color.primary.opacity(0.07))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func exerciseDetail(for name: String) -> some View {
        let weeklyData = vm.weeklyVolume(for: name)
        let pb         = vm.personalBest(for: name)
        let recent     = vm.recentSetLogs(for: name, limit: 5)
        let count      = vm.sessionCount(for: name)

        VStack(spacing: 20) {
            if let pb { pbCard(pb, count: count).padding(.horizontal) }
            if weeklyData.contains(where: { $0.volume > 0 }) { volumeChart(data: weeklyData).padding(.horizontal) }
            if !recent.isEmpty { recentSetsCard(recent).padding(.horizontal) }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.easeInOut(duration: 0.25), value: selectedExercise)
    }

    private func pbCard(_ pb: PersonalBest, count: Int) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 6) {
                Image(systemName: "trophy.fill").font(.title2).foregroundColor(.yellow)
                Text("Personal Best").font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.45))
                Text(pb.displayString).font(.title3.bold()).foregroundColor(.primary).multilineTextAlignment(.center)
                Text(pb.date.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundColor(.primary.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
            Rectangle().fill(Color.primary.opacity(0.08)).frame(width: 1, height: 60)
            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").font(.title2).foregroundColor(.setflowAccent)
                Text("Sessions").font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.45))
                Text("\(count)").font(.title3.bold()).foregroundColor(.primary)
                Text("total").font(.caption2).foregroundColor(.primary.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .setflowCard()
    }

    private func volumeChart(data: [WeeklyVolume]) -> some View {
        let maxVol     = data.map(\.volume).max() ?? 1
        let isWeighted = data.first?.isWeighted ?? false

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("WEEKLY VOLUME").font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.4)).tracking(1)
                Spacer()
                Text(isWeighted ? "kg·reps" : "reps").font(.caption2).foregroundColor(.primary.opacity(0.3))
            }
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(data) { week in
                    VStack(spacing: 6) {
                        if week.volume > 0 {
                            Text(week.volume >= 1000 ? String(format: "%.1fk", week.volume/1000) : String(format: "%.0f", week.volume))
                                .font(.caption2.weight(.semibold)).foregroundColor(.primary.opacity(0.55)).lineLimit(1).minimumScaleFactor(0.7)
                        }
                        RoundedRectangle(cornerRadius: 5)
                            .fill(week.volume > 0
                                  ? LinearGradient(colors: [.setflowAccent, .setflowAccent.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                                  : LinearGradient(colors: [Color.primary.opacity(0.08), Color.primary.opacity(0.08)], startPoint: .top, endPoint: .bottom))
                            .frame(height: week.volume > 0 ? max(8, CGFloat(week.volume / maxVol) * 100) : 8)
                            .animation(.easeOut(duration: 0.4), value: week.volume)
                        Text(week.label).font(.caption2.weight(.medium)).foregroundColor(.primary.opacity(0.35)).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
        }
        .padding(16)
        .setflowCard()
    }

    private func recentSetsCard(_ recent: [(log: SetLog, date: Date, sessionName: String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT SETS").font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.4)).tracking(1)
            VStack(spacing: 0) {
                ForEach(Array(recent.enumerated()), id: \.offset) { index, entry in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(entry.log.isWarmup ? Color.setflowRest.opacity(0.18) : Color.setflowAccent.opacity(0.15))
                                .frame(width: 30, height: 30)
                            Text("\(entry.log.setNumber)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(entry.log.isWarmup ? .setflowRest : .setflowAccent)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                if let w = entry.log.weight {
                                    Text(w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))kg" : String(format: "%.1fkg", w))
                                        .font(.subheadline.weight(.semibold)).foregroundColor(.primary)
                                }
                                Text("\(entry.log.reps) reps")
                                    .font(.subheadline.weight(entry.log.weight == nil ? .semibold : .regular))
                                    .foregroundColor(entry.log.weight == nil ? .primary : .primary.opacity(0.7))
                                if entry.log.isWarmup {
                                    Text("WARM-UP")
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(.setflowRest)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Color.setflowRest.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                            Text(entry.sessionName).font(.caption).foregroundColor(.primary.opacity(0.35))
                        }
                        Spacer()
                        Text(entry.date.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundColor(.primary.opacity(0.35))
                    }
                    .padding(.vertical, 10)
                    if index < recent.count - 1 { Divider().background(Color.primary.opacity(0.06)) }
                }
            }
        }
        .padding(16)
        .setflowCard()
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Color.setflowAccent.opacity(0.12)).frame(width: 88, height: 88)
                Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 32, weight: .semibold)).foregroundColor(.setflowAccent)
            }
            VStack(spacing: 8) {
                Text("No Data Yet").font(.title3.bold()).foregroundColor(.primary)
                Text("Complete a session to start tracking your progress.").font(.subheadline).foregroundColor(.primary.opacity(0.6)).multilineTextAlignment(.center).padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
