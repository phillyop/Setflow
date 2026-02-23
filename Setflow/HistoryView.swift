import SwiftUI

struct HistoryView: View {
    var vm: WorkoutViewModel
    @State private var selectedSession: SessionHistory? = nil
    @State private var undoAction = UndoAction()

    // Group sessions by calendar day, newest first
    private var groupedSessions: [(label: String, sessions: [SessionHistory])] {
        let cal = Calendar.current

        let sorted = vm.sessionHistory.sorted { $0.completedAt > $1.completedAt }
        let grouped = Dictionary(grouping: sorted) {
            cal.startOfDay(for: $0.completedAt)
        }

        return grouped.keys.sorted(by: >).map { day in
            let label: String
            if cal.isDateInToday(day)          { label = "Today" }
            else if cal.isDateInYesterday(day) { label = "Yesterday" }
            else {
                let f = DateFormatter()
                f.dateFormat = "EEE d MMM"
                label = f.string(from: day)
            }
            return (label: label, sessions: grouped[day]!.sorted { $0.completedAt > $1.completedAt })
        }
    }

    var body: some View {
        ZStack {
            Color.setflowBg.ignoresSafeArea()

            if vm.sessionHistory.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(groupedSessions, id: \.label) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(group.label)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary.opacity(0.45))
                                    .padding(.horizontal)

                                VStack(spacing: 10) {
                                    ForEach(group.sessions) { session in
                                        sessionCard(session)
                                            .padding(.horizontal)
                                            .onTapGesture { selectedSession = session }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button(role: .destructive) {
                                                    deleteSession(session)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .undoToast(undoAction)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSession) { session in
            SessionDetailSheet(vm: vm, session: session)
        }
    }

    private func deleteSession(_ session: SessionHistory) {
        undoAction.show(
            message: "Session deleted",
            onUndo: { vm.fetchSessionHistory() },
            onCommit: { vm.deleteSession(session) }
        )
        // Remove from UI immediately for snappy feel
        vm.sessionHistory.removeAll { $0.id == session.id }
    }

    // MARK: - Session Card

    private func sessionCard(_ session: SessionHistory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row
            HStack(spacing: 10) {
                // Routine icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(session.wasCompleted ? Color.blue.opacity(0.18) : Color.orange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: session.wasCompleted
                          ? "figure.strengthtraining.traditional"
                          : "flag.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(session.wasCompleted ? .blue : .orange)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.routineName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Label(durationText(session.durationSeconds), systemImage: "clock")
                        Label("\(session.totalSets) sets", systemImage: "list.bullet")
                    }
                    .font(.caption)
                    .foregroundColor(.primary.opacity(0.5))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    completionBadge(session.wasCompleted)

                    Text(session.completedAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.primary.opacity(0.35))
                }
            }

            // Exercise strip
            if !session.results.isEmpty {
                exerciseStrip(session.results)
            }

            // Volume line for weighted sessions
            let totalVol = session.results.reduce(0.0) { $0 + $1.totalVolume }
            if totalVol > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "scalemass.fill")
                        .font(.caption2)
                        .foregroundColor(.primary.opacity(0.35))
                    Text(volumeText(totalVol))
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.45))
                    Text("total volume")
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.3))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardPrimary)
                .overlay(RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.cardBorder, lineWidth: 1))
        )
    }

    private func completionBadge(_ completed: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: completed ? "checkmark.circle.fill" : "minus.circle.fill")
                .font(.caption)
            Text(completed ? "Complete" : "Partial")
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(completed ? .green : .orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((completed ? Color.green : Color.orange).opacity(0.12))
        .clipShape(Capsule())
    }

    private func exerciseStrip(_ results: [SessionExerciseResult]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(results) { result in
                    Text(result.exerciseName)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.primary.opacity(0.65))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.07))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Color.setflowAccent.opacity(0.12)).frame(width: 88, height: 88)
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.setflowAccent)
            }
            VStack(spacing: 8) {
                Text("No Sessions Yet")
                    .font(.title3.bold()).foregroundColor(.primary)
                Text("Complete a routine to see your history here.")
                    .font(.subheadline).foregroundColor(.primary.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            Text("Go to Home → tap a routine to start")
                .font(.caption)
                .foregroundColor(.setflowAccent.opacity(0.8))
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(Color.setflowAccent.opacity(0.1))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func durationText(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    private func volumeText(_ vol: Double) -> String {
        vol >= 1000
            ? String(format: "%.1fk kg", vol / 1000)
            : String(format: "%.0f kg", vol)
    }
}

// MARK: - Session Detail Sheet

struct SessionDetailSheet: View {
    var vm: WorkoutViewModel
    let session: SessionHistory
    @Environment(\.dismiss) private var dismiss
    @State private var editingLog: SetLog? = nil
    @State private var editingResultID: UUID? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.setflowBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        sessionHeader

                        ForEach(session.results) { result in
                            exerciseCard(result)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(session.routineName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(item: $editingLog) { log in
                if let resultID = editingResultID {
                    SetLogEditSheet(
                        log: log,
                        hasWeight: session.results
                            .first(where: { $0.id == resultID })?
                            .setLogs.contains(where: { $0.weight != nil }) ?? false
                    ) { updatedLog in
                        vm.updateSetLog(updatedLog, inResult: resultID, ofSession: session)
                        editingLog = nil
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var sessionHeader: some View {
        HStack(spacing: 0) {
            statCell(value: durationText(session.durationSeconds), label: "Duration",
                     icon: "clock.fill", color: .blue)
            divider
            statCell(value: "\(session.totalSets)", label: "Total Sets",
                     icon: "list.bullet", color: .purple)
            divider
            statCell(value: session.wasCompleted ? "Done" : "Partial", label: "Status",
                     icon: session.wasCompleted ? "checkmark.circle.fill" : "minus.circle.fill",
                     color: session.wasCompleted ? .green : .orange)
        }
        .padding(.vertical, 16)
        .background(Color.cardPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func statCell(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(color)
            Text(value).font(.headline.bold()).foregroundColor(.primary)
            Text(label).font(.caption2).foregroundColor(.primary.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle().fill(Color.primary.opacity(0.08)).frame(width: 1, height: 48)
    }

    // MARK: - Exercise Card

    private func exerciseCard(_ result: SessionExerciseResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: result.completedSets >= result.sets ? "checkmark" : "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.exerciseName)
                        .font(.subheadline.weight(.semibold)).foregroundColor(.primary)
                    Text(result.completionSummary)
                        .font(.caption).foregroundColor(.primary.opacity(0.45))
                }
                Spacer()
                if result.totalVolume > 0 {
                    Text(volumeText(result.totalVolume))
                        .font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.5))
                }
            }

            if !result.setLogs.isEmpty {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("SET").frame(width: 24, alignment: .leading)
                        Spacer()
                        if result.setLogs.contains(where: { $0.weight != nil }) {
                            Text("WEIGHT").frame(width: 70, alignment: .trailing)
                        }
                        Text("REPS").frame(width: 50, alignment: .trailing)
                        if result.setLogs.contains(where: { $0.rpe != nil }) {
                            Text("RPE").frame(width: 34, alignment: .trailing)
                        }
                        Text("").frame(width: 28) // edit button placeholder
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.primary.opacity(0.3))
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)

                    ForEach(Array(result.setLogs.enumerated()), id: \.offset) { index, log in
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(log.isWarmup ? Color.setflowRest.opacity(0.18) : Color.blue.opacity(0.15))
                                    .frame(width: 24, height: 24)
                                Text("\(log.setNumber)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(log.isWarmup ? .setflowRest : .blue)
                            }

                            if log.isWarmup {
                                Text("WARM-UP")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(.setflowRest)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.setflowRest.opacity(0.12))
                                    .clipShape(Capsule())
                            } else if result.missedTarget(log) {
                                Text("MISS")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.12))
                                    .clipShape(Capsule())
                            }

                            Spacer()
                            if result.setLogs.contains(where: { $0.weight != nil }) {
                                Text(log.weight.map { w in
                                    w.truncatingRemainder(dividingBy: 1) == 0
                                        ? "\(Int(w)) kg" : String(format: "%.1f kg", w)
                                } ?? "—")
                                .font(.subheadline)
                                .foregroundColor(.primary.opacity(log.weight != nil ? (log.isWarmup ? 0.6 : 0.9) : 0.3))
                                .frame(width: 70, alignment: .trailing)
                            }
                            Text("\(log.reps)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(log.isWarmup ? .primary.opacity(0.6) : .primary)
                                .frame(width: 50, alignment: .trailing)

                            if result.setLogs.contains(where: { $0.rpe != nil }) {
                                Text(log.rpe.map { "\($0)" } ?? "—")
                                    .font(.subheadline)
                                    .foregroundColor(.primary.opacity(log.rpe != nil ? 0.6 : 0.25))
                                    .frame(width: 34, alignment: .trailing)
                            }

                            // Edit button
                            Button {
                                editingResultID = result.id
                                editingLog = log
                            } label: {
                                Image(systemName: "pencil.circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary.opacity(0.25))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Edit set \(log.setNumber)")
                            .frame(width: 28)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            log.isWarmup
                                ? Color.setflowRest.opacity(0.05)
                                : (index % 2 == 0 ? Color.primary.opacity(0.04) : Color.clear)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                vm.deleteSetLog(log, inResult: result.id, ofSession: session)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                editingResultID = result.id
                                editingLog = log
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .background(Color.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(14)
        .background(Color.cardPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.cardBorder, lineWidth: 1))
    }

    // MARK: - Helpers

    private func durationText(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    private func volumeText(_ vol: Double) -> String {
        vol >= 1000 ? String(format: "%.1fk kg", vol / 1000) : String(format: "%.0f kg", vol)
    }
}

// MARK: - Set Log Edit Sheet

struct SetLogEditSheet: View {
    let log: SetLog
    let hasWeight: Bool
    let onSave: (SetLog) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var reps: Int
    @State private var weight: Double
    @State private var isWarmup: Bool
    @State private var rpe: Int?

    init(log: SetLog, hasWeight: Bool, onSave: @escaping (SetLog) -> Void) {
        self.log = log
        self.hasWeight = hasWeight
        self.onSave = onSave
        _reps     = State(initialValue: log.reps)
        _weight   = State(initialValue: log.weight ?? 0)
        _isWarmup = State(initialValue: log.isWarmup)
        _rpe      = State(initialValue: log.rpe)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.setflowBg.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Edit Set \(log.setNumber)")
                        .font(.headline).foregroundColor(.primary)
                        .padding(.top, 20)

                    // Reps
                    VStack(alignment: .leading, spacing: 8) {
                        Text("REPS")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.primary.opacity(0.4)).tracking(1)

                        HStack(spacing: 20) {
                            stepperBtn(icon: "minus", label: "Decrease reps") { reps = max(1, reps - 1) }
                            Text("\(reps)")
                                .font(.system(.largeTitle, design: .rounded).bold())
                                .foregroundColor(.primary).frame(minWidth: 60)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.15), value: reps)
                                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                            stepperBtn(icon: "plus", label: "Increase reps") { reps += 1 }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(16)
                    .background(Color.cardPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Weight (only for weighted exercises)
                    if hasWeight {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("WEIGHT (KG)")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.primary.opacity(0.4)).tracking(1)

                            HStack(spacing: 12) {
                                quickBtn("-5")  { weight = max(0, weight - 5) }
                                quickBtn("-2.5"){ weight = max(0, weight - 2.5) }
                                Spacer()
                                Text(weightStr(weight))
                                    .font(.system(.title, design: .rounded).bold())
                                    .foregroundColor(.primary).frame(minWidth: 80)
                                    .contentTransition(.numericText())
                                    .animation(.easeInOut(duration: 0.15), value: weight)
                                    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                                Spacer()
                                quickBtn("+2.5"){ weight += 2.5 }
                                quickBtn("+5")  { weight += 5 }
                            }
                        }
                        .padding(16)
                        .background(Color.cardPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Warm-up toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("WARM-UP SET")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.primary.opacity(0.4)).tracking(1)
                            Text("Excluded from PRs and volume stats")
                                .font(.caption2)
                                .foregroundColor(.primary.opacity(0.35))
                        }
                        Spacer()
                        Toggle("", isOn: $isWarmup)
                            .labelsHidden()
                            .tint(.setflowRest)
                    }
                    .padding(16)
                    .background(Color.cardPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // RPE (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("RPE")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.primary.opacity(0.4)).tracking(1)
                            Text("optional")
                                .font(.caption2)
                                .foregroundColor(.primary.opacity(0.3))
                            Spacer()
                            if rpe != nil {
                                Button("Clear") { rpe = nil }
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.primary.opacity(0.4))
                                    .buttonStyle(.plain)
                            }
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(1...10, id: \.self) { value in
                                    Button {
                                        rpe = value
                                    } label: {
                                        Text("\(value)")
                                            .font(.subheadline.weight(.bold))
                                            .foregroundColor(rpe == value ? .white : .primary.opacity(0.4))
                                            .frame(width: 36, height: 36)
                                            .background(rpe == value ? Color.blue : Color.primary.opacity(0.06))
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.cardPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Spacer()

                    Button {
                        var updated     = log
                        updated.reps     = reps
                        updated.weight   = hasWeight ? weight : nil
                        updated.isWarmup = isWarmup
                        updated.rpe      = rpe
                        onSave(updated)
                        dismiss()
                    } label: {
                        Text("Save Changes")
                            .font(.headline.weight(.semibold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.blue))
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.primary.opacity(0.7))
                }
            }
        }
        .presentationDetents([.height(hasWeight ? 580 : 460)])
        .presentationCornerRadius(24)
    }

    private func stepperBtn(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold)).foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(Color.primary.opacity(0.1)).clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func quickBtn(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.7))
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(Color.primary.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 8))
        }.buttonStyle(.plain)
    }

    private func weightStr(_ kg: Double) -> String {
        kg.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(kg))kg" : String(format: "%.1fkg", kg)
    }
}
