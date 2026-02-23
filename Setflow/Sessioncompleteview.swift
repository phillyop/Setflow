import SwiftUI

struct SessionCompleteView: View {
    var vm: WorkoutViewModel
    let summary: SessionSummary
    @State private var showShareSheet = false
    @State private var shareImage: UIImage? = nil
    @State private var isRendering = false

    // Celebration sequence state
    @State private var heroIn = false
    @State private var contentIn = false
    @State private var fireConfetti = false
    @State private var displayStreak = 0

    private var isWin: Bool { summary.wasCompleted }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.setflowBgGradientTop, Color.setflowBgGradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Confetti only for a genuinely completed workout — a partial
            // session gets a calmer, honest "saved" treatment.
            if isWin {
                ConfettiView(trigger: fireConfetti)
                    .ignoresSafeArea()
                    .zIndex(2)
            }

            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 20)

                    // Hero
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(isWin ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                                .frame(width: 96, height: 96)
                                .scaleEffect(heroIn ? 1 : 0.5)

                            Image(systemName: isWin ? "trophy.fill" : "flag.fill")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundColor(isWin ? .green : .orange)
                                .scaleEffect(heroIn ? 1 : 0.3)
                                .rotationEffect(.degrees(heroIn ? 0 : -18))
                        }

                        VStack(spacing: 6) {
                            Text(isWin ? "Workout Complete!" : "Session Saved")
                                .font(.title.bold())
                                .foregroundColor(.primary)

                            Text(summary.routineName)
                                .font(.subheadline)
                                .foregroundColor(.primary.opacity(0.6))
                        }
                        .opacity(heroIn ? 1 : 0)
                        .offset(y: heroIn ? 0 : 8)
                    }

                    // Streak — animates the number up for a little dopamine hit
                    if summary.streak > 0 {
                        HStack(spacing: 8) {
                            Text("🔥")
                            Text("\(displayStreak) Day Streak")
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                                .contentTransition(.numericText())
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                        .scaleEffect(contentIn ? 1 : 0.8)
                        .opacity(contentIn ? 1 : 0)
                    }

                    // Stats row
                    HStack(spacing: 0) {
                        statCell(value: summary.durationText, label: "Duration")
                        divider
                        statCell(value: "\(summary.totalSets)", label: "Total Sets")
                        divider
                        statCell(value: "\(summary.totalReps)", label: "Total Reps")
                    }
                    .padding(.vertical, 18)
                    .background(Color.cardPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .opacity(contentIn ? 1 : 0)
                    .offset(y: contentIn ? 0 : 12)

                    // Exercise breakdown
                    VStack(alignment: .leading, spacing: 10) {
                        Text("EXERCISES")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.primary.opacity(0.4))
                            .tracking(1)
                            .padding(.horizontal, 4)

                        VStack(spacing: 8) {
                            ForEach(summary.results) { result in
                                exerciseRow(result)
                            }
                        }
                    }
                    .opacity(contentIn ? 1 : 0)
                    .offset(y: contentIn ? 0 : 12)

                    Spacer(minLength: 12)

                    VStack(spacing: 12) {
                        Button {
                            isRendering = true
                            Task { @MainActor in
                                shareImage  = ShareManager.shareImage(for: summary)
                                isRendering = false
                                showShareSheet = true
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if isRendering {
                                    SwiftUI.ProgressView().tint(.white).scaleEffect(0.8)
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                Text("Share Workout")
                            }
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 18).fill(Color.blue))
                        }
                        .buttonStyle(.plain)

                        Button { vm.clearSessionSummary() } label: {
                            Text("Done")
                                .font(.subheadline)
                                .foregroundColor(.primary.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage { ShareSheet(items: [img]) }
        }
        .onAppear { runCelebration() }
    }

    private func runCelebration() {
        // 1. Hero springs in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
            heroIn = true
        }
        // 2. Confetti bursts just after the hero lands (wins only)
        if isWin {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                fireConfetti = true
                Haptics.sessionComplete()
            }
        }
        // 3. Stats + streak fade in
        withAnimation(.easeOut(duration: 0.4).delay(0.35)) {
            contentIn = true
        }
        // 4. Streak number counts up
        if summary.streak > 0 {
            let target = summary.streak
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateStreakCount(to: target)
            }
        }
    }

    private func animateStreakCount(to target: Int) {
        // Count up quickly; caps the number of steps so a big streak still lands fast.
        let steps = min(target, 12)
        guard steps > 0 else { displayStreak = target; return }
        for i in 1...steps {
            let value = Int(round(Double(target) * Double(i) / Double(steps)))
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                withAnimation(.easeOut(duration: 0.1)) { displayStreak = value }
            }
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.primary)
            Text(label)
                .font(.caption)
                .foregroundColor(.primary.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.1))
            .frame(width: 1, height: 36)
    }

    private func exerciseRow(_ result: SessionExerciseResult) -> some View {
        let finished = result.completedSets >= result.sets
        let actualReps = result.totalReps > 0 ? result.totalReps : result.completedSets * result.reps
        let weightText = result.averageWeight.map { w -> String in
            w.truncatingRemainder(dividingBy: 1) == 0
                ? " · \(Int(w))kg avg"
                : String(format: " · %.1fkg avg", w)
        } ?? ""

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(finished ? Color.blue.opacity(0.2) : Color.primary.opacity(0.06))
                    .frame(width: 36, height: 36)

                Image(systemName: finished ? "checkmark" : "minus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(finished ? .blue : .primary.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(result.exerciseName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Text("\(result.completedSets)/\(result.sets) sets · \(result.reps) reps each\(weightText)")
                    .font(.caption)
                    .foregroundColor(.primary.opacity(0.45))
            }

            Spacer()

            Text("\(actualReps) reps")
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cardPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
