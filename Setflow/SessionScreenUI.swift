import SwiftUI
import Combine

struct SessionScreenUI: View {
    var vm: WorkoutViewModel
    @State private var pulseRing    = false
    @State private var showEndConfirm = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            LinearGradient(
                colors: [Color.setflowBgGradientTop, Color.setflowBgGradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Main content — always visible
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal)
                    .padding(.top, 8)

                progressBar
                    .padding(.horizontal)
                    .padding(.top, 12)

                Spacer()

                exerciseDisplay

                Spacer()

                if let next = vm.nextRoutineExercise, !vm.isResting, vm.pendingSetLog == nil {
                    upNextBanner(next)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }

                actionButtons
                    .padding(.horizontal)
                    .padding(.bottom, 28)
            }
            // Dim background when log overlay is showing
            .overlay(
                vm.pendingSetLog != nil
                    ? Color.black.opacity(0.45).ignoresSafeArea()
                    : nil
            )

            // Log overlay — slides up from bottom during rest
            if let ex = vm.currentRoutineExercise,
               vm.pendingSetLog != nil {
                @Bindable var bindableVM = vm
                InlineSetLogView(
                    vm: vm,
                    log: Binding(
                        get: { vm.pendingSetLog ?? SetLog(setNumber: 1, reps: ex.reps, weight: nil) },
                        set: { vm.pendingSetLog = $0 }
                    ),
                    exercise: ex,
                    isLastSet: vm.isFinishingLastSet,
                    onConfirm: { vm.confirmSetLog($0) },
                    onDismiss: { vm.dismissSetLog() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: vm.pendingSetLog != nil)
        .confirmationDialog("End Workout?", isPresented: $showEndConfirm, titleVisibility: .visible) {
            Button("End & Save Progress", role: .destructive) { vm.endSessionEarly() }
            Button("Keep Going", role: .cancel) { }
        } message: {
            Text("Your completed sets will be saved.")
        }
        .onChange(of: vm.restCountdown) { _, newValue in
            if newValue == 0 { pulse() }
        }
        .onAppear { vm.processSiriCommandIfNeeded() }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if !vm.isResting { vm.processSiriCommandIfNeeded() }
        }
    }

    private var hasProgress: Bool {
        !vm.sessionResults.isEmpty || !vm.currentSetLogs.isEmpty || vm.pendingSetLog != nil
    }

