import SwiftUI

struct ProfileView: View {
    var vm: WorkoutViewModel
    @State private var showScheduleEditor = false
    @State private var showExport         = false
    @State private var exportURL: URL?    = nil

    @State private var confirmAction: ResetAction? = nil

    enum ResetAction: Identifiable {
        case history, bodyMetrics, programmes, routinesAndExercises, everything
        var id: Self { self }

        var title: String {
            switch self {
            case .history:               return "Reset Workout History?"
            case .bodyMetrics:           return "Reset Body Metrics?"
            case .programmes:            return "Reset Programmes?"
            case .routinesAndExercises:  return "Reset Routines & Exercises?"
            case .everything:            return "Reset Everything?"
            }
        }

        var message: String {
            switch self {
            case .history:
                return "This permanently deletes every logged session and resets your streak. This cannot be undone."
            case .bodyMetrics:
                return "This permanently deletes every weight entry you've logged. This cannot be undone."
            case .programmes:
                return "This permanently deletes every programme you've created. This cannot be undone."
            case .routinesAndExercises:
                return "This permanently deletes every routine and exercise you've created. This cannot be undone."
            case .everything:
                return "This erases all Setflow data on this device — history, routines, exercises, programmes, and body metrics — and restarts onboarding. This cannot be undone."
            }
        }

        var buttonLabel: String {
            switch self {
            case .everything: return "Erase Everything"
            default:          return "Reset"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.setflowBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Summary card
                        summaryCard
                            .padding(.horizontal)

                        sectionCard(title: "TRAINING") {
                            NavigationLink { ProgrammesView(vm: vm) } label: {
                                rowLink(icon: "calendar.badge.checkmark", color: .setflowAccent,
                                        title: "Programmes",
                                        subtitle: programmesSubtitle)
                            }
                            .buttonStyle(.plain)
                            Divider().background(Color.primary.opacity(0.07))
                            rowButton(icon: "calendar.badge.checkmark", color: .purple,
                                      title: "Training Schedule",
                                      subtitle: scheduleSubtitle) {
                                showScheduleEditor = true
                            }
                            Divider().background(Color.primary.opacity(0.07))
                            NavigationLink { BodyMetricsView(vm: vm) } label: {
                                rowLink(icon: "scalemass.fill", color: .green,
                                        title: "Body Metrics",
                                        subtitle: bodyMetricsSubtitle)
                            }
                            .buttonStyle(.plain)
                        }

                        // Reminders section
                        sectionCard(title: "REMINDERS") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 9)
                                            .fill(Color.setflowRest.opacity(0.16))
                                            .frame(width: 34, height: 34)
                                        Image(systemName: "bell.badge.fill")
                                            .font(.system(size: 15))
                                            .foregroundColor(.setflowRest)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Daily Nudge")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Text(vm.notificationPref.tone.detail)
                                            .font(.caption)
                                            .foregroundColor(.primary.opacity(0.5))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer()
                                }

