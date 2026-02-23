import SwiftUI

struct WorkoutScreenUI: View {
    var vm: WorkoutViewModel
    let exercise: Exercise

    @State private var pulseRing = false

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

            VStack(spacing: 28) {
                topBar

                Spacer()

                VStack(spacing: 14) {
                    Text(exercise.name)
                        .font(.title.bold())
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text(vm.isResting ? "Rest Time" : "Workout in Progress")
                        .font(.subheadline)
                        .foregroundColor(.primary.opacity(0.65))
                }

                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.12), lineWidth: 16)
                        .frame(width: 210, height: 210)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            vm.isFinishingWorkout ? Color.green : (vm.isResting ? Color.orange : Color.blue),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 210, height: 210)
                        .scaleEffect(pulseRing ? 1.04 : 1.0)
                        .opacity(pulseRing ? 0.9 : 1.0)
                        .animation(.linear(duration: 0.9), value: vm.restCountdown)
                        .animation(.easeInOut(duration: 0.35), value: vm.currentSet)
                        .animation(.easeOut(duration: 0.35), value: pulseRing)

                    VStack(spacing: 8) {
                        if vm.isFinishingWorkout {
                            Image(systemName: "checkmark")
                                .font(.system(size: 56, weight: .bold))
                                .foregroundColor(.green)
                                .transition(.scale.combined(with: .opacity))

                            Text("Complete")
                                .font(.headline)
                                .foregroundColor(.primary.opacity(0.75))

                        } else if vm.isResting {
                            Text("\(vm.restCountdown)")
                                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                                .monospacedDigit()
                                .foregroundColor(.orange)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.25), value: vm.restCountdown)

                            Text("seconds")
                                .font(.headline)
                                .foregroundColor(.primary.opacity(0.65))

                        } else {
                            Text("\(exercise.reps)")
                                .font(.system(.largeTitle).weight(.heavy))
                                .foregroundColor(.primary)

                            Text("reps")
                                .font(.headline)
                                .foregroundColor(.primary.opacity(0.65))
                        }
                    }
                    // Fixed 210pt ring — capped so accessibility text sizes
                    // can't push the countdown/rep number past the ring edge.
                    .dynamicTypeSize(...DynamicTypeSize.large)
                }

                VStack(spacing: 6) {
                    Text("Set \(vm.currentSet) of \(exercise.sets)")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.primary)

                    Text("Rest: \(exercise.restSeconds)s")
                        .font(.subheadline)
                        .foregroundColor(.primary.opacity(0.6))
                }

                Spacer()

                VStack(spacing: 14) {
                    if vm.isResting {
                        Button(vm.isPaused ? "Resume Rest" : "Pause Rest") {
                            vm.togglePause()
                        }
                        .buttonStyle(.bordered)
                        .tint(.primary)
                        .controlSize(.large)
                    } else {
                        Button("Complete Set") {
                            vm.completeSet()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .controlSize(.large)
                    }

                    Button("End Workout") {
                        vm.finishWorkout()
                    }
                    .foregroundColor(.red.opacity(0.9))
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 80 && abs(value.translation.height) < 50 {
                        vm.finishWorkout()
                    }
                }
        )
        .onChange(of: vm.restCountdown) { _, newValue in
            if newValue == 0 {
                pulseRing = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    pulseRing = false
                }
            }
        }
    }

    private var ringProgress: Double {
        if vm.isFinishingWorkout {
            return 1.0
        } else if vm.isResting {
            let totalRest = max(exercise.restSeconds, 1)
            return Double(vm.restCountdown) / Double(totalRest)
        } else {
            guard exercise.sets > 0 else { return 0 }
            return Double(vm.currentSet - 1) / Double(exercise.sets)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                vm.finishWorkout()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                    .frame(width: 42, height: 42)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Circle())
            }
            .accessibilityLabel("End workout")

            Spacer()
        }
    }
}
