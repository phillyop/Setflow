import SwiftUI

struct ProgrammesView: View {
    var vm: WorkoutViewModel
    @State private var showEditor      = false
    @State private var editingProgramme: TrainingProgramme? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.setflowBg.ignoresSafeArea()

                if vm.programmes.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Active programme hero
                            if let active = vm.activeProgramme {
                                activeProgrammeCard(active)
                                    .padding(.horizontal)
                            }

                            // All programmes
                            VStack(alignment: .leading, spacing: 10) {
                                if vm.activeProgramme != nil {
                                    Text("ALL PROGRAMMES")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.primary.opacity(0.4))
                                        .tracking(1)
                                        .padding(.horizontal)
                                }

                                ForEach(vm.programmes) { programme in
                                    programmeCard(programme)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Programmes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showEditor = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New programme")
                }
            }
            .sheet(isPresented: $showEditor) {
                ProgrammeEditorView(vm: vm)
            }
            .sheet(item: $editingProgramme) { p in
                ProgrammeEditorView(vm: vm, editingProgramme: p)
            }
        }
    }

    // MARK: - Active Programme Hero

    private func activeProgrammeCard(_ programme: TrainingProgramme) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACTIVE PROGRAMME")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.setflowAccent.opacity(0.8))
                        .tracking(1)
                    Text(programme.name)
                        .font(.title3.bold()).foregroundColor(.primary)
                    Text(programme.goal)
                        .font(.subheadline).foregroundColor(.primary.opacity(0.55))
                }
                Spacer()
                ZStack {
                    Circle().fill(Color.setflowAccent.opacity(0.18)).frame(width: 48, height: 48)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2).foregroundColor(.setflowAccent)
                }
            }

            // Progress bar
            if let start = programme.startedAt {
                let progress = programme.progressFraction()
                let cal      = Calendar.current
                let elapsed  = cal.dateComponents([.day], from: start, to: Date()).day ?? 0
                let total    = programme.totalWeeks * 7

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Day \(elapsed + 1) of \(total)")
                            .font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.6))
                        Spacer()
                        Text("\(Int(progress * 100))% complete")
                            .font(.caption).foregroundColor(.setflowAccent.opacity(0.8))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.08)).frame(height: 6)
                            RoundedRectangle(cornerRadius: 4).fill(Color.setflowAccent)
                                .frame(width: geo.size.width * progress, height: 6)
                                .animation(.easeOut(duration: 0.5), value: progress)
                        }
                    }
                    .frame(height: 6)
                }
            }

            // Today's workout
            if let today = programme.todayProgrammeDay() {
                Divider().background(Color.primary.opacity(0.08))
                HStack(spacing: 12) {
                    Image(systemName: today.isRestDay ? "moon.fill" : "play.fill")
                        .font(.subheadline).foregroundColor(today.isRestDay ? .primary.opacity(0.3) : .setflowAccent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today").font(.caption).foregroundColor(.primary.opacity(0.45))
                        Text(today.isRestDay ? "Rest Day" : today.routineName)
                            .font(.subheadline.weight(.semibold)).foregroundColor(.primary)
                    }
                    Spacer()
                    if !today.isRestDay, let routine = vm.routines.first(where: { $0.id == today.routineID }) {
                        Button {
                            vm.startSession(routine: routine)
                        } label: {
                            Text("Start")
                                .font(.subheadline.weight(.semibold)).foregroundColor(.white)
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(Color.setflowAccent)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .background(Color.setflowAccent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.setflowAccent.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Programme Card

    private func programmeCard(_ programme: TrainingProgramme) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(programme.name)
                        .font(.headline).foregroundColor(.primary)
                    HStack(spacing: 8) {
                        Label("\(programme.totalWeeks)w", systemImage: "calendar")
                        Label("\(programme.trainingDaysPerWeek)d/wk", systemImage: "figure.strengthtraining.traditional")
                        if programme.goal != "" {
                            Label(programme.goal, systemImage: "target")
                        }
                    }
                    .font(.caption).foregroundColor(.primary.opacity(0.5))
                }
                Spacer()
                if programme.isActive {
                    Text("ACTIVE")
                        .font(.caption2.weight(.bold)).foregroundColor(.setflowAccent)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.setflowAccent.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 8) {
                if programme.isActive {
                    Button("Deactivate") {
                        vm.deactivateProgramme()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.red.opacity(0.7))
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(Color.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Button("Start Programme") {
                        vm.activateProgramme(programme)
                    }
                    .font(.subheadline.weight(.semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(Color.setflowAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button { editingProgramme = programme } label: {
                    Image(systemName: "pencil")
                        .font(.subheadline).foregroundColor(.primary.opacity(0.6))
                        .frame(width: 40, height: 40)
                        .background(Color.primary.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit \(programme.name)")

                Button {
                    vm.deleteProgramme(programme)
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline).foregroundColor(.red.opacity(0.5))
                        .frame(width: 40, height: 40)
                        .background(Color.primary.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete \(programme.name)")
            }
        }
        .padding(16)
        .setflowCard()
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(Color.setflowAccent.opacity(0.12)).frame(width: 88, height: 88)
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 32, weight: .semibold)).foregroundColor(.setflowAccent)
            }
            VStack(spacing: 8) {
                Text("No Programmes Yet").font(.title3.bold()).foregroundColor(.primary)
                Text("Create a multi-week training plan to stay on track.")
                    .font(.subheadline).foregroundColor(.primary.opacity(0.6))
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }
            Button { showEditor = true } label: {
                Label("Create Programme", systemImage: "plus")
                    .fontWeight(.semibold).foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.setflowAccent))
            }
            .buttonStyle(.plain)
        }
    }
}
