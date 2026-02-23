import SwiftUI

struct SetLogSheet: View {
    var vm: WorkoutViewModel
    @Binding var log: SetLog
    let exercise: RoutineExercise
    let onConfirm: (SetLog) -> Void
    let onDismiss: () -> Void

    @State private var reps: Int
    @State private var weight: Double
    @State private var customRest: Int
    @State private var showPlateCalc: Bool = false
    @FocusState private var weightFocused: Bool

    private let isWeighted: Bool
    private let lastResult: SessionExerciseResult?
    private let isLastSet: Bool

    init(vm: WorkoutViewModel, log: Binding<SetLog>, exercise: RoutineExercise,
         onConfirm: @escaping (SetLog) -> Void, onDismiss: @escaping () -> Void) {
        self.vm        = vm
        self._log      = log
        self.exercise  = exercise
        self.onConfirm = onConfirm
        self.onDismiss = onDismiss
        self.isWeighted   = exercise.tracking == .weighted
        self.isLastSet    = log.wrappedValue.setNumber >= exercise.sets
        self.lastResult   = vm.lastResult(for: exercise.exerciseID)
        self._reps        = State(initialValue: log.wrappedValue.reps)
        self._weight      = State(initialValue: log.wrappedValue.weight ?? exercise.defaultWeight)
        self._customRest  = State(initialValue: exercise.restSeconds)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Header
            VStack(spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Set \(log.setNumber) of \(exercise.sets)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.55))
            }
            .padding(.bottom, 20)

            // Last session reference OR first-session hint
            if let last = lastResult,
               let lastLog = last.setLogs.first(where: { $0.setNumber == log.setNumber }) {
                lastSessionRow(lastLog)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            } else if lastResult == nil {
                firstSessionHint
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }

            // Input fields
            VStack(spacing: 12) {
                repsRow
                if isWeighted { weightRow }
                if !isLastSet { restRow }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 20)

            // Confirm button
            Button { confirm() } label: {
                Text(isLastSet ? "Log & Finish Exercise" : "Log & Rest \(customRest)s")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.blue))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.14))
        .presentationDetents(isWeighted ? [.height(500)] : [.height(420)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    // MARK: - Sub-views

    private var firstSessionHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundColor(.blue.opacity(0.7))
            Text(isWeighted
                 ? "Suggested start: \(weightString(exercise.defaultWeight)) — adjust any time"
                 : "Log your actual reps — we'll remember for next time")
                .font(.caption)
                .foregroundColor(.white.opacity(0.45))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func lastSessionRow(_ lastLog: SetLog) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
            Text("Last: \(lastLog.reps) reps\(lastLog.weight.map { " · \(weightString($0))" } ?? "")")
                .font(.caption)
                .foregroundColor(.white.opacity(0.45))
            Spacer()
            Button("Use") {
                reps = lastLog.reps
                if let w = lastLog.weight { weight = w }
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(.blue)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var repsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("REPS")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1)
            HStack(spacing: 16) {
                stepperButton(icon: "minus") { reps = max(1, reps - 1) }
                Text("\(reps)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(minWidth: 60)
                    .multilineTextAlignment(.center)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: reps)
                stepperButton(icon: "plus") { reps += 1 }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var weightRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("WEIGHT (KG)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)
                Spacer()
                Button {
                    showPlateCalc = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.stack.3d.up")
                            .font(.caption)
                        Text("Plates")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(.setflowAccent.opacity(0.8))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showPlateCalc) {
                    PlateCalculatorView(targetWeight: weight)
                }
            }
            HStack(spacing: 12) {
                quickWeightButton(-5)
                quickWeightButton(-2.5)
                Spacer()
                Text(weightString(weight))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(minWidth: 80)
                    .multilineTextAlignment(.center)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: weight)
                Spacer()
                quickWeightButton(2.5)
                quickWeightButton(5)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var restRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.4))
            Text("Rest")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            ForEach([30, 60, 90, 120], id: \.self) { sec in
                Button {
                    customRest = sec
                    Haptics.selection()
                } label: {
                    Text("\(sec)s")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(customRest == sec ? .white : .white.opacity(0.4))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(customRest == sec ? Color.blue : Color.white.opacity(0.07))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: customRest)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func stepperButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func quickWeightButton(_ delta: Double) -> some View {
        Button { weight = max(0, weight + delta) } label: {
            Text(delta > 0 ? "+\(weightString(delta))" : weightString(delta))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func weightString(_ kg: Double) -> String {
        kg.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(kg))kg" : String(format: "%.1fkg", kg)
    }

    private func confirm() {
        Haptics.setConfirmed()
        var updated        = log
        updated.reps       = reps
        updated.weight     = isWeighted ? weight : nil
        updated.customRest = isLastSet ? nil : customRest
        onConfirm(updated)
    }
}
