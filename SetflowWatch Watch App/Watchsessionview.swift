import SwiftUI

struct WatchSessionView: View {
    let state: WatchSessionState

    var restProgress: Double {
        guard state.totalRestSeconds > 0 else { return 0 }
        return Double(state.restCountdown) / Double(state.totalRestSeconds)
    }

    var body: some View {
        if state.isResting { restView } else { activeView }
    }

    // MARK: Active

    private var activeView: some View {
        VStack(spacing: 6) {
            // Session progress dots
            HStack(spacing: 4) {
                ForEach(0..<max(1, state.totalExercises), id: \.self) { i in
                    Circle()
                        .fill(i < state.exerciseIndex ? Color.blue :
                              i == state.exerciseIndex ? Color.white :
                              Color.white.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }

            Spacer(minLength: 4)

            Text(state.exerciseName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text("Set \(state.currentSet) of \(state.totalSets)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))

            Spacer(minLength: 4)

            // Set pip dots
            HStack(spacing: 6) {
                ForEach(1...max(1, state.totalSets), id: \.self) { i in
                    Circle()
                        .fill(i < state.currentSet ? Color.blue :
                              i == state.currentSet ? Color.white :
                              Color.white.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: Resting

    private var restView: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 6)
            Circle()
                .trim(from: 0, to: restProgress)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: restProgress)

            VStack(spacing: 2) {
                Text("\(state.restCountdown)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.orange)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.25), value: state.restCountdown)
                Text("REST")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1)
            }
        }
        .padding(12)
    }
}
