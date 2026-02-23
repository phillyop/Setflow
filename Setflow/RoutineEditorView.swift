import SwiftUI

struct RoutineEditorView: View {
    var vm: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedExercises: [RoutineExercise] = []
    @State private var showExercisePicker = false

    var isEditing: Bool { editingRoutine != nil }
    var editingRoutine: WorkoutRoutine?

    init(vm: WorkoutViewModel, editingRoutine: WorkoutRoutine? = nil) {
        self.vm = vm
        self.editingRoutine = editingRoutine
        if let r = editingRoutine {
            _name               = State(initialValue: r.name)
            _selectedExercises  = State(initialValue: r.exercises)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.setflowBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        nameField
                        exerciseSection
                        if !selectedExercises.isEmpty { estimateRow }
                    }
                    .padding()
                }
            }
            .navigationTitle(isEditing ? "Edit Routine" : "New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.primary.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                  || selectedExercises.isEmpty)
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView(vm: vm, selected: $selectedExercises)
            }
        }
    }

    // MARK: - Sections

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ROUTINE NAME")
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary.opacity(0.4))
                .tracking(1)

            TextField("e.g. Push Day, Full Body A", text: $name)
                .font(.body)
                .foregroundColor(.primary)
                .padding()
                .background(Color.primary.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .tint(.blue)
        }
    }

    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("EXERCISES")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary.opacity(0.4))
                    .tracking(1)

                Spacer()

                Button {
                    showExercisePicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.blue)
                }
            }

            if selectedExercises.isEmpty {
                emptyExerciseState
            } else {
                exerciseList
            }
        }
    }

    private var emptyExerciseState: some View {
        Button {
            showExercisePicker = true
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 32))
                    .foregroundColor(.blue.opacity(0.7))

                Text("Add exercises to your routine")
                    .font(.subheadline)
                    .foregroundColor(.primary.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var exerciseList: some View {
        VStack(spacing: 8) {
            ForEach(Array(selectedExercises.enumerated()), id: \.element.id) { index, ex in
                HStack(spacing: 12) {
                    // Drag handle
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.primary.opacity(0.25))
                        .font(.subheadline)

                    // Index badge
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.primary.opacity(0.4))
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(ex.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)

                        Text(ex.warmupSets > 0
                             ? "\(ex.sets) sets × \(ex.reps) reps · \(ex.restSeconds)s rest · \(ex.warmupSets) warm-up"
                             : "\(ex.sets) sets × \(ex.reps) reps · \(ex.restSeconds)s rest")
                            .font(.caption)
                            .foregroundColor(.primary.opacity(0.45))
                    }

                    Spacer()

                    Button {
                        selectedExercises.removeAll { $0.id == ex.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.primary.opacity(0.2))
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(ex.name)")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.cardPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .onMove { from, to in
                selectedExercises.move(fromOffsets: from, toOffset: to)
                // Re-stamp sortOrder
                for (i, _) in selectedExercises.enumerated() {
                    selectedExercises[i].sortOrder = i
                }
            }
        }
    }

    private var estimateRow: some View {
        let totalSets = selectedExercises.reduce(0) { $0 + $1.sets }
        let minutes   = selectedExercises.reduce(0) { acc, ex in
            acc + (ex.sets * (ex.restSeconds + 30))
        } / 60

        return HStack(spacing: 20) {
            statPill(value: "\(selectedExercises.count)", label: "exercises")
            statPill(value: "\(totalSets)", label: "total sets")
            statPill(value: "~\(max(1, minutes))m", label: "est. time")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundColor(.primary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.primary.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Save

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !selectedExercises.isEmpty else { return }

        // Re-stamp sortOrder before saving
        var stamped = selectedExercises
        for i in stamped.indices { stamped[i].sortOrder = i }

        if let routine = editingRoutine {
            routine.name      = trimmed
            routine.exercises = stamped
            vm.updateRoutine(routine)
        } else {
            let routine = WorkoutRoutine(name: trimmed, exercises: stamped)
            vm.addRoutine(routine)
        }

        Haptics.saved()
        dismiss()
    }
}

// MARK: - Exercise Picker

struct ExercisePickerView: View {
    var vm: WorkoutViewModel
    @Binding var selected: [RoutineExercise]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.setflowBg.ignoresSafeArea()

                if vm.exercises.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue.opacity(0.5))
                        Text("No exercises in your library yet.")
                            .foregroundColor(.primary.opacity(0.6))
                    }
                } else {
                    List {
                        ForEach(vm.exercises) { exercise in
                            let isAdded = selected.contains { $0.exerciseID == exercise.id }

                            Button {
                                if isAdded {
                                    selected.removeAll { $0.exerciseID == exercise.id }
                                } else {
                                    let re = RoutineExercise(
                                        exerciseID:   exercise.id,
                                        name:         exercise.name,
                                        sets:         exercise.sets,
                                        reps:         exercise.reps,
                                        restSeconds:  exercise.restSeconds,
                                        sortOrder:    selected.count,
                                        trackingType: exercise.trackingType,
                                        defaultWeight: exercise.defaultWeight,
                                        warmupSets:   exercise.warmupSets
                                    )
                                    selected.append(re)
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isAdded ? Color.blue : Color.primary.opacity(0.07))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: isAdded ? "checkmark" : "figure.strengthtraining.traditional")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(isAdded ? .white : .primary.opacity(0.5))
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(exercise.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Text("\(exercise.sets) × \(exercise.reps) · \(exercise.restSeconds)s rest")
                                            .font(.caption)
                                            .foregroundColor(.primary.opacity(0.45))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
