import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Palette

private enum RestPalette {
    static let active  = Color(red: 0.30, green: 0.66, blue: 1.0)   // calm blue
    static let paused  = Color(red: 1.0,  green: 0.62, blue: 0.25)  // warm amber
    static let resting = Color(red: 0.40, green: 0.90, blue: 0.55)  // soft green
    static let track   = Color.white.opacity(0.14)
    static let bg      = Color(red: 0.055, green: 0.06, blue: 0.10)
}

// MARK: - Continuous timer ring
// Driven by the system clock via TimelineView, so it sweeps smoothly at up to
// 30fps ON-DEVICE with no per-second push. Frozen to last-known value on pause.

private struct TimerRing: View {
    let start: Date
    let end: Date
    let isPaused: Bool
    let frozenRemaining: Int
    let total: Int
    let size: CGFloat
    let lineWidth: CGFloat
    var showGlow: Bool = false

    private var ringColor: Color { isPaused ? RestPalette.paused : RestPalette.active }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isPaused)) { timeline in
            let progress = currentProgress(at: timeline.date)
            ZStack {
                Circle().stroke(RestPalette.track, lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [ringColor.opacity(0.75), ringColor]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: showGlow ? ringColor.opacity(0.55) : .clear,
                            radius: showGlow ? 5 : 0)
            }
            .frame(width: size, height: size)
        }
    }

    private func currentProgress(at now: Date) -> Double {
        if isPaused { return Double(frozenRemaining) / Double(max(total, 1)) }
        let remaining = max(0, end.timeIntervalSince(now))
        return min(1, max(0, remaining / Double(max(total, 1))))
    }
}

// MARK: - Continuous countdown number
// Shows a plain integer second count, recomputed from the system clock so it
// stays in step with the ring. Avoids Text(timerInterval:)'s "0:45" mm:ss format
// which is too wide for the compact/minimal Dynamic Island rings.

private struct CountdownText: View {
    let start: Date
    let end: Date
    let isPaused: Bool
    let frozenRemaining: Int
    let font: Font

    var body: some View {
        Group {
            if isPaused {
                Text("\(frozenRemaining)").font(font).monospacedDigit().foregroundColor(.white)
            } else {
                TimelineView(.periodic(from: start, by: 1.0)) { timeline in
                    let remaining = max(0, Int(end.timeIntervalSince(timeline.date).rounded(.up)))
                    Text("\(remaining)")
                        .font(font)
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                }
            }
        }
    }
}

// MARK: - Set pips

private struct SetPips: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...max(total, 1), id: \.self) { i in
                Circle()
                    .fill(i < current ? RestPalette.active :
                          i == current ? Color.white :
                          Color.white.opacity(0.22))
                    .frame(width: 7, height: 7)
                    .scaleEffect(i == current ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: current)
            }
        }
    }
}

// MARK: - Continuous progress bar

private struct TimerBar: View {
    let start: Date
    let end: Date
    let isPaused: Bool
    let frozenRemaining: Int
    let total: Int
    let height: CGFloat

    private var barColor: Color { isPaused ? RestPalette.paused : RestPalette.active }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isPaused)) { timeline in
                let progress = progressValue(at: timeline.date)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(RestPalette.track)
                        .frame(height: height)

                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(LinearGradient(colors: [barColor.opacity(0.7), barColor],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progress, height: height)
                }
            }
        }
        .frame(height: height)
    }

    private func progressValue(at now: Date) -> Double {
        if isPaused { return Double(frozenRemaining) / Double(max(total, 1)) }
        let remaining = max(0, end.timeIntervalSince(now))
        return min(1, max(0, remaining / Double(max(total, 1))))
    }
}

// MARK: - Lock Screen / Banner

private struct LockScreenView: View {
    let context: ActivityViewContext<SetflowLiveActivityAttributes>
    private var s: SetflowLiveActivityAttributes.ContentState { context.state }

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle().fill(RestPalette.active.opacity(0.18)).frame(width: 36, height: 36)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(RestPalette.active)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(s.exerciseName).font(.headline).foregroundColor(.white).lineLimit(1)
                    Text(s.isPaused ? "Paused" : "Resting")
                        .font(.caption)
                        .foregroundColor(s.isPaused ? RestPalette.paused : RestPalette.resting)
                }

                Spacer()

                ZStack {
                    TimerRing(start: s.startDate, end: s.endDate,
                              isPaused: s.isPaused, frozenRemaining: s.secondsRemaining,
                              total: s.totalRestSeconds, size: 54, lineWidth: 4, showGlow: true)
                    VStack(spacing: 0) {
                        CountdownText(start: s.startDate, end: s.endDate,
                                      isPaused: s.isPaused, frozenRemaining: s.secondsRemaining,
                                      font: .system(size: 17, weight: .bold, design: .rounded))
                            .fixedSize()
                        Text("sec").font(.system(size: 9, weight: .medium)).foregroundColor(.white.opacity(0.5))
                    }
                }
            }

            TimerBar(start: s.startDate, end: s.endDate,
                     isPaused: s.isPaused, frozenRemaining: s.secondsRemaining,
                     total: s.totalRestSeconds, height: 4)

            HStack {
                Text("Sets").font(.caption2).foregroundColor(.white.opacity(0.45))
                SetPips(current: s.currentSet, total: s.totalSets)
                Spacer()
                Text("Set \(s.currentSet) of \(s.totalSets)")
                    .font(.caption2).foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .activityBackgroundTint(RestPalette.bg)
        .activitySystemActionForegroundColor(.white)
    }
}

