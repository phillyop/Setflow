import SwiftUI

struct ExerciseEditorView: View {
    var vm: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var sets: Int = 3
    @State private var reps: Int = 10
    @State private var restSeconds: Int = 45
    @State private var trackingType: ExerciseTrackingType = .bodyweight
    @State private var defaultWeight: Double = 20
    @State private var reminders: [ExerciseReminder] = []
    @State private var warmupSets: Int = 0
    @State private var showLibraryPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showLibraryPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "books.vertical.fill")
                                .foregroundColor(.blue)
                            Text("Pick from Exercise Library")
                                .foregroundColor(.blue)
                        }
                    }
                }

                Section("Exercise") {
                    TextField("Name (e.g. Push-ups)", text: $name)
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
            .navigationTitle("Add Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showLibraryPicker) {
                LibraryPickerView { preset in
                    name          = preset.name
                    sets          = preset.sets
                    reps          = preset.reps
                    restSeconds   = preset.restSeconds
                    trackingType  = preset.tracking
                    defaultWeight = preset.defaultWeight
                }
            }
        }
    }

    private func save() {
        let exercise = Exercise(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            sets: sets,
            reps: reps,
            restSeconds: restSeconds,
            trackingType: trackingType,
            defaultWeight: trackingType == .weighted ? defaultWeight : 0,
            reminders: reminders,
            warmupSets: warmupSets
        )
        vm.addExercise(exercise)
        Haptics.saved()
        dismiss()
    }

    private func weightString(_ kg: Double) -> String {
        kg.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(kg)) kg" : String(format: "%.1f kg", kg)
    }
}
