import SwiftUI

struct PlateCalculatorView: View {
    @State var targetWeight: Double
    @State private var barWeight: Double = 20   // standard Olympic bar
    @Environment(\.dismiss) private var dismiss

    // Standard plate sizes in kg
    private let availablePlates: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]

    var platesPerSide: [(weight: Double, count: Int)] {
        var remaining = max(0, (targetWeight - barWeight)) / 2
        var result: [(Double, Int)] = []

        for plate in availablePlates {
            if remaining <= 0 { break }
            let count = Int(remaining / plate)
            if count > 0 {
                result.append((plate, count))
                remaining -= Double(count) * plate
            }
        }
        return result
    }

    var totalLoaded: Double {
        barWeight + platesPerSide.reduce(0) { $0 + $1.weight * Double($1.count) * 2 }
    }

    var isExact: Bool { abs(totalLoaded - targetWeight) < 0.01 }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.setflowBgCard.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Target weight
                    VStack(spacing: 8) {
                        Text("TARGET WEIGHT")
                            .font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.4)).tracking(1)
                        HStack(spacing: 16) {
                            Button { targetWeight = max(barWeight, targetWeight - 2.5) } label: {
                                Image(systemName: "minus").font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary).frame(width: 44, height: 44)
                                    .background(Color.primary.opacity(0.1)).clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Decrease target weight by 2.5 kg")

                            Text(wtStr(targetWeight) + " kg")
                                .font(.system(.largeTitle, design: .rounded).bold())
                                .foregroundColor(.primary).frame(minWidth: 120).multilineTextAlignment(.center)
                                .contentTransition(.numericText()).animation(.easeInOut(duration: 0.15), value: targetWeight)
                                .dynamicTypeSize(...DynamicTypeSize.xxLarge)

                            Button { targetWeight += 2.5 } label: {
                                Image(systemName: "plus").font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary).frame(width: 44, height: 44)
                                    .background(Color.primary.opacity(0.1)).clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Increase target weight by 2.5 kg")
                        }
                    }
                    .padding(20)
                    .background(Color.cardPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    // Bar weight
                    HStack {
                        Text("Bar weight")
                            .font(.subheadline).foregroundColor(.primary.opacity(0.6))
                        Spacer()
                        HStack(spacing: 0) {
                            ForEach([15.0, 20.0, 25.0], id: \.self) { w in
                                Button {
                                    barWeight = w
                                    Haptics.selection()
                                } label: {
                                    Text("\(Int(w))kg")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(barWeight == w ? .white : .primary.opacity(0.45))
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(barWeight == w ? Color.setflowAccent : Color.primary.opacity(0.07))
                                }
                                .buttonStyle(.plain)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(.horizontal, 4)

                    // Plates per side
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("PLATES PER SIDE")
                                .font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.4)).tracking(1)
                            Spacer()
                            Text(isExact ? "✓ Exact" : "≈ \(wtStr(totalLoaded))kg loaded")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(isExact ? .setflowSuccess : .setflowRest)
                        }

                        if platesPerSide.isEmpty {
                            Text("Bar only — no plates needed")
                                .font(.subheadline).foregroundColor(.primary.opacity(0.45))
                                .padding(.vertical, 8)
                        } else {
                            HStack(spacing: 8) {
                                ForEach(platesPerSide, id: \.weight) { plate in
                                    VStack(spacing: 4) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(plateColor(plate.weight).opacity(0.2))
                                                .frame(width: 52, height: 64)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                                )
                                            VStack(spacing: 2) {
                                                Text(wtStr(plate.weight))
                                                    .font(.system(.caption, design: .rounded).bold())
                                                    .foregroundColor(.primary)
                                                Text("kg").font(.caption2).foregroundColor(.primary.opacity(0.5))
                                            }
                                            .dynamicTypeSize(...DynamicTypeSize.large)
                                        }
                                        Text("×\(plate.count)")
                                            .font(.caption.weight(.bold)).foregroundColor(.primary.opacity(0.6))
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.cardPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Plate Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(24)
    }

    private func wtStr(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)
    }

    private func plateColor(_ w: Double) -> Color {
        switch w {
        case 25:   return .red
        case 20:   return .blue
        case 15:   return .yellow
        case 10:   return .green
        case 5:    return .white
        default:   return .gray
        }
    }
}