                                Picker("", selection: Binding(
                                    get: { vm.notificationPref.tone },
                                    set: { vm.updateNotificationTone($0) }
                                )) {
                                    ForEach(NotificationTone.allCases) { tone in
                                        Text(tone.label).tag(tone)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding(.vertical, 4)
                        }

                        // Data section
                        sectionCard(title: "DATA") {
                            rowButton(icon: "square.and.arrow.up", color: .green,
                                      title: "Export History",
                                      subtitle: "Download all sessions as CSV") {
                                if let url = ShareManager.csvFileURL(sessions: vm.sessionHistory) {
                                    exportURL = url
                                    showExport = true
                                }
                            }
                            Divider().background(Color.primary.opacity(0.07))
                            rowInfo(icon: "chart.bar.fill", color: .purple,
                                    title: "Total Sessions",
                                    value: "\(vm.totalWorkouts)")
                            Divider().background(Color.primary.opacity(0.07))
                            rowInfo(icon: "scalemass.fill", color: .blue,
                                    title: "Total Volume",
                                    value: volStr(vm.totalVolumeLifted))
                        }

                        // App info
                        sectionCard(title: "APP") {
                            rowInfo(icon: "info.circle.fill", color: .primary.opacity(0.4),
                                    title: "Version", value: appVersion)
                            Divider().background(Color.primary.opacity(0.07))
                            rowInfo(icon: "swift", color: .orange,
                                    title: "Built with SwiftUI", value: "iOS 17+")
                        }

                        // Danger zone
                        dangerZoneCard
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showScheduleEditor) {
                ScheduleEditorView(vm: vm)
            }
            .sheet(isPresented: $showExport) {
                if let url = exportURL { ShareSheet(items: [url]) }
            }
            .confirmationDialog(
                confirmAction?.title ?? "",
                isPresented: Binding(get: { confirmAction != nil }, set: { if !$0 { confirmAction = nil } }),
                titleVisibility: .visible
            ) {
                if let action = confirmAction {
                    Button(action.buttonLabel, role: .destructive) {
                        performReset(action)
                    }
                    Button("Cancel", role: .cancel) {}
                }
            } message: {
                Text(confirmAction?.message ?? "")
            }
        }
    }

    // MARK: - Danger Zone

    private var dangerZoneCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("DANGER ZONE")
                .font(.caption.weight(.semibold))
                .foregroundColor(.red.opacity(0.7))
                .tracking(1)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

            dangerRow(title: "Reset Workout History", subtitle: "Deletes all logged sessions and streak") {
                confirmAction = .history
            }
            Divider().background(Color.primary.opacity(0.07))
            dangerRow(title: "Reset Body Metrics", subtitle: "Deletes all weight entries") {
                confirmAction = .bodyMetrics
            }
            Divider().background(Color.primary.opacity(0.07))
            dangerRow(title: "Reset Programmes", subtitle: "Deletes all programmes") {
                confirmAction = .programmes
            }
            Divider().background(Color.primary.opacity(0.07))
            dangerRow(title: "Reset Routines & Exercises", subtitle: "Deletes all routines and exercises") {
                confirmAction = .routinesAndExercises
            }
            Divider().background(Color.primary.opacity(0.07))
            dangerRow(title: "Erase Everything", subtitle: "Full factory reset of Setflow on this device", isSevere: true) {
                confirmAction = .everything
            }
            .padding(.bottom, 4)
        }
        .background(Color.red.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.red.opacity(0.15), lineWidth: 1))
    }

    private func dangerRow(title: String, subtitle: String, isSevere: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(isSevere ? 0.22 : 0.14)).frame(width: 36, height: 36)
                    Image(systemName: isSevere ? "exclamationmark.triangle.fill" : "trash")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.red.opacity(0.85))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundColor(.red.opacity(0.9))
                    Text(subtitle).font(.caption).foregroundColor(.primary.opacity(0.4))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.25))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func performReset(_ action: ResetAction) {
        switch action {
        case .history:              vm.resetWorkoutHistory()
        case .bodyMetrics:          vm.resetBodyMetrics()
        case .programmes:           vm.resetProgrammes()
        case .routinesAndExercises: vm.resetRoutinesAndExercises()
        case .everything:           vm.resetEverything()
        }
        Haptics.light()
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        HStack(spacing: 0) {
            statCell("🔥", "\(vm.currentStreak)", "Streak")
            Rectangle().fill(Color.primary.opacity(0.08)).frame(width: 1, height: 44)
            statCell("🏋️", "\(vm.totalWorkouts)", "Sessions")
            Rectangle().fill(Color.primary.opacity(0.08)).frame(width: 1, height: 44)
            statCell("⚡️", "\(vm.longestStreak)", "Best Streak")
        }
        .padding(.vertical, 16)
        .setflowCard()
    }

    private func statCell(_ emoji: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(emoji).font(.title3)
            Text(value).font(.headline.bold()).foregroundColor(.primary)
            Text(label).font(.caption2).foregroundColor(.primary.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Section Card

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary.opacity(0.4))
                .tracking(1)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

            content()
                .padding(.bottom, 4)
        }
        .padding(.horizontal)
        .background(Color.cardPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cardBorder, lineWidth: 1))
        .padding(.horizontal)
    }

    private func rowButton(icon: String, color: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.18)).frame(width: 36, height: 36)
                    Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundColor(.primary)
                    Text(subtitle).font(.caption).foregroundColor(.primary.opacity(0.45))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func rowInfo(icon: String, color: Color, title: String, value: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.18)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(color)
            }
            Text(title).font(.subheadline.weight(.semibold)).foregroundColor(.primary)
            Spacer()
            Text(value).font(.subheadline).foregroundColor(.primary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func rowLink(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.18)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundColor(.primary)
                Text(subtitle).font(.caption).foregroundColor(.primary.opacity(0.45))
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var programmesSubtitle: String {
        if let active = vm.activeProgramme {
            return "Active: \(active.name)"
        }
        return vm.programmes.isEmpty ? "No programmes yet" : "\(vm.programmes.count) programme\(vm.programmes.count == 1 ? "" : "s")"
    }

    private var bodyMetricsSubtitle: String {
        if let w = vm.latestWeight {
            return "Latest: \(w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)) kg"
        }
        return "Track your body weight"
    }

    private var scheduleSubtitle: String {
        let s = vm.trainingSchedule
        guard s.isEnabled, !s.scheduledWeekdays.isEmpty else { return "Every day (tap to customise)" }
        let names = s.scheduledWeekdays.sorted().compactMap { day in
            TrainingSchedule.weekdayLabels.first(where: { $0.0 == day })?.1
        }
        return names.joined(separator: ", ")
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func volStr(_ vol: Double) -> String {
        if vol == 0 { return "—" }
        if vol >= 1000 { return String(format: "%.1fk kg", vol / 1000) }
        return String(format: "%.0f kg", vol)
    }
}
