import SwiftUI

struct BodyMetricsView: View {
    var vm: WorkoutViewModel
    @State private var showAddSheet = false
    @State private var newWeight: Double = 70
    @State private var newNotes: String  = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.setflowBg.ignoresSafeArea()

                if vm.bodyMetrics.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            currentWeightCard
                                .padding(.horizontal)
                            if vm.bodyMetrics.count >= 2 {
                                weightChart
                                    .padding(.horizontal)
                            }
                            logSection
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Body Metrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Log weight")
                }
            }
            .sheet(isPresented: $showAddSheet) {
                addWeightSheet
            }
        }
    }

    // MARK: - Current Weight Card

    private var currentWeightCard: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Current Weight")
                    .font(.subheadline).foregroundColor(.primary.opacity(0.55))
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(weightStr(vm.latestWeight ?? 0))
                        .font(.system(.largeTitle, design: .rounded).bold())
                        .foregroundColor(.primary)
                    Text("kg").font(.headline).foregroundColor(.primary.opacity(0.5))
                }
                if let trend = vm.weightTrend {
                    HStack(spacing: 4) {
                        Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption.weight(.bold))
                        Text(String(format: "%.1f kg from last entry", abs(trend)))
                            .font(.caption)
                    }
                    .foregroundColor(trend >= 0 ? .setflowRest : .setflowSuccess)
                }
            }
            Spacer()

            Button { showAddSheet = true } label: {
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32)).foregroundColor(.setflowAccent)
                    Text("Log").font(.caption.weight(.semibold)).foregroundColor(.setflowAccent)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .setflowCard()
    }

    // MARK: - Weight Chart

    private var weightChart: some View {
        let metrics  = Array(vm.bodyMetrics.prefix(12).reversed())
        let weights  = metrics.map(\.weightKg)
        let minW     = (weights.min() ?? 0) - 2
        let maxW     = (weights.max() ?? 100) + 2
        let range    = max(maxW - minW, 1)

        return VStack(alignment: .leading, spacing: 14) {
            Text("WEIGHT TREND")
                .font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.4)).tracking(1)

            GeometryReader { geo in
                ZStack {
                    // Grid lines
                    ForEach(0..<4) { i in
                        let y = geo.size.height * CGFloat(i) / 3
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: geo.size.width, y: y))
                        }
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    }

                    // Line
                    if metrics.count >= 2 {
                        Path { path in
                            for (i, metric) in metrics.enumerated() {
                                let x = geo.size.width * CGFloat(i) / CGFloat(metrics.count - 1)
                                let y = geo.size.height * (1 - CGFloat((metric.weightKg - minW) / range))
                                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else       { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .stroke(Color.setflowAccent, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                        // Dots
                        ForEach(Array(metrics.enumerated()), id: \.offset) { i, metric in
                            let x = geo.size.width * CGFloat(i) / CGFloat(metrics.count - 1)
                            let y = geo.size.height * (1 - CGFloat((metric.weightKg - minW) / range))
                            Circle()
                                .fill(Color.setflowAccent)
                                .frame(width: 6, height: 6)
                                .position(x: x, y: y)
                        }
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(16)
        .setflowCard()
    }

    // MARK: - Log

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LOG")
                .font(.caption.weight(.semibold)).foregroundColor(.primary.opacity(0.4)).tracking(1)

            VStack(spacing: 0) {
                ForEach(Array(vm.bodyMetrics.prefix(20).enumerated()), id: \.element.id) { i, metric in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(weightStr(metric.weightKg) + " kg")
                                .font(.subheadline.weight(.semibold)).foregroundColor(.primary)
                            if !metric.notes.isEmpty {
                                Text(metric.notes).font(.caption).foregroundColor(.primary.opacity(0.45))
                            }
                        }
                        Spacer()
                        Text(metric.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption).foregroundColor(.primary.opacity(0.4))
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(i % 2 == 0 ? Color.primary.opacity(0.04) : Color.clear)
                    .swipeActions {
                        Button(role: .destructive) { vm.deleteBodyMetric(metric) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.07), lineWidth: 1))
        }
    }

    // MARK: - Add Sheet

    private var addWeightSheet: some View {
        NavigationStack {
            ZStack {
                Color.setflowBgCard.ignoresSafeArea()
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text(weightStr(newWeight) + " kg")
                            .font(.system(.largeTitle, design: .rounded).bold())
                            .foregroundColor(.primary)
                            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                        Slider(value: $newWeight, in: 30...250, step: 0.5)
                            .tint(.setflowAccent)
                        HStack {
                            Text("30").font(.caption).foregroundColor(.primary.opacity(0.4))
                            Spacer()
                            Text("250").font(.caption).foregroundColor(.primary.opacity(0.4))
                        }
                    }
                    .padding(20)
                    .background(Color.primary.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    TextField("Notes (optional)", text: $newNotes)
                        .font(.body).foregroundColor(.primary).tint(.setflowAccent)
                        .padding().background(Color.primary.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    Spacer()

                    Button {
                        vm.addBodyMetric(BodyMetric(weightKg: newWeight, notes: newNotes))
                        Haptics.saved()
                        showAddSheet = false
                        newNotes = ""
                    } label: {
                        Text("Save Entry")
                            .font(.headline.weight(.semibold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.setflowAccent))
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddSheet = false }.foregroundColor(.primary.opacity(0.7))
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Color.setflowAccent.opacity(0.12)).frame(width: 88, height: 88)
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 32, weight: .semibold)).foregroundColor(.setflowAccent)
            }
            VStack(spacing: 8) {
                Text("No Metrics Yet").font(.title3.bold()).foregroundColor(.primary)
                Text("Track your body weight over time to correlate with your training.")
                    .font(.subheadline).foregroundColor(.primary.opacity(0.6))
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }
            Button { showAddSheet = true } label: {
                Label("Log First Entry", systemImage: "plus")
                    .fontWeight(.semibold).foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.setflowAccent))
            }
            .buttonStyle(.plain)
        }
    }

    private func weightStr(_ kg: Double) -> String {
        kg.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(kg))" : String(format: "%.1f", kg)
    }
}