    private func handleCancelTap() {
        if hasProgress {
            // Some work exists — treat like End Workout, ask and save
            showEndConfirm = true
        } else {
            // Nothing done at all — exit immediately, nothing to save or confirm
            vm.discardEmptySession()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { handleCancelTap() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Circle())
            }
            .accessibilityLabel("End session")

            Spacer()

            VStack(spacing: 2) {
                Text(vm.activeRoutine?.name ?? "Workout")
                    .font(.subheadline.weight(.semibold)).foregroundColor(.primary)
                Text("\(vm.currentExerciseIndex + 1) of \(vm.sessionExercises.count)")
                    .font(.caption).foregroundColor(.primary.opacity(0.5))
            }

            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3).fill(Color.primary.opacity(0.08)).frame(height: 4)
                RoundedRectangle(cornerRadius: 3).fill(Color.setflowAccent)
                    .frame(width: geo.size.width * sessionProgressFraction, height: 4)
                    .animation(.easeInOut(duration: 0.4), value: sessionProgressFraction)
            }
        }
        .frame(height: 4)
    }

    private var sessionProgressFraction: Double {
        guard !vm.sessionExercises.isEmpty else { return 0 }
        let exFrac = Double(vm.currentExerciseIndex) / Double(vm.sessionExercises.count)
        if let ex = vm.currentRoutineExercise, ex.sets > 0 {
            let setFrac = Double(vm.currentSet - 1) / Double(ex.sets)
            return exFrac + setFrac / Double(vm.sessionExercises.count)
        }
        return exFrac
    }

    // MARK: - Exercise Display

    private var exerciseDisplay: some View {
        VStack(spacing: 28) {
            if let ex = vm.currentRoutineExercise {
                VStack(spacing: 10) {
                    Text(ex.name)
                        .font(.title.bold())
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                        .id(ex.id)

                    Text(vm.isResting ? "Rest Time" : "Set \(vm.currentSet) of \(ex.sets)")
                        .font(.subheadline)
                        .foregroundColor(.primary.opacity(0.6))
                }

                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.10), lineWidth: 16)
                        .frame(width: 210, height: 210)

                    Circle()
                        .trim(from: 0, to: ringProgress(ex: ex))
                        .stroke(
                            vm.isFinishingExercise ? Color.setflowSuccess :
                            vm.isResting ? Color.setflowRest : Color.setflowAccent,
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 210, height: 210)
                        .scaleEffect(pulseRing ? 1.04 : 1.0)
                        .animation(.linear(duration: 0.9), value: vm.restCountdown)
                        .animation(.easeInOut(duration: 0.35), value: vm.currentSet)
                        .animation(.easeOut(duration: 0.3), value: pulseRing)

                    ringContent(ex: ex)
                }

                setDots(ex: ex)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.currentExerciseIndex)
    }

    private func ringContent(ex: RoutineExercise) -> some View {
        Group {
            if vm.isFinishingExercise {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold)).foregroundColor(.setflowSuccess)
                    Text("Done!").font(.headline).foregroundColor(.primary.opacity(0.75))
                }
                .transition(.scale.combined(with: .opacity))
            } else if vm.isResting {
                VStack(spacing: 6) {
                    Text("\(vm.restCountdown)")
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        .monospacedDigit().foregroundColor(.setflowRest)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.25), value: vm.restCountdown)
                    Text("seconds").font(.headline).foregroundColor(.primary.opacity(0.6))
                }
            } else {
                VStack(spacing: 6) {
                    Text("\(ex.reps)")
                        .font(.system(.largeTitle).weight(.heavy)).foregroundColor(.primary)
                    Text("reps").font(.headline).foregroundColor(.primary.opacity(0.6))
                }
            }
        }
        // This ring is a fixed 210pt circle and the most-viewed number in the
        // app mid-session — capped rather than left to scale freely so a large
        // accessibility text size can't push the countdown past the ring edge.
        .dynamicTypeSize(...DynamicTypeSize.large)
    }

    private func setDots(ex: RoutineExercise) -> some View {
        HStack(spacing: 8) {
            ForEach(1...max(1, ex.sets), id: \.self) { i in
                Circle()
                    .fill(i < vm.currentSet ? Color.setflowAccent :
                          i == vm.currentSet ? Color.primary : Color.primary.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: vm.currentSet)
            }
        }
    }

    // MARK: - Up Next Banner

    private func upNextBanner(_ next: RoutineExercise) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.right.circle.fill")
                .foregroundColor(.primary.opacity(0.3)).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("UP NEXT").font(.caption2.weight(.semibold))
                    .foregroundColor(.primary.opacity(0.35)).tracking(1)
                Text(next.name).font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary.opacity(0.65))
            }
            Spacer()
            Text("\(next.sets) × \(next.reps)").font(.caption.weight(.semibold))
                .foregroundColor(.primary.opacity(0.4))
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if vm.isResting {
                Button(vm.isPaused ? "Resume Rest" : "Pause Rest") {
                    vm.togglePause()
                }
                .buttonStyle(.bordered).tint(.setflowRest).controlSize(.large)
            } else if !vm.isFinishingExercise && !vm.isFinishingLastSet {
                Button("Complete Set") {
                    vm.completeSessionSet()
                }
                .buttonStyle(.borderedProminent).tint(.setflowAccent).controlSize(.large)
            }

            Button("End Workout") { showEndConfirm = true }
                .foregroundColor(.red.opacity(0.75)).font(.subheadline)
        }
    }

    // MARK: - Helpers

    private func ringProgress(ex: RoutineExercise) -> Double {
        if vm.isFinishingExercise { return 1.0 }
        if vm.isResting { return Double(vm.restCountdown) / Double(max(ex.restSeconds, 1)) }
        guard ex.sets > 0 else { return 0 }
        return Double(vm.currentSet - 1) / Double(ex.sets)
    }

    private func pulse() {
        pulseRing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { pulseRing = false }
    }
}

