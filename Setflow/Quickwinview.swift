import SwiftUI
import Combine

/// The Quick Win flow — a short guided mobility sequence that keeps the streak
/// alive on a day a full workout isn't happening. Deliberately calm and simple:
/// one move at a time, a gentle timer, no pressure.
struct QuickWinView: View {
    var vm: WorkoutViewModel

    @State private var remaining: Int = 0
    @State private var isPaused = false
    @State private var showExitConfirm = false

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var move: WorkoutViewModel.QuickWinMove? {
        guard vm.quickWinIndex < vm.quickWinMoves.count else { return nil }
        return vm.quickWinMoves[vm.quickWinIndex]
    }

    private var progress: Double {
        Double(vm.quickWinIndex) / Double(max(vm.quickWinMoves.count, 1))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.setflowBgGradientTop, Color.setflowBgGradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer()

                if let move {
                    moveContent(move)
                }

                Spacer()

                controls
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .onAppear { resetTimerForCurrentMove() }
        .onChange(of: vm.quickWinIndex) { _, _ in resetTimerForCurrentMove() }
        .onReceive(tick) { _ in
            guard !isPaused, vm.isQuickWinActive else { return }
            if remaining > 0 {
                remaining -= 1
                if remaining == 0 {
                    Haptics.setConfirmed()
                    vm.advanceQuickWin()
                }
            }
        }
        .confirmationDialog("Leave Quick Win?", isPresented: $showExitConfirm, titleVisibility: .visible) {
            Button("Leave", role: .destructive) { vm.cancelQuickWin() }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("Your streak won't be saved unless you finish.")
        }
    }

    // MARK: - Top bar + progress

    private var topBar: some View {
        VStack(spacing: 14) {
            HStack {
                Button { showExitConfirm = true } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color.primary.opacity(0.08))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Exit Quick Win")
                Spacer()
                VStack(spacing: 1) {
                    Text("QUICK WIN")
                        .font(.caption2.weight(.bold)).tracking(1.5)
                        .foregroundColor(.setflowSuccess)
                    Text("Move \(vm.quickWinIndex + 1) of \(vm.quickWinMoves.count)")
                        .font(.caption).foregroundColor(.primary.opacity(0.5))
                }
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08)).frame(height: 5)
                    Capsule().fill(Color.setflowSuccess)
                        .frame(width: geo.size.width * progress, height: 5)
                        .animation(.easeInOut(duration: 0.35), value: progress)
                }
            }
            .frame(height: 5)
        }
        .padding(.top, 8)
    }

    // MARK: - Current move

    private func moveContent(_ move: WorkoutViewModel.QuickWinMove) -> some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 14)
                    .frame(width: 240, height: 240)

                Circle()
                    .trim(from: 0, to: ringProgress(move))
                    .stroke(Color.setflowSuccess,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 240, height: 240)
                    .animation(.linear(duration: 0.9), value: remaining)

                VStack(spacing: 8) {
                    Image(systemName: move.symbol)
                        .font(.system(size: 34, weight: .light))
                        .foregroundColor(.setflowSuccess)
                    Text("\(remaining)")
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("seconds").font(.caption).foregroundColor(.primary.opacity(0.45))
                }
                .dynamicTypeSize(...DynamicTypeSize.large)
            }

            VStack(spacing: 8) {
                Text(move.name)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                Text(move.detail)
                    .font(.subheadline)
                    .foregroundColor(.primary.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
            .id(move.id)
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                isPaused.toggle()
            } label: {
                Text(isPaused ? "Resume" : "Pause")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.primary.opacity(0.10)))
            }
            .buttonStyle(.plain)

            Button {
                Haptics.selection()
                vm.advanceQuickWin()
            } label: {
                Text(vm.quickWinIndex < vm.quickWinMoves.count - 1 ? "Skip to Next" : "Finish Quick Win")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.setflowSuccess))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func ringProgress(_ move: WorkoutViewModel.QuickWinMove) -> Double {
        guard move.seconds > 0 else { return 0 }
        return Double(remaining) / Double(move.seconds)
    }

    private func resetTimerForCurrentMove() {
        remaining = move?.seconds ?? 0
        isPaused  = false
    }
}
