import SwiftUI

struct WeeklyStreakStrip: View {
    var vm: WorkoutViewModel

    var body: some View {
        let dates    = vm.currentWeekDates()
        let calendar = Calendar.current
        let today    = Date()
        let schedule = vm.trainingSchedule

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This Week")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if schedule.isEnabled {
                    Text("Schedule On")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 10) {
                ForEach(dates, id: \.self) { date in
                    let isToday       = calendar.isDate(date, inSameDayAs: today)
                    let completed     = vm.hasWorkout(on: date)
                    let isRestDay     = !schedule.isTrainingDay(date)
                    let isFuture      = date > today

                    VStack(spacing: 8) {
                        Text(shortWeekday(for: date))
                            .font(.caption)
                            .foregroundColor(isRestDay ? .primary.opacity(0.3) : .primary.opacity(0.65))

                        ZStack {
                            Circle()
                                .fill(circleFill(
                                    completed: completed,
                                    isToday: isToday,
                                    isRestDay: isRestDay,
                                    isFuture: isFuture
                                ))
                                .frame(width: 34, height: 34)

                            if completed {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.white)
                            } else if isRestDay {
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.primary.opacity(0.25))
                            } else if isToday {
                                Circle()
                                    .stroke(Color.primary.opacity(0.9), lineWidth: 2)
                                    .frame(width: 14, height: 14)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(isFuture && !isRestDay ? 0.5 : 1.0)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.cardBorder, lineWidth: 1)
                )
        )
    }

    private func shortWeekday(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "E"
        return f.string(from: date)
    }

    private func circleFill(completed: Bool, isToday: Bool,
                             isRestDay: Bool, isFuture: Bool) -> Color {
        if completed  { return .blue }
        if isRestDay  { return Color.primary.opacity(0.04) }
        if isToday    { return Color.primary.opacity(0.12) }
        if isFuture   { return Color.primary.opacity(0.05) }
        return Color.primary.opacity(0.08)
    }
}