// MARK: - Inline Set Log View
// Non-blocking overlay that slides up from the bottom during rest.
// The timer continues running above it.

struct InlineSetLogView: View {
    var vm: WorkoutViewModel
    @Binding var log: SetLog
    let exercise: RoutineExercise
    let isLastSet: Bool
    let onConfirm: (SetLog) -> Void
    let onDismiss: () -> Void

    @State private var reps: Int
    @State private var weight: Double
    @State private var customRest: Int
    @State private var isWarmup: Bool
    @State private var rpe: Int?
    @State private var showPlateCalc = false

    private let isWeighted: Bool
    private let lastResult: SessionExerciseResult?

    init(vm: WorkoutViewModel, log: Binding<SetLog>, exercise: RoutineExercise,
         isLastSet: Bool, onConfirm: @escaping (SetLog) -> Void, onDismiss: @escaping () -> Void) {
        self.vm        = vm
        self._log      = log
        self.exercise  = exercise
        self.isLastSet = isLastSet
        self.onConfirm = onConfirm
        self.onDismiss = onDismiss
        self.isWeighted  = exercise.tracking == .weighted
        self.lastResult  = vm.lastResult(for: exercise.exerciseID)
        self._reps       = State(initialValue: log.wrappedValue.reps)
        self._weight     = State(initialValue: log.wrappedValue.weight ?? exercise.defaultWeight)
        self._customRest = State(initialValue: exercise.restSeconds)
        self._isWarmup   = State(initialValue: log.wrappedValue.isWarmup)
        self._rpe        = State(initialValue: log.wrappedValue.rpe)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.primary.opacity(0.25))
                .frame(width: 40, height: 4)
                .padding(.top, 14)
                .padding(.bottom, 16)

            // Header — shows rest context
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("Set \(log.setNumber) of \(exercise.sets)")
                            .font(.headline).foregroundColor(.primary)

                        Button {
                            isWarmup.toggle()
                            Haptics.selection()
                        } label: {
                            Text(isWarmup ? "Warm-up" : "Working")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(isWarmup ? .setflowRest : .primary.opacity(0.4))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(isWarmup ? Color.setflowRest.opacity(0.15) : Color.primary.opacity(0.07))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    Text(isLastSet
                         ? "Last set — log to finish this exercise"
                         : "Log while you rest")
                        .font(.caption)
                        .foregroundColor(isLastSet ? .setflowSuccess.opacity(0.9) : .primary.opacity(0.5))
                }
                Spacer()