// MARK: - Dynamic Island: Expanded

private struct ExpandedLeading: View {
    let context: ActivityViewContext<SetflowLiveActivityAttributes>
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(RestPalette.active.opacity(0.2)).frame(width: 32, height: 32)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(RestPalette.active)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.exerciseName)
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                Text(context.state.isPaused ? "Paused" : "Resting")
                    .font(.system(size: 11))
                    .foregroundColor(context.state.isPaused ? RestPalette.paused : RestPalette.resting)
            }
        }
        .padding(.leading, 4)
    }
}

private struct ExpandedTrailing: View {
    let context: ActivityViewContext<SetflowLiveActivityAttributes>
    private var s: SetflowLiveActivityAttributes.ContentState { context.state }
    var body: some View {
        ZStack {
            TimerRing(start: s.startDate, end: s.endDate,
                      isPaused: s.isPaused, frozenRemaining: s.secondsRemaining,
                      total: s.totalRestSeconds, size: 48, lineWidth: 4, showGlow: true)
            CountdownText(start: s.startDate, end: s.endDate,
                          isPaused: s.isPaused, frozenRemaining: s.secondsRemaining,
                          font: .system(size: 16, weight: .bold, design: .rounded))
                .fixedSize()
        }
        .padding(.trailing, 4)
    }
}

private struct ExpandedBottom: View {
    let context: ActivityViewContext<SetflowLiveActivityAttributes>
    private var s: SetflowLiveActivityAttributes.ContentState { context.state }
    var body: some View {
        VStack(spacing: 8) {
            TimerBar(start: s.startDate, end: s.endDate,
                     isPaused: s.isPaused, frozenRemaining: s.secondsRemaining,
                     total: s.totalRestSeconds, height: 3)
            HStack(spacing: 0) {
                Text("Set \(s.currentSet) of \(s.totalSets)")
                    .font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.6))
                Spacer()
                SetPips(current: s.currentSet, total: s.totalSets)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }
}

// MARK: - Dynamic Island: Compact

private struct CompactLeadingView: View {
    let context: ActivityViewContext<SetflowLiveActivityAttributes>
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(RestPalette.active)
            Text("Set \(context.state.currentSet)/\(context.state.totalSets)")
                .font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
        }
        .padding(.leading, 4)
    }
}

private struct CompactTrailingView: View {
    let context: ActivityViewContext<SetflowLiveActivityAttributes>
    private var s: SetflowLiveActivityAttributes.ContentState { context.state }
    var body: some View {
        ZStack {
            TimerRing(start: s.startDate, end: s.endDate,
                      isPaused: s.isPaused, frozenRemaining: s.secondsRemaining,
                      total: s.totalRestSeconds, size: 26, lineWidth: 2.5)
            CountdownText(start: s.startDate, end: s.endDate,
                          isPaused: s.isPaused, frozenRemaining: s.secondsRemaining,
                          font: .system(size: 10, weight: .bold, design: .rounded))
                .fixedSize()
        }
        .padding(.trailing, 4)
    }
}

// MARK: - Dynamic Island: Minimal

private struct MinimalView: View {
    let context: ActivityViewContext<SetflowLiveActivityAttributes>
    private var s: SetflowLiveActivityAttributes.ContentState { context.state }
    var body: some View {
        ZStack {
            TimerRing(start: s.startDate, end: s.endDate,
                      isPaused: s.isPaused, frozenRemaining: s.secondsRemaining,
                      total: s.totalRestSeconds, size: 22, lineWidth: 2.5)
            CountdownText(start: s.startDate, end: s.endDate,
                          isPaused: s.isPaused, frozenRemaining: s.secondsRemaining,
                          font: .system(size: 9, weight: .bold, design: .rounded))
                .fixedSize()
        }
    }
}

// MARK: - Widget

struct SetflowWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SetflowLiveActivityAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading)  { ExpandedLeading(context: context) }
                DynamicIslandExpandedRegion(.trailing) { ExpandedTrailing(context: context) }
                DynamicIslandExpandedRegion(.bottom)   { ExpandedBottom(context: context) }
            } compactLeading: {
                CompactLeadingView(context: context)
            } compactTrailing: {
                CompactTrailingView(context: context)
            } minimal: {
                MinimalView(context: context)
            }
            .keylineTint(RestPalette.active)
            .contentMargins(.horizontal, 0, for: .compactLeading)
            .contentMargins(.horizontal, 0, for: .compactTrailing)
            .contentMargins(.horizontal, 0, for: .minimal)
        }
    }
}
