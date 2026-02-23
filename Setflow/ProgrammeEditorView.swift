import SwiftUI

struct ProgrammeEditorView: View {
    var vm: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss

    var editingProgramme: TrainingProgramme?

    @State private var name: String
    @State private var goal: String
    @State private var weeks: [ProgrammeWeek]
    @State private var editingWeekIndex: Int? = nil
    @State private var showAddWeek = false

    init(vm: WorkoutViewModel, editingProgramme: TrainingProgramme? = nil) {
        self.vm                = vm
        self.editingProgramme  = editingProgramme

        if let p = editingProgramme {
            _name  = State(initialValue: p.name)
            _goal  = State(initialValue: p.goal)
            _weeks = State(initialValue: p.weeks)
        } else {
            _name  = State(initialValue: "")
            _goal  = State(initialValue: "Build Strength")
            _weeks = State(initialValue: [])
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.setflowBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        nameSection
                        goalSection
                        weeksSection
                        if !weeks.isEmpty { summaryRow }
                    }
                    .padding()
                }
            }
            .navigationTitle(editingProgramme == nil ? "New Programme" : "Edit Programme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.primary.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || weeks.isEmpty)
                }
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROGRAMME NAME").font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.4)).tracking(1)
            TextField("e.g. 8-Week Strength Block", text: $name)
                .font(.body).foregroundColor(.primary)
                .padding()
                .background(Color.cardPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .tint(.setflowAccent)
        }
    }

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GOAL").font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.4)).tracking(1)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["Build Strength", "Build Muscle", "Lose Weight", "Stay Active", "Custom"], id: \.self) { g in
                        Button {
                            goal = g
                            Haptics.selection()
                        } label: {
                            Text(g)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(goal == g ? .white : .primary.opacity(0.5))
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(goal == g ? Color.setflowAccent : Color.cardPrimary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var weeksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("WEEKS").font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.4)).tracking(1)
                Spacer()
                Button {
                    let newWeek = ProgrammeWeek.make(
                        weekNumber: weeks.count + 1,
                        days: defaultDays()
                    )
                    weeks.append(newWeek)
                    editingWeekIndex = weeks.count - 1
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Week")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.setflowAccent)
                }
                .buttonStyle(.plain)
            }

            if weeks.isEmpty {
                Button {
                    let newWeek = ProgrammeWeek.make(weekNumber: 1, days: defaultDays())
                    weeks.append(newWeek)
                    editingWeekIndex = 0
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle").font(.system(size: 30)).foregroundColor(.setflowAccent.opacity(0.7))
                        Text("Add your first week").font(.subheadline).foregroundColor(.primary.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 28)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            } else {
                ForEach(Array(weeks.enumerated()), id: \.element.id) { index, week in
                    weekCard(week: week, index: index)
                }
            }
        }
    }

    private func weekCard(week: ProgrammeWeek, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(week.label)
                            .font(.headline).foregroundColor(.primary)
                        if week.isDeload {
                            Text("DELOAD")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.setflowRest)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.setflowRest.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    Text("\(week.days.filter { !$0.isRestDay }.count) training days")
                        .font(.caption).foregroundColor(.primary.opacity(0.5))
                }
                Spacer()
                Button { editingWeekIndex = index } label: {
                    Image(systemName: "pencil.circle")
                        .font(.title3).foregroundColor(.primary.opacity(0.3))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit \(week.label)")
                Button {
                    weeks.remove(at: index)
                    renumberWeeks()
                } label: {
                    Image(systemName: "trash").font(.subheadline).foregroundColor(.red.opacity(0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete \(week.label)")
            }

            // Day strip
            HStack(spacing: 4) {
                ForEach(week.days) { day in
                    VStack(spacing: 3) {
                        Text(dayLabel(day.weekday))
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.primary.opacity(0.35))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(day.isRestDay ? Color.primary.opacity(0.06) :
                                  week.isDeload ? Color.setflowRest.opacity(0.4) : Color.setflowAccent)
                            .frame(height: 24)
                            .overlay(
                                Text(day.isRestDay ? "—" : "▶")
                                    .font(.caption2)
                                    .foregroundColor(day.isRestDay ? .primary.opacity(0.3) : .white.opacity(0.9))
                            )
                    }
                    .dynamicTypeSize(...DynamicTypeSize.large)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
        .background(Color.cardPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: Binding(
            get: { editingWeekIndex == index },
            set: { if !$0 { editingWeekIndex = nil } }
        )) {
            WeekEditorSheet(vm: vm, week: $weeks[index])
        }
    }

    private var summaryRow: some View {
        let totalTraining = weeks.reduce(0) { $0 + $1.days.filter { !$0.isRestDay }.count }
        let deloadWeeks   = weeks.filter(\.isDeload).count

        return HStack(spacing: 0) {
            summaryCell("\(weeks.count)", "Weeks")
            Rectangle().fill(Color.primary.opacity(0.08)).frame(width: 1, height: 32)
            summaryCell("\(totalTraining)", "Sessions")
            Rectangle().fill(Color.primary.opacity(0.08)).frame(width: 1, height: 32)
            summaryCell("\(deloadWeeks)", "Deloads")
        }
        .padding(.vertical, 14)
        .background(Color.setflowAccent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func summaryCell(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.headline.bold()).foregroundColor(.primary)
            Text(label).font(.caption2).foregroundColor(.primary.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func defaultDays() -> [ProgrammeDay] {
        (1...7).map { ProgrammeDay.rest(weekday: $0) }
    }

    private func dayLabel(_ weekday: Int) -> String {
        ["M","T","W","T","F","S","S"][max(0, weekday - 1)]
    }

    private func renumberWeeks() {
        for i in weeks.indices {
            if !weeks[i].isDeload {
                let trainingWeekNumber = weeks[0...i].filter { !$0.isDeload }.count
                weeks[i].label = "Week \(trainingWeekNumber)"
                weeks[i].weekNumber = trainingWeekNumber
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !weeks.isEmpty else { return }

        if let p = editingProgramme {
            p.name  = trimmed
            p.goal  = goal
            p.weeks = weeks
            vm.updateProgramme(p)
        } else {
            let p = TrainingProgramme(name: trimmed, goal: goal, weeks: weeks)
            vm.addProgramme(p)
        }
        Haptics.saved()
        dismiss()
    }
}

// MARK: - Week Editor Sheet

struct WeekEditorSheet: View {
    var vm: WorkoutViewModel
    @Binding var week: ProgrammeWeek
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.setflowBgCard.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Deload toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Deload Week")
                                    .font(.headline).foregroundColor(.primary)
                                Text("Lighter training — streak won't break")
                                    .font(.caption).foregroundColor(.primary.opacity(0.5))
                            }
                            Spacer()
                            Toggle("", isOn: $week.isDeload).tint(.setflowRest)
                                .onChange(of: week.isDeload) { _, val in
                                    if val { week.label = "Deload Week" }
                                    else   { week.label = "Week \(week.weekNumber)" }
                                }
                        }
                        .padding(16)
                        .background(Color.cardPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Day assignments
                        Text("DAY ASSIGNMENTS")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.primary.opacity(0.4))
                            .tracking(1)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(week.days.indices, id: \.self) { i in
                            dayRow(index: i)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(week.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func dayRow(index: Int) -> some View {
        let day      = week.days[index]
        let dayNames = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]

        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(day.isRestDay ? Color.primary.opacity(0.06) : Color.setflowAccent.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: day.isRestDay ? "moon.fill" : "figure.strengthtraining.traditional")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(day.isRestDay ? .primary.opacity(0.3) : .setflowAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(dayNames[max(0, day.weekday - 1)])
                    .font(.subheadline.weight(.semibold)).foregroundColor(.primary)
                Text(day.isRestDay ? "Rest Day" : day.routineName)
                    .font(.caption).foregroundColor(.primary.opacity(0.5))
            }

            Spacer()

            // Routine picker
            Menu {
                Button("Rest Day") {
                    week.days[index] = ProgrammeDay.rest(weekday: day.weekday)
                }
                Divider()
                ForEach(vm.routines) { routine in
                    Button(routine.name) {
                        week.days[index] = ProgrammeDay(
                            weekday: day.weekday,
                            routineID: routine.id,
                            routineName: routine.name
                        )
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(day.isRestDay ? "Set Routine" : "Change")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.setflowAccent)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2).foregroundColor(.setflowAccent.opacity(0.7))
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.setflowAccent.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(Color.cardPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
