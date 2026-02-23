import SwiftUI

struct EditExerciseView: View {
    var vm: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise

    @State private var name: String
    @State private var sets: Int
    @State private var reps: Int
    @State private var restSeconds: Int
    @State private var trackingType: ExerciseTrackingType
    @State private var defaultWeight: Double
    @State private var reminders: [ExerciseReminder]
    @State private var warmupSets: Int

    init(vm: WorkoutViewModel, exercise: Exercise) {
        self.vm       = vm
        self.exercise = exercise
        _name          = State(initialValue: exercise.name)
        _sets          = State(initialValue: exercise.sets)
        _reps          = State(initialValue: exercise.reps)
        _restSeconds   = State(initialValue: exercise.restSeconds)
        _trackingType  = State(initialValue: exercise.tracking)
        _defaultWeight = State(initialValue: exercise.defaultWeight)
        _reminders     = State(initialValue: exercise.reminders)
        _warmupSets    = State(initialValue: exercise.warmupSets)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name", text: $name)
                    Stepper("Sets: \(sets)", value: $sets, in: 1...20)
                        .onChange(of: sets) { _, newSets in
                            if warmupSets > newSets { warmupSets = newSets }
                        }
                    Stepper("Reps: \(reps)", value: $reps, in: 1...200)
                    Stepper("Rest: \(restSeconds)s", value: $restSeconds, in: 5...600, step: 5)
                    Stepper("Warm-up sets: \(warmupSets)", value: $warmupSets, in: 0...sets)
                }

                if warmupSets > 0 {
                    Section {
                        Text("The first \(warmupSets) set\(warmupSets == 1 ? "" : "s") of every session will be tagged as warm-up automatically. Warm-up sets don't count toward your personal bests or volume stats.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Tracking") {
                    Picker("Type", selection: $trackingType) {
                        ForEach(ExerciseTrackingType.allCases, id: \.self) { type in
                            Label(type.label, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    if trackingType == .weighted {
                        HStack {
                            Text("Default Weight")
                            Spacer()
                            Text(weightString(defaultWeight))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $defaultWeight, in: 0...200, step: 2.5)
                    }
                }

                Section("Reminders (max 2 times)") {
                    ForEach($reminders) { $rem in
                        ReminderRow(reminder: $rem)
                    }
                    .onDelete { idx in reminders.remove(atOffsets: idx) }

                    Button("Add reminder time") {
                        guard reminders.count < 2 else { return }
                        reminders.append(ExerciseReminder())
                    }
                    .disabled(reminders.count >= 2)
                }
            }
            .navigationTitle("Edit Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        exercise.name          = name.trimmingCharacters(in: .whitespacesAndNewlines)
        exercise.sets          = sets
        exercise.reps          = reps
        exercise.restSeconds   = restSeconds
        exercise.tracking      = trackingType
        exercise.defaultWeight = trackingType == .weighted ? defaultWeight : 0
        exercise.reminders     = reminders
        exercise.warmupSets    = warmupSets
        vm.updateExercise(exercise)
        Haptics.saved()
        dismiss()
    }

    private func weightString(_ kg: Double) -> String {
        kg.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(kg)) kg" : String(format: "%.1f kg", kg)
    }
}