                // Last session reference
                if let last = lastResult,
                   let lastLog = last.setLogs.first(where: { $0.setNumber == log.setNumber }) {
                    Button {
                        reps = lastLog.reps
                        if let w = lastLog.weight { weight = w }
                        Haptics.selection()
                    } label: {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Last time").font(.caption2).foregroundColor(.primary.opacity(0.35))
                            Text(lastLog.weight.map { "\(weightStr($0)) × \(lastLog.reps)" } ?? "\(lastLog.reps) reps")
                                .font(.caption.weight(.semibold)).foregroundColor(.setflowAccent)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("First time").font(.caption2).foregroundColor(.primary.opacity(0.3))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            Divider().background(Color.primary.opacity(0.08))

            // Inputs
            HStack(spacing: 16) {
                // Reps
                VStack(spacing: 8) {
                    Text("REPS").font(.caption2.weight(.semibold))
                        .foregroundColor(.primary.opacity(0.4)).tracking(1)
                    HStack(spacing: 12) {
                        smallStepper("minus", label: "Decrease reps") { reps = max(1, reps - 1) }
                        Text("\(reps)")
                            .font(.system(.title2, design: .rounded).bold())
                            .foregroundColor(.primary).frame(minWidth: 44).multilineTextAlignment(.center)
                            .contentTransition(.numericText()).animation(.easeInOut(duration: 0.12), value: reps)
                        smallStepper("plus", label: "Increase reps") { reps += 1 }
                    }
                }
                .frame(maxWidth: .infinity)

                if isWeighted {
                    Rectangle().fill(Color.primary.opacity(0.08)).frame(width: 1, height: 60)

                    // Weight
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Text("WEIGHT").font(.caption2.weight(.semibold))
                                .foregroundColor(.primary.opacity(0.4)).tracking(1)
                            Button { showPlateCalc = true } label: {
                                Image(systemName: "square.stack.3d.up")
                                    .font(.caption2).foregroundColor(.setflowAccent.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Plate calculator")
                            .sheet(isPresented: $showPlateCalc) {
                                PlateCalculatorView(targetWeight: weight)
                            }
                        }
                        HStack(spacing: 8) {
                            Button { weight = max(0, weight - 2.5) } label: {
                                Text("-2.5").font(.caption2.weight(.semibold))
                                    .foregroundColor(.primary.opacity(0.5))
                                    .padding(.horizontal, 6).padding(.vertical, 4)
                                    .background(Color.primary.opacity(0.07)).clipShape(Capsule())
                            }.buttonStyle(.plain)

                            Text(weightStr(weight))
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(.primary).frame(minWidth: 52).multilineTextAlignment(.center)
                                .contentTransition(.numericText()).animation(.easeInOut(duration: 0.12), value: weight)

                            Button { weight += 2.5 } label: {
                                Text("+2.5").font(.caption2.weight(.semibold))
                                    .foregroundColor(.primary.opacity(0.5))
                                    .padding(.horizontal, 6).padding(.vertical, 4)
                                    .background(Color.primary.opacity(0.07)).clipShape(Capsule())
                            }.buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)

            // RPE (optional)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("RPE").font(.caption2.weight(.semibold))
                        .foregroundColor(.primary.opacity(0.4)).tracking(1)
                    Text("optional").font(.caption2).foregroundColor(.primary.opacity(0.25))
                    Spacer()
                    if rpe != nil {
                        Button {
                            rpe = nil
                            Haptics.selection()
                        } label: {
                            Text("Clear").font(.caption2.weight(.semibold)).foregroundColor(.primary.opacity(0.35))
                        }
                        .buttonStyle(.plain)
                    }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(1...10, id: \.self) { value in
                            Button {
                                rpe = value
                                Haptics.selection()
                            } label: {
                                Text("\(value)")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(rpe == value ? .white : .primary.opacity(0.4))
                                    .frame(width: 30, height: 30)
                                    .background(rpe == value ? Color.setflowAccent : Color.primary.opacity(0.06))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Rest override (only for non-last sets)
            if !isLastSet {
                HStack(spacing: 10) {
                    Image(systemName: "timer").font(.caption).foregroundColor(.primary.opacity(0.35))
                    Text("Rest").font(.caption).foregroundColor(.primary.opacity(0.5))
                    Spacer()
                    ForEach([30, 60, 90, 120], id: \.self) { sec in
                        Button {
                            customRest = sec
                            Haptics.selection()
                        } label: {
                            Text("\(sec)s").font(.caption2.weight(.semibold))
                                .foregroundColor(customRest == sec ? .white : .primary.opacity(0.35))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(customRest == sec ? Color.setflowAccent : Color.primary.opacity(0.06))
                                .clipShape(Capsule())
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }

            // Confirm button
            Button { confirm() } label: {
                Text(isLastSet ? "Log & Finish Exercise" : "Log Set")
                    .font(.headline.weight(.semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14)
                        .fill(isLastSet ? Color.setflowSuccess : Color.setflowAccent))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.setflowBgCard)
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: -4)
        )
    }

    private func smallStepper(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(.primary)
                .frame(width: 36, height: 36).background(Color.primary.opacity(0.1)).clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func confirm() {
        Haptics.setConfirmed()
        var updated        = log
        updated.reps       = reps
        updated.weight     = isWeighted ? weight : nil
        updated.customRest = isLastSet ? nil : customRest
        updated.isWarmup   = isWarmup
        updated.rpe        = rpe
        onConfirm(updated)
    }

    private func weightStr(_ kg: Double) -> String {
        kg.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(kg))kg" : String(format: "%.1fkg", kg)
    }
}
