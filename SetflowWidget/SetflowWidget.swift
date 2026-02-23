import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct SetflowEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

// MARK: - Provider

struct SetflowProvider: TimelineProvider {

    func placeholder(in context: Context) -> SetflowEntry {
        SetflowEntry(date: Date(), snapshot: SharedDataReader.loadSnapshot())
    }

    func getSnapshot(in context: Context, completion: @escaping (SetflowEntry) -> Void) {
        completion(SetflowEntry(date: Date(), snapshot: SharedDataReader.loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SetflowEntry>) -> Void) {
        let snapshot = SharedDataReader.loadSnapshot()
        let entry = SetflowEntry(date: Date(), snapshot: snapshot)

        // Refresh at midnight so "done today" resets correctly
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )

        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let snapshot: WidgetSnapshot
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var isFullColor: Bool { renderingMode == .fullColor }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Streak row
            HStack(spacing: 6) {
                Text("🔥")
                    .font(.system(size: 18))
                    .widgetAccentable(!isFullColor)

                Text(snapshot.streak > 0 ? "\(snapshot.streak)" : "0")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(isFullColor ? .white : .primary)

                Text(snapshot.streak == 1 ? "day" : "days")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isFullColor ? .white.opacity(0.55) : .secondary)
                    .padding(.top, 3)
            }

            Spacer(minLength: 8)

            // Exercise pills — up to 3 on small
            VStack(alignment: .leading, spacing: 5) {
                ForEach(snapshot.exercises.prefix(3), id: \.name) { ex in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(ex.doneToday
                                  ? (isFullColor ? Color.blue : Color.primary)
                                  : (isFullColor ? Color.white.opacity(0.18) : Color.secondary.opacity(0.3)))
                            .frame(width: 7, height: 7)

                        Text(ex.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(
                                isFullColor
                                    ? (ex.doneToday ? .white : .white.opacity(0.55))
                                    : (ex.doneToday ? .primary : .secondary)
                            )
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 8)

            // Footer
            Text(footerText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isFullColor ? .blue.opacity(0.85) : .secondary)
                .widgetAccentable(!isFullColor)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            if isFullColor {
                Color.black
            } else {
                // Let the system render the tinted/clear background — an empty
                // container background tells WidgetKit not to force black.
                Color.clear
            }
        }
    }

    private var footerText: String {
        let total = snapshot.exercises.count
        let done = snapshot.exercises.filter(\.doneToday).count
        if done == 0 { return "Start today" }
        if done == total { return "All done today 🎉" }
        return "\(done)/\(total) done today"
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let snapshot: WidgetSnapshot
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var isFullColor: Bool { renderingMode == .fullColor }

    var body: some View {
        HStack(spacing: 0) {

            // Left column — streak + progress ring
            VStack(alignment: .leading, spacing: 6) {
                Text("Setflow")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isFullColor ? .white.opacity(0.4) : .secondary)
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isFullColor ? Color.white.opacity(0.1) : Color.secondary.opacity(0.2), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            isFullColor ? Color.blue : Color.primary,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.4), value: ringProgress)
                        .widgetAccentable(!isFullColor)

                    VStack(spacing: 1) {
                        Text("\(snapshot.streak)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(isFullColor ? .white : .primary)
                        Text("streak")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(isFullColor ? .white.opacity(0.5) : .secondary)
                    }
                }
                .frame(width: 74, height: 74)

                Spacer()

                Text(footerText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isFullColor ? .blue.opacity(0.9) : .secondary)
                    .lineLimit(1)
                    .widgetAccentable(!isFullColor)
            }
            .frame(width: 90)
            .padding(.leading, 14)
            .padding(.vertical, 14)

            // Divider
            Rectangle()
                .fill(isFullColor ? Color.white.opacity(0.07) : Color.secondary.opacity(0.15))
                .frame(width: 1)
                .padding(.vertical, 14)

            // Right column — exercise list
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(snapshot.exercises.prefix(4).enumerated()), id: \.element.name) { index, ex in
                    ExerciseRowView(exercise: ex)

                    if index < min(snapshot.exercises.count, 4) - 1 {
                        Divider()
                            .background(isFullColor ? Color.white.opacity(0.06) : Color.secondary.opacity(0.15))
                    }
                }

                if snapshot.exercises.isEmpty {
                    Spacer()
                    Text("Open Setflow to add exercises")
                        .font(.system(size: 11))
                        .foregroundColor(isFullColor ? .white.opacity(0.4) : .secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            if isFullColor {
                Color.black
            } else {
                Color.clear
            }
        }
    }

    private var ringProgress: Double {
        let total = snapshot.exercises.count
        guard total > 0 else { return 0 }
        let done = snapshot.exercises.filter(\.doneToday).count
        return Double(done) / Double(total)
    }

    private var footerText: String {
        let done = snapshot.exercises.filter(\.doneToday).count
        let total = snapshot.exercises.count
        if done == total && total > 0 { return "All done! 🎉" }
        return "\(done)/\(total) today"
    }
}

// MARK: - Exercise Row (medium widget)

struct ExerciseRowView: View {
    let exercise: WidgetSnapshot.ExerciseRow
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var isFullColor: Bool { renderingMode == .fullColor }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(
                        exercise.doneToday
                            ? (isFullColor ? Color.blue.opacity(0.25) : Color.primary.opacity(0.18))
                            : (isFullColor ? Color.white.opacity(0.07) : Color.secondary.opacity(0.12))
                    )
                    .frame(width: 28, height: 28)

