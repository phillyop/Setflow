import SwiftUI

struct ExerciseListUI: View {
    var vm: WorkoutViewModel
    @State private var selectedTab: HomeTab = .routines
    @State private var showingRoutineEditor = false
    @State private var editingRoutine: WorkoutRoutine?
    @State private var showingExerciseEditor = false
    @State private var editingExercise: Exercise?
    @State private var showScheduleEditor = false
    @State private var undoAction = UndoAction()
    @State private var hasAppeared = false
    @State private var flamePulse = false

    enum HomeTab { case routines, exercises }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.setflowBgGradientTop, Color.setflowBgGradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .appearStagger(index: 0, visible: hasAppeared)

                    if let message = vm.streakBreakMessage {
                        streakBreakBanner(message)
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .appearStagger(index: 1, visible: hasAppeared)
                    }

                    streakStrip
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .appearStagger(index: 2, visible: hasAppeared)

                    if !vm.resumableSessionsToday.isEmpty {
                        resumeStrip
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .appearStagger(index: 3, visible: hasAppeared)
                    }

                    if vm.activeProgramme == nil && !vm.todaysScheduledExercises.isEmpty {
                        todaysPlanCard
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .appearStagger(index: 4, visible: hasAppeared)
                    }

                    if vm.resumableSessionsToday.isEmpty,
                       vm.activeProgramme == nil,
                       vm.todaysScheduledExercises.isEmpty,
                       let repeatRoutine = vm.lastCompletedRoutine {
                        repeatLastWorkoutCard(routine: repeatRoutine)
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .appearStagger(index: 5, visible: hasAppeared)
                    }

                    weeklyStreak
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .appearStagger(index: 6, visible: hasAppeared)

                    if !vm.streakSafeToday {
                        quickWinCard
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .appearStagger(index: 7, visible: hasAppeared)
                    }

                    tabPicker
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .appearStagger(index: 8, visible: hasAppeared)

