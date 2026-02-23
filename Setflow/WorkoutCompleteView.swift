import SwiftUI

struct WorkoutCompleteView: View {
    var vm: WorkoutViewModel
    let summary: WorkoutSummary

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.setflowBgGradientTop,
                    Color.setflowBgGradientBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.16))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.green)
                }

                VStack(spacing: 8) {
                    Text("Workout Complete")
                        .font(.title.bold())
                        .foregroundColor(.primary)

                    Text("Nice work — you finished \(summary.exerciseName).")
                        .font(.subheadline)
                        .foregroundColor(.primary.opacity(0.72))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 14) {
                    summaryCard(title: "Sets", value: "\(summary.sets)")
                    summaryCard(title: "Reps per Set", value: "\(summary.reps)")
                    summaryCard(title: "Total Reps", value: "\(summary.totalReps)")
                    summaryCard(
                        title: "Completed",
                        value: summary.completedAt.formatted(date: .abbreviated, time: .shortened)
                    )
                }

                if vm.currentStreak > 0 {
                    HStack(spacing: 8) {
                        Text("🔥")
                        Text("\(vm.currentStreak) Day Streak")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.orange)
                    .padding(.top, 6)
                }

                Spacer()

                Button {
                    vm.clearWorkoutSummary()
                } label: {
                    Text("Done")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.blue)
                        )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    HistoryView(vm: vm)
                } label: {
                    Text("View History")
                        .font(.headline)
                        .foregroundColor(.primary.opacity(0.85))
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
    }

    private func summaryCard(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.primary.opacity(0.72))

            Spacer()

            Text(value)
                .foregroundColor(.primary)
                .fontWeight(.semibold)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.cardPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.cardBorder, lineWidth: 1)
                )
        )
    }
}
