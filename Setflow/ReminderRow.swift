import SwiftUI

struct ReminderRow: View {
    @Binding var reminder: ExerciseReminder

    private let weekdays: [(label: String, value: Int)] = [
        ("Mon", 2), ("Tue", 3), ("Wed", 4),
        ("Thu", 5), ("Fri", 6), ("Sat", 7), ("Sun", 1)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle("Enabled", isOn: $reminder.isEnabled)

            DatePicker(
                "Time",
                selection: timeBinding,
                displayedComponents: [.hourAndMinute]
            )

            Text("Repeat on")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                spacing: 8
            ) {
                ForEach(weekdays, id: \.value) { day in
                    dayChip(label: day.label, value: day.value)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func dayChip(label: String, value: Int) -> some View {
        let isSelected = reminder.weekdays.contains(value)

        Text(label)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.15))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .onTapGesture {
                toggle(value)
            }
    }

    private func toggle(_ day: Int) {
        if reminder.weekdays.contains(day) {
            reminder.weekdays.remove(day)
        } else {
            reminder.weekdays.insert(day)
        }
    }

    private var timeBinding: Binding<Date> {
        Binding<Date>(
            get: {
                var comps = DateComponents()
                comps.hour = reminder.hour
                comps.minute = reminder.minute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newValue in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminder.hour = comps.hour ?? reminder.hour
                reminder.minute = comps.minute ?? reminder.minute
            }
        )
    }
}
