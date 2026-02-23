import SwiftUI

struct ScheduleEditorView: View {
    var vm: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isEnabled: Bool
    @State private var selectedDays: Set<Int>

    init(vm: WorkoutViewModel) {
        self.vm = vm
        let s = vm.trainingSchedule
        _isEnabled    = State(initialValue: s.isEnabled)
        _selectedDays = State(initialValue: s.scheduledWeekdays)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.setflowBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Toggle
                        toggleSection

                        if isEnabled {
                            // Day picker
                            dayPickerSection

                            // Preview
                            if !selectedDays.isEmpty {
                                previewSection
                            }
                        }
                    }
                    .padding()
                    .animation(.easeInOut(duration: 0.25), value: isEnabled)
                }
            }
            .navigationTitle("Training Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.primary.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Toggle Section

    private var toggleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Programme-Aware Streaks")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Rest days won't break your streak.")
                        .font(.subheadline)
                        .foregroundColor(.primary.opacity(0.55))
                }
                Spacer()
                Toggle("", isOn: $isEnabled)
                    .tint(.blue)
            }

            if !isEnabled {
                Text("When off, your streak requires a workout every single day.")
                    .font(.caption)
                    .foregroundColor(.primary.opacity(0.4))
                    .padding(.top, 2)
            }
        }
        .padding(16)
        .background(Color.cardPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Day Picker

    private var dayPickerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TRAINING DAYS")
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary.opacity(0.4))
                .tracking(1)

            // Day chips — 2 rows of 4 (Mon–Thu top, Fri–Sun bottom)
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    ForEach(TrainingSchedule.weekdayLabels.prefix(4), id: \.0) { (day, label) in
                        dayChip(day: day, label: label)
                    }
                }
                HStack(spacing: 10) {
                    ForEach(TrainingSchedule.weekdayLabels.suffix(3), id: \.0) { (day, label) in
                        dayChip(day: day, label: label)
                    }
                    // Filler to keep alignment
                    Spacer().frame(maxWidth: .infinity)
                }
            }

            // Quick presets
            HStack(spacing: 8) {
                presetButton("Every day",  days: Set(1...7))
                presetButton("Mon–Fri",    days: Set([2,3,4,5,6]))
                presetButton("3×/week",    days: Set([2,4,6]))
                presetButton("4×/week",    days: Set([2,3,5,6]))
            }
        }
        .padding(16)
        .background(Color.cardPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func dayChip(day: Int, label: String) -> some View {
        let selected = selectedDays.contains(day)
        return Button {
            if selected { selectedDays.remove(day) }
            else         { selectedDays.insert(day) }
            Haptics.selection()
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(selected ? .white : .primary.opacity(0.45))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? Color.blue : Color.primary.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func presetButton(_ label: String, days: Set<Int>) -> some View {
        Button {
            selectedDays = days
            Haptics.selection()
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary.opacity(0.7))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.primary.opacity(0.06))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preview

    private var previewSection: some View {
        let sorted = selectedDays.sorted()
        let names = sorted.compactMap { day in
            TrainingSchedule.weekdayLabels.first(where: { $0.0 == day })?.1
        }
        let schedule = "\(selectedDays.count) days/week: \(names.joined(separator: ", "))"

        return VStack(alignment: .leading, spacing: 10) {
            Text("PREVIEW")
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary.opacity(0.4))
                .tracking(1)

            HStack(spacing: 10) {
                ForEach(1...7, id: \.self) { weekday in
                    let isTraining = selectedDays.contains(weekday)
                    let label = shortLabel(weekday: weekday)

                    VStack(spacing: 6) {
                        Text(label)
                            .font(.caption2.weight(.medium))
                            .foregroundColor(isTraining ? .primary.opacity(0.7) : .primary.opacity(0.25))

                        ZStack {
                            Circle()
                                .fill(isTraining
                                      ? Color.blue.opacity(0.25)
                                      : Color.primary.opacity(0.04))
                                .frame(width: 32, height: 32)

                            Image(systemName: isTraining ? "figure.strengthtraining.traditional" : "moon.fill")
                                .font(.system(size: isTraining ? 12 : 9))
                                .foregroundColor(isTraining ? .blue : .primary.opacity(0.2))
                        }
                    }
                    .dynamicTypeSize(...DynamicTypeSize.large)
                    .frame(maxWidth: .infinity)
                }
            }

            Text(schedule)
                .font(.caption)
                .foregroundColor(.primary.opacity(0.5))
                .padding(.top, 4)
        }
        .padding(16)
        .background(Color.blue.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.blue.opacity(0.15), lineWidth: 1))
    }

    private func shortLabel(weekday: Int) -> String {
        TrainingSchedule.weekdayLabels.first(where: { $0.0 == weekday })?.1
            ?? ["S","M","T","W","T","F","S"][weekday - 1]
    }

    // MARK: - Save

    private func save() {
        let schedule = TrainingSchedule(
            scheduledWeekdays: isEnabled ? selectedDays : [],
            isEnabled: isEnabled
        )
        vm.updateSchedule(schedule)
        Haptics.saved()
        dismiss()
    }
}
