import SwiftUI

// MARK: - Onboarding State

enum OnboardingGoal: String, CaseIterable {
    case strength    = "Build Strength"
    case muscle      = "Build Muscle"
    case weightLoss  = "Lose Weight"
    case active      = "Stay Active"

    var icon: String {
        switch self {
        case .strength:   return "bolt.fill"
        case .muscle:     return "figure.strengthtraining.traditional"
        case .weightLoss: return "flame.fill"
        case .active:     return "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .strength:   return .blue
        case .muscle:     return .purple
        case .weightLoss: return .orange
        case .active:     return .green
        }
    }
}

enum OnboardingEquipment: String, CaseIterable {
    case none      = "No Equipment"
    case dumbbells = "Dumbbells"
    case fullGym   = "Full Gym"

    var icon: String {
        switch self {
        case .none:      return "figure.walk"
        case .dumbbells: return "dumbbell.fill"
        case .fullGym:   return "building.2.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .none:      return "Bodyweight exercises only"
        case .dumbbells: return "Home workout setup"
        case .fullGym:   return "Full equipment access"
        }
    }
}

// MARK: - Starter Routine Generator

struct StarterRoutine {
    let name: String
    let exercises: [(name: String, sets: Int, reps: Int, rest: Int, tracking: ExerciseTrackingType, weight: Double)]
}

enum StarterRoutineGenerator {
    static func routine(goal: OnboardingGoal, equipment: OnboardingEquipment) -> StarterRoutine {
        switch (goal, equipment) {

        case (.strength, .fullGym), (.muscle, .fullGym):
            return StarterRoutine(name: "Push Day", exercises: [
                ("Bench Press",     4, 8,  90, .weighted, 40),
                ("Overhead Press",  3, 10, 75, .weighted, 25),
                ("Incline DB Press",3, 10, 60, .weighted, 20),
                ("Tricep Dips",     3, 12, 60, .bodyweight, 0),
                ("Lateral Raises",  3, 15, 45, .weighted, 8)
            ])

        case (.strength, .dumbbells), (.muscle, .dumbbells):
            return StarterRoutine(name: "Full Body A", exercises: [
                ("DB Goblet Squat",  4, 10, 75, .weighted, 20),
                ("DB Row",           3, 12, 60, .weighted, 15),
                ("DB Shoulder Press",3, 10, 60, .weighted, 12),
                ("DB Romanian Deadlift", 3, 10, 75, .weighted, 20),
                ("DB Bicep Curl",    3, 12, 45, .weighted, 10)
            ])

        case (.strength, .none), (.muscle, .none):
            return StarterRoutine(name: "Bodyweight Strength", exercises: [
                ("Push-ups",         4, 12, 60, .bodyweight, 0),
                ("Pull-ups",         3, 8,  90, .bodyweight, 0),
                ("Bodyweight Squat", 4, 20, 45, .bodyweight, 0),
                ("Dips",             3, 10, 60, .bodyweight, 0),
                ("Plank",            3, 45, 45, .bodyweight, 0)
            ])

        case (.weightLoss, .fullGym):
            return StarterRoutine(name: "Fat Burner Circuit", exercises: [
                ("Barbell Squat",    3, 15, 45, .weighted, 30),
                ("DB Lunges",        3, 12, 45, .weighted, 12),
                ("Push-ups",         3, 20, 30, .bodyweight, 0),
                ("KB Swings",        3, 20, 45, .weighted, 16),
                ("Burpees",          3, 15, 60, .bodyweight, 0)
            ])

        case (.weightLoss, .dumbbells):
            return StarterRoutine(name: "DB HIIT Circuit", exercises: [
                ("DB Thrusters",     3, 15, 45, .weighted, 10),
                ("DB Renegade Row",  3, 10, 60, .weighted, 10),
                ("DB Reverse Lunge", 3, 12, 45, .weighted, 10),
                ("Push-ups",         3, 20, 30, .bodyweight, 0),
                ("Jumping Jacks",    3, 30, 30, .bodyweight, 0)
            ])

        case (.weightLoss, .none), (.active, .none):
            return StarterRoutine(name: "Bodyweight Cardio", exercises: [
                ("Jumping Jacks",    3, 40, 30, .bodyweight, 0),
                ("Burpees",          3, 15, 60, .bodyweight, 0),
                ("Mountain Climbers",3, 30, 45, .bodyweight, 0),
                ("High Knees",       3, 40, 30, .bodyweight, 0),
                ("Push-ups",         3, 15, 45, .bodyweight, 0)
            ])

        case (.active, .fullGym):
            return StarterRoutine(name: "Active Lifestyle", exercises: [
                ("Treadmill Walk",   1, 20, 30, .bodyweight, 0),
                ("Leg Press",        3, 15, 60, .weighted, 40),
                ("Lat Pulldown",     3, 12, 60, .weighted, 30),
                ("Cable Row",        3, 12, 60, .weighted, 25),
                ("Stretching",       1, 10, 30, .bodyweight, 0)
            ])

        case (.active, .dumbbells):
            return StarterRoutine(name: "Stay Active", exercises: [
                ("DB Squat",         3, 15, 45, .weighted, 12),
                ("DB Row",           3, 12, 45, .weighted, 10),
                ("Push-ups",         3, 15, 45, .bodyweight, 0),
                ("DB Deadlift",      3, 12, 60, .weighted, 15),
                ("Plank",            3, 30, 45, .bodyweight, 0)
            ])
        }
    }
}