                    tabContent
                        .padding(.top, 14)
                        .appearStagger(index: 9, visible: hasAppeared)
                }
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            vm.processSiriCommandIfNeeded()
            if !hasAppeared {
                withAnimation { hasAppeared = true }
            }
        }
        .sheet(isPresented: $showingRoutineEditor) {
            RoutineEditorView(vm: vm)
        }
        .sheet(item: $editingRoutine) { routine in
            RoutineEditorView(vm: vm, editingRoutine: routine)
        }
        .sheet(isPresented: $showingExerciseEditor) {
            ExerciseEditorView(vm: vm)
        }
        .sheet(item: $editingExercise) { ex in
            EditExerciseView(vm: vm, exercise: ex)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showScheduleEditor) {
            ScheduleEditorView(vm: vm)
        }
        .undoToast(undoAction)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text(greeting)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.setflowAccent)

                Text(headlinePrompt)
                    .font(.title.bold())
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Late session"
        }
    }

    private var headlinePrompt: String {
        // If a programme has a routine scheduled today, name it.
        if let programme = vm.activeProgramme,
           let today = programme.todayProgrammeDay(), !today.isRestDay {
            return "Ready for \(today.routineName)?"
        }
        if let programme = vm.activeProgramme,
           let today = programme.todayProgrammeDay(), today.isRestDay {
            return "Rest day. Recover well."
        }
        return vm.currentStreak > 0 ? "Keep the streak alive." : "Let's get moving."
    }

    // MARK: - Streak Strip

    private var streakStrip: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                // Animated flame badge
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.orange.opacity(0.35), Color.orange.opacity(0.0)],
                                center: .center, startRadius: 2, endRadius: 40
                            )
                        )
                        .frame(width: 68, height: 68)

                    Circle()
                        .fill(Color.orange.opacity(0.16))
                        .frame(width: 54, height: 54)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.7, blue: 0.2),
                                         Color(red: 1.0, green: 0.42, blue: 0.15)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .scaleEffect(flamePulse ? 1.08 : 0.96)
                        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: flamePulse)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(vm.currentStreak)")
                            .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                            .foregroundColor(.primary)
                            .contentTransition(.numericText())
                        Text(vm.currentStreak == 1 ? "day" : "days")
                            .font(.headline)
                            .foregroundColor(.primary.opacity(0.6))
                    }
                    Text(vm.currentStreak > 0
                         ? "You're on a roll. Keep going."
                         : "Complete a workout today to begin.")
                        .font(.subheadline)
                        .foregroundColor(.primary.opacity(0.6))
                }
                Spacer()
            }

            // Today's programme workout if active
            if let programme = vm.activeProgramme,
               let today = programme.todayProgrammeDay() {
                Divider().background(Color.primary.opacity(0.10))
                HStack(spacing: 10) {
                    Image(systemName: today.isRestDay ? "moon.fill" : "calendar")
                        .font(.caption).foregroundColor(today.isRestDay ? .primary.opacity(0.35) : .setflowAccent)
                    Text(today.isRestDay ? "Rest Day — \(programme.name)" : "Today: \(today.routineName)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(today.isRestDay ? .primary.opacity(0.45) : .primary.opacity(0.9))
                    Spacer()
                    if !today.isRestDay, let routine = vm.routines.first(where: { $0.id == today.routineID }) {
                        Button {
                            vm.startSession(routine: routine)
                        } label: {
                            Text("Start")
                                .font(.caption.weight(.bold)).foregroundColor(.white)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color.setflowAccent)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(light: Color(red: 1.0, green: 0.97, blue: 0.93),
                                           dark:  Color(red: 0.13, green: 0.11, blue: 0.09)),
                                     Color(light: Color(red: 0.98, green: 0.97, blue: 1.0),
                                           dark:  Color(red: 0.09, green: 0.09, blue: 0.13))],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.25), Color.primary.opacity(0.05)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .onAppear { flamePulse = true }
    }

    // MARK: - Today's Plan (no Programme active)

    private var todaysPlanCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.setflowAccent)
                Text("TODAY'S PLAN")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary.opacity(0.5))
                    .tracking(1)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(vm.todaysScheduledExercises, id: \.exercise.id) { item in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(item.doneToday ? Color.setflowSuccess : Color.primary.opacity(0.15))
                            .frame(width: 8, height: 8)

                        Text(item.exercise.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(item.doneToday ? .primary.opacity(0.5) : .primary)
                            .strikethrough(item.doneToday)

                        Spacer()

                        Text(item.time)
                            .font(.caption)
                            .foregroundColor(.primary.opacity(0.4))

                        if item.doneToday {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.setflowSuccess)
                        }
                    }
                }
            }
        }
        .padding()
        .background(cardBackground)
    }

    // MARK: - Resume Strip

    private var resumeStrip: some View {
        VStack(spacing: 10) {
            ForEach(vm.resumableSessionsToday, id: \.id) { session in
                Button {
                    vm.resumeSession(from: session)
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.setflowAccent.opacity(0.18)).frame(width: 40, height: 40)
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.setflowAccent)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Resume \(session.routineName)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                            Text("\(session.totalSets) sets logged so far — pick up where you left off")
                                .font(.caption)
                                .foregroundColor(.primary.opacity(0.55))
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.primary.opacity(0.3))
                    }
                    .padding()
                    .background(cardBackground)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Streak Break Banner

    private func streakBreakBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.setflowRest.opacity(0.18)).frame(width: 40, height: 40)
                Image(systemName: "flame.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.setflowRest)
            }
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    vm.dismissStreakBreakMessage()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.primary.opacity(0.35))
                    .padding(8)
            }
            .accessibilityLabel("Dismiss")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.setflowRest.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.setflowRest.opacity(0.18), lineWidth: 1)
                )
        )
    }

    // MARK: - Repeat Last Workout Card

    private func repeatLastWorkoutCard(routine: WorkoutRoutine) -> some View {
        Button {
            vm.repeatLastWorkout()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.setflowAccent.opacity(0.18)).frame(width: 40, height: 40)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.setflowAccent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Repeat \(routine.name)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text("Same routine as your last workout")
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.55))
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary.opacity(0.3))
            }
            .padding()
            .background(cardBackground)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Win Card

    private var quickWinCard: some View {
        Button {
            vm.startQuickWin()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.setflowSuccess.opacity(0.16)).frame(width: 48, height: 48)
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.setflowSuccess)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Short on time?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text("A 4-minute Quick Win keeps your streak alive.")
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.setflowSuccess.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.setflowSuccess.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var weeklyStreak: some View {
        WeeklyStreakStrip(vm: vm)
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            tabButton(title: "Routines", tab: .routines)
            tabButton(title: "Exercises", tab: .exercises)
        }
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func tabButton(title: String, tab: HomeTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(selectedTab == tab ? .primary : .primary.opacity(0.45))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    selectedTab == tab
                    ? RoundedRectangle(cornerRadius: 10).fill(Color.setflowAccent)
                    : RoundedRectangle(cornerRadius: 10).fill(Color.clear)
                )
                .padding(3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .routines:  routinesTab
        case .exercises: exercisesTab
        }
    }

    // MARK: - Routines Tab

    private var routinesTab: some View {
        VStack(spacing: 12) {
            if vm.routines.isEmpty {
                routinesEmptyState
                    .padding(.top, 24)
            } else {
                ForEach(Array(vm.routines.enumerated()), id: \.element.id) { idx, routine in
                    routineCard(routine)
                        .appearStagger(index: idx, visible: hasAppeared)
                }
            }

            addRoutineButton
                .padding(.top, vm.routines.isEmpty ? 8 : 4)
        }
        .padding(.horizontal)
    }

    private func routineCard(_ routine: WorkoutRoutine) -> some View {
        VStack(spacing: 0) {
            // Main tap area — starts session
            Button {
                vm.startSession(routine: routine)
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.setflowAccent.opacity(0.18))
                            .frame(width: 52, height: 52)
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title3)
                            .foregroundColor(.setflowAccent)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(routine.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack(spacing: 8) {
                            Label("\(routine.exerciseCount) exercises", systemImage: "list.bullet")
                            Label("~\(routine.estimatedMinutes)m", systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.5))
                    }

                    Spacer()

                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.setflowAccent)
                }
                .padding()
            }
            .buttonStyle(.plain)
        }
        .background(cardBackground)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                softDeleteRoutine(routine)
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                editingRoutine = routine
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .contextMenu {
            Button("Edit") { editingRoutine = routine }
            Button("Delete", role: .destructive) { softDeleteRoutine(routine) }
        }
    }

    private var routinesEmptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Color.blue.opacity(0.12)).frame(width: 88, height: 88)
                Image(systemName: "plus.rectangle.on.rectangle")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.setflowAccent)
            }

            VStack(spacing: 8) {
                Text("No Routines Yet")
                    .font(.title3.bold()).foregroundColor(.primary)
                Text("Create a routine to group exercises into a single session.")
                    .font(.subheadline).foregroundColor(.primary.opacity(0.6))
                    .multilineTextAlignment(.center).padding(.horizontal, 24)
            }

            Button {
                showingRoutineEditor = true
            } label: {
                Label("Create First Routine", systemImage: "plus")
                    .fontWeight(.semibold).foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.setflowAccent))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private var addRoutineButton: some View {
        Button {
            showingRoutineEditor = true
        } label: {
            Label("New Routine", systemImage: "plus")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 22).fill(Color.setflowAccent))
        }
        .buttonStyle(.plain)
        .shadow(color: Color.blue.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    // MARK: - Exercises Tab

    private var exercisesTab: some View {
        VStack(spacing: 12) {
            if vm.exercises.isEmpty {
                exercisesEmptyState
                    .padding(.top, 24)
            } else {
                ForEach(Array(vm.exercises.enumerated()), id: \.element.id) { idx, exercise in
                    Button {
                        vm.startWorkout(for: exercise)
                    } label: {
                        exerciseRow(exercise)
                    }
                    .buttonStyle(.plain)
                    .appearStagger(index: idx, visible: hasAppeared)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            softDeleteExercise(exercise)
                        } label: { Label("Delete", systemImage: "trash") }

                        Button { editingExercise = exercise } label: {
                            Label("Edit", systemImage: "pencil")
                        }.tint(.blue)
                    }
                    .contextMenu {
                        Button("Edit") { editingExercise = exercise }
                        Button("Delete", role: .destructive) { softDeleteExercise(exercise) }
                    }
                }
            }

            addExerciseButton
                .padding(.top, vm.exercises.isEmpty ? 8 : 4)
        }
        .padding(.horizontal)
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.setflowAccent.opacity(0.16))
                    .frame(width: 52, height: 52)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title3).foregroundColor(.setflowAccent)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(exercise.name).font(.headline).foregroundColor(.primary)
                Text("\(exercise.sets) sets × \(exercise.reps) reps")
                    .font(.subheadline).foregroundColor(.primary.opacity(0.65))
                Text("Rest \(exercise.restSeconds)s")
                    .font(.caption).foregroundColor(.primary.opacity(0.45))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.primary.opacity(0.3))
                .font(.subheadline.weight(.semibold))
        }
        .padding()
        .background(cardBackground)
    }

    private var exercisesEmptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Color.blue.opacity(0.14)).frame(width: 88, height: 88)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.setflowAccent)
            }
            VStack(spacing: 8) {
                Text("No Exercises Yet")
                    .font(.title3.bold()).foregroundColor(.primary)
                Text("Add exercises to build your routines.")
                    .font(.subheadline).foregroundColor(.primary.opacity(0.6))
                    .multilineTextAlignment(.center).padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var addExerciseButton: some View {
        Button {
            showingExerciseEditor = true
        } label: {
            Label("Add Exercise", systemImage: "plus")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 22).fill(Color.setflowAccent))
        }
        .buttonStyle(.plain)
        .shadow(color: Color.blue.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    // MARK: - Helpers

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.cardPrimary)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cardBorder, lineWidth: 1))
    }

    private func iconButton(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.title3).foregroundColor(.primary)
            .frame(width: 42, height: 42)
            .background(Color.cardBorder)
            .clipShape(Circle())
    }

    // MARK: - Soft Delete Helpers

    private func softDeleteRoutine(_ routine: WorkoutRoutine) {
        vm.softDeleteRoutine(routine) {}
        undoAction.show(
            message: "\"\(routine.name)\" deleted",
            onUndo: { vm.restoreRoutine(routine) },
            onCommit: { vm.commitDeleteRoutine(routine) }
        )
    }

    private func softDeleteExercise(_ exercise: Exercise) {
        vm.softDeleteExercise(exercise) {}
        undoAction.show(
            message: "\"\(exercise.name)\" deleted",
            onUndo: { vm.restoreExercise(exercise) },
            onCommit: { vm.commitDeleteExercise(exercise) }
        )
    }
}

// MARK: - Staggered appear animation

private struct AppearStagger: ViewModifier {
    let index: Int
    let visible: Bool

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 14)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.85)
                    .delay(Double(index) * 0.06),
                value: visible
            )
    }
}

extension View {
    /// Fades and rises a view into place, staggered by `index` so a stack of
    /// sections animates in sequence. Cheap, and makes the screen feel premium.
    func appearStagger(index: Int, visible: Bool) -> some View {
        modifier(AppearStagger(index: index, visible: visible))
    }
}