                Image(systemName: exercise.doneToday ? "checkmark" : "figure.strengthtraining.traditional")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(
                        isFullColor
                            ? (exercise.doneToday ? .blue : .white.opacity(0.5))
                            : (exercise.doneToday ? .primary : .secondary)
                    )
            }
            .widgetAccentable(!isFullColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(
                        isFullColor
                            ? (exercise.doneToday ? .white : .white.opacity(0.7))
                            : (exercise.doneToday ? .primary : .primary.opacity(0.7))
                    )
                    .lineLimit(1)

                Text("\(exercise.sets) sets × \(exercise.reps) reps")
                    .font(.system(size: 10))
                    .foregroundColor(isFullColor ? .white.opacity(0.35) : .secondary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Widget Definition

struct SetflowWidget: Widget {
    let kind: String = "SetflowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SetflowProvider()) { entry in
            SetflowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Setflow")
        .description("Your streak and today's exercises.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

// MARK: - Entry View (router)

struct SetflowWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SetflowEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(snapshot: entry.snapshot)
        case .systemMedium:
            MediumWidgetView(snapshot: entry.snapshot)
        case .accessoryCircular:
            LockScreenCircularView(snapshot: entry.snapshot)
        case .accessoryRectangular:
            LockScreenRectangularView(snapshot: entry.snapshot)
        case .accessoryInline:
            LockScreenInlineView(snapshot: entry.snapshot)
        default:
            SmallWidgetView(snapshot: entry.snapshot)
        }
    }
}

// MARK: - Lock Screen — Circular (streak fire count)
// iOS forces tinted/monochrome rendering here — no custom colors are honoured,
// so we lean entirely on widgetAccentable() and let the system theme it.

struct LockScreenCircularView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 1) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .widgetAccentable()

                Text("\(snapshot.streak)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.7)
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Lock Screen — Rectangular (streak + today's progress)

struct LockScreenRectangularView: View {
    let snapshot: WidgetSnapshot

    private var total: Int { snapshot.exercises.count }
    private var done: Int { snapshot.exercises.filter(\.doneToday).count }

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .widgetAccentable()
                    Text("\(snapshot.streak) day\(snapshot.streak == 1 ? "" : "s")")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }

                Text(progressText)
                    .font(.system(size: 11, weight: .medium))
                    .opacity(0.75)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .containerBackground(.clear, for: .widget)
    }

    private var progressText: String {
        guard total > 0 else { return "Open Setflow to add exercises" }
        if done == 0 { return "Start today" }
        if done == total { return "All done today 🎉" }
        return "\(done)/\(total) done today"
    }
}

// MARK: - Lock Screen — Inline (single line next to the clock)

struct LockScreenInlineView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        let total = snapshot.exercises.count
        let done  = snapshot.exercises.filter(\.doneToday).count

        Label {
            if total > 0 && done < total {
                Text("\(snapshot.streak)d streak · \(done)/\(total) today")
            } else {
                Text("\(snapshot.streak) day streak")
            }
        } icon: {
            Image(systemName: "flame.fill")
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    SetflowWidget()
} timeline: {
    SetflowEntry(
        date: .now,
        snapshot: WidgetSnapshot(
            streak: 5,
            completedToday: 1,
            exercises: [
                .init(name: "Push-ups",       sets: 4, reps: 12, doneToday: true),
                .init(name: "Russian Twists",  sets: 4, reps: 10, doneToday: false),
                .init(name: "Plank",           sets: 3, reps: 60, doneToday: false)
            ],
            updatedAt: .now
        )
    )
}

#Preview("Medium", as: .systemMedium) {
    SetflowWidget()
} timeline: {
    SetflowEntry(
        date: .now,
        snapshot: WidgetSnapshot(
            streak: 5,
            completedToday: 2,
            exercises: [
                .init(name: "Push-ups",       sets: 4, reps: 12, doneToday: true),
                .init(name: "Russian Twists",  sets: 4, reps: 10, doneToday: true),
                .init(name: "Plank",           sets: 3, reps: 60, doneToday: false),
                .init(name: "Jumping Jacks",   sets: 2, reps: 20, doneToday: false)
            ],
            updatedAt: .now
        )
    )
}

#Preview("Lock Screen Circular", as: .accessoryCircular) {
    SetflowWidget()
} timeline: {
    SetflowEntry(
        date: .now,
        snapshot: WidgetSnapshot(
            streak: 12,
            completedToday: 1,
            exercises: [.init(name: "Push-ups", sets: 4, reps: 12, doneToday: true)],
            updatedAt: .now
        )
    )
}

#Preview("Lock Screen Rectangular", as: .accessoryRectangular) {
    SetflowWidget()
} timeline: {
    SetflowEntry(
        date: .now,
        snapshot: WidgetSnapshot(
            streak: 12,
            completedToday: 1,
            exercises: [
                .init(name: "Push-ups",      sets: 4, reps: 12, doneToday: true),
                .init(name: "Russian Twists", sets: 4, reps: 10, doneToday: false)
            ],
            updatedAt: .now
        )
    )
}

#Preview("Lock Screen Inline", as: .accessoryInline) {
    SetflowWidget()
} timeline: {
    SetflowEntry(
        date: .now,
        snapshot: WidgetSnapshot(
            streak: 12,
            completedToday: 1,
            exercises: [
                .init(name: "Push-ups",      sets: 4, reps: 12, doneToday: true),
                .init(name: "Russian Twists", sets: 4, reps: 10, doneToday: false)
            ],
            updatedAt: .now
        )
    )
}