// MARK: - Main Onboarding View

struct OnboardingView: View {
    var vm: WorkoutViewModel
    let onComplete: () -> Void

    @State private var page: Int = 0
    @State private var goal: OnboardingGoal? = nil
    @State private var equipment: OnboardingEquipment? = nil
    @State private var trainingTime: TrainingTimeChoice? = nil

    var body: some View {
        ZStack {
            Color.setflowBg.ignoresSafeArea()

            switch page {
            case 0:
                WelcomePage { page = 1 }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
            case 1:
                GoalPage(selected: $goal) {
                    if goal != nil { withAnimation(.easeInOut(duration: 0.35)) { page = 2 } }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
            case 2:
                EquipmentPage(selected: $equipment) {
                    if equipment != nil { withAnimation(.easeInOut(duration: 0.35)) { page = 3 } }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
            case 3:
                TrainingTimePage(selected: $trainingTime) {
                    if let choice = trainingTime {
                        vm.setOnboardingTrainingHour(choice.hour)
                        withAnimation(.easeInOut(duration: 0.35)) { page = 4 }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
            case 4:
                if let goal, let equipment {
                    StarterRoutinePage(
                        vm: vm,
                        routine: StarterRoutineGenerator.routine(goal: goal, equipment: equipment),
                        onComplete: onComplete
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: page)
    }
}

// MARK: - Page 1: Welcome

private struct WelcomePage: View {
    let onNext: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo area
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.5)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                        .shadow(color: .blue.opacity(0.4), radius: 20)

                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

                VStack(spacing: 10) {
                    Text("Setflow")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("Train with structure.\nStay consistent. See results.")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            }

            Spacer()

            // Feature highlights
            VStack(spacing: 14) {
                featureRow(icon: "list.bullet.clipboard.fill", color: .blue,
                           title: "Structured Routines",
                           subtitle: "Build and follow workout plans")
                featureRow(icon: "chart.line.uptrend.xyaxis", color: .purple,
                           title: "Track Progress",
                           subtitle: "See your strength improve over time")
                featureRow(icon: "flame.fill", color: .orange,
                           title: "Build Streaks",
                           subtitle: "Stay consistent with smart reminders")
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()

            Button(action: onNext) {
                Text("Get Started")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.blue))
                    .shadow(color: .blue.opacity(0.35), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 28)
            .padding(.bottom, 48)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) {
                appeared = true
            }
        }
    }

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundColor(.white)
                Text(subtitle).font(.caption).foregroundColor(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}

// MARK: - Page 2: Goal

private struct GoalPage: View {
    @Binding var selected: OnboardingGoal?
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            pageHeader(step: "1 of 4", title: "What's your\nmain goal?",
                       subtitle: "We'll build a starter routine around it.")

            Spacer()

            VStack(spacing: 14) {
                ForEach(OnboardingGoal.allCases, id: \.self) { goal in
                    goalCard(goal)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            nextButton(label: "Continue", enabled: selected != nil, action: onNext)
        }
    }

    private func goalCard(_ goal: OnboardingGoal) -> some View {
        let isSelected = selected == goal
        return Button {
            selected = goal
            Haptics.selection()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? goal.color : goal.color.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: goal.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isSelected ? .white : goal.color)
                }

                Text(goal.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(goal.color)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? goal.color.opacity(0.12) : Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isSelected ? goal.color.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Page 3: Equipment

private struct EquipmentPage: View {
    @Binding var selected: OnboardingEquipment?
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            pageHeader(step: "2 of 4", title: "What equipment\ndo you have?",
                       subtitle: "Your routine will match what's available.")

            Spacer()

            VStack(spacing: 14) {
                ForEach(OnboardingEquipment.allCases, id: \.self) { equip in
                    equipmentCard(equip)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            nextButton(label: "Continue", enabled: selected != nil, action: onNext)
        }
    }

    private func equipmentCard(_ equip: OnboardingEquipment) -> some View {
        let isSelected = selected == equip
        return Button {
            selected = equip
            Haptics.selection()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                        .frame(width: 52, height: 52)
                    Image(systemName: equip.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .blue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(equip.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(equip.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? Color.blue.opacity(0.12) : Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isSelected ? Color.blue.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Page 4: Training Time (habit anchor)

enum TrainingTimeChoice: String, CaseIterable, Identifiable {
    case morning
    case midday
    case evening
    case lateEvening

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning:     return "Early morning"
        case .midday:      return "Midday"
        case .evening:     return "Evening"
        case .lateEvening: return "Late evening"
        }
    }

    var subtitle: String {
        switch self {
        case .morning:     return "Before the day gets going"
        case .midday:      return "Around lunch or a break"
        case .evening:     return "After work or school"
        case .lateEvening: return "Winding down the day"
        }
    }

    var icon: String {
        switch self {
        case .morning:     return "sunrise.fill"
        case .midday:      return "sun.max.fill"
        case .evening:     return "sunset.fill"
        case .lateEvening: return "moon.stars.fill"
        }
    }

    /// The hour the reminder is seeded to. Deliberately mid-window so it lands
    /// during the block rather than at its edge.
    var hour: Int {
        switch self {
        case .morning:     return 7
        case .midday:      return 12
        case .evening:     return 18
        case .lateEvening: return 21
        }
    }
}

private struct TrainingTimePage: View {
    @Binding var selected: TrainingTimeChoice?
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            pageHeader(step: "3 of 4", title: "When do you\nusually train?",
                       subtitle: "We'll remind you then. You can change it anytime.")

            Spacer()

            VStack(spacing: 14) {
                ForEach(TrainingTimeChoice.allCases) { choice in
                    timeCard(choice)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            nextButton(label: "Continue", enabled: selected != nil, action: onNext)
        }
    }

    private func timeCard(_ choice: TrainingTimeChoice) -> some View {
        let isSelected = selected == choice
        return Button {
            selected = choice
            Haptics.selection()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                        .frame(width: 52, height: 52)
                    Image(systemName: choice.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .blue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(choice.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(choice.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? Color.blue.opacity(0.12) : Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isSelected ? Color.blue.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Page 5: Starter Routine

private struct StarterRoutinePage: View {
    var vm: WorkoutViewModel
    let routine: StarterRoutine
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            pageHeader(step: "4 of 4", title: "Your starter\nroutine is ready",
                       subtitle: "You can edit or add more any time.")

            Spacer(minLength: 16)

            // Routine card
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.blue.opacity(0.18))
                            .frame(width: 52, height: 52)
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(routine.name)
                            .font(.headline).foregroundColor(.white)
                        Text("\(routine.exercises.count) exercises")
                            .font(.caption).foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding([.horizontal, .top], 16)
                .padding(.bottom, 14)

                Divider().background(Color.white.opacity(0.08))

                VStack(spacing: 0) {
                    ForEach(Array(routine.exercises.enumerated()), id: \.offset) { index, ex in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white.opacity(0.35))
                                .frame(width: 18)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(ex.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white)
                                Text("\(ex.sets) sets × \(ex.reps) reps · \(ex.rest)s rest")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.45))
                            }

                            Spacer()

                            if ex.tracking == .weighted {
                                Text("\(Int(ex.weight))kg")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.blue.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                        if index < routine.exercises.count - 1 {
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 46)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.horizontal, 24)

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button {
                    createAndComplete()
                } label: {
                    Text("Start with This Routine")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.blue))
                        .shadow(color: .blue.opacity(0.35), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)

                Button {
                    markComplete()
                } label: {
                    Text("Skip, I'll build my own")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private func createAndComplete() {
        // Create exercises in the library
        var routineExercises: [RoutineExercise] = []

        for (index, ex) in routine.exercises.enumerated() {
            let exercise = Exercise(
                name: ex.name,
                sets: ex.sets,
                reps: ex.reps,
                restSeconds: ex.rest,
                sortOrder: index,
                trackingType: ex.tracking,
                defaultWeight: ex.weight
            )
            vm.addExercise(exercise)

            routineExercises.append(RoutineExercise(
                exerciseID:    exercise.id,
                name:          exercise.name,
                sets:          exercise.sets,
                reps:          exercise.reps,
                restSeconds:   exercise.restSeconds,
                sortOrder:     index,
                trackingType:  exercise.trackingType,
                defaultWeight: exercise.defaultWeight
            ))
        }

        // Create the routine
        let workoutRoutine = WorkoutRoutine(name: routine.name, exercises: routineExercises)
        vm.addRoutine(workoutRoutine)

        Haptics.sessionComplete()
        markComplete()
    }

    private func markComplete() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        onComplete()
    }
}

// MARK: - Shared Page Components

private func pageHeader(step: String, title: String, subtitle: String) -> some View {
    VStack(spacing: 10) {
        Text(step)
            .font(.caption.weight(.semibold))
            .foregroundColor(.blue)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.12))
            .clipShape(Capsule())
            .padding(.top, 60)

        Text(title)
            .font(.title.bold())
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .padding(.top, 8)

        Text(subtitle)
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.55))
            .multilineTextAlignment(.center)
    }
    .padding(.horizontal, 28)
    .padding(.bottom, 8)
}

private func nextButton(label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(label)
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(enabled ? Color.blue : Color.white.opacity(0.1))
            )
            .shadow(color: enabled ? .blue.opacity(0.35) : .clear, radius: 12, x: 0, y: 6)
    }
    .buttonStyle(.plain)
    .disabled(!enabled)
    .padding(.horizontal, 24)
    .padding(.bottom, 48)
    .animation(.easeInOut(duration: 0.2), value: enabled)
}
