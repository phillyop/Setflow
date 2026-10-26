# Setflow

A workout tracker built around the rest timer. Tap **Complete Set**, the rest starts instantly, and you log the set while you recover — no stopping to type between sets.

![Platform](https://img.shields.io/badge/platform-iOS%2026%20%7C%20watchOS-blue)
![UI](https://img.shields.io/badge/UI-SwiftUI-orange)
![Storage](https://img.shields.io/badge/storage-SwiftData-green)
![Xcode](https://img.shields.io/badge/Xcode-26-lightgrey)

<!--
Add screenshots to docs/screenshots/ and uncomment:

| Home | Session | Progress | History |
|------|---------|----------|---------|
| ![Home](docs/screenshots/home.png) | ![Session](docs/screenshots/session.png) | ![Progress](docs/screenshots/progress.png) | ![History](docs/screenshots/history.png) |
-->

## Features

### Training
- **Routines and exercise library** — build routines from a preset library or your own exercises, weighted or bodyweight.
- **Guided sessions** — set-by-set flow with a rest-timer ring. A logging panel slides up *during* the rest, pre-filled from your last session.
- **Per-set detail** — reps, weight, optional **RPE (1–10)**, warm-up sets (excluded from PRs and volume), and a custom rest time per set.
- **Plate calculator** — plates per side for a target weight, with selectable bar weight.
- **Programmes** — multi-week plans with a routine (or rest) assigned to each day, plus deload weeks.
- **Quick Win** — a four-minute guided stretch routine for days you're short on time. It keeps your streak alive and is recorded in History.
- **Repeat last workout** — one tap from Home to run your most recent routine again.

### Tracking
- **Streaks** — schedule- and programme-aware (see [How the streak works](#how-the-streak-works)).
- **History** — every session with per-set detail, editable after the fact. Sets that miss their rep target are tagged, and partial sessions can be resumed.
- **Progress** — consistency ring, total volume, a 28-day activity heatmap, routine breakdown, best week, and per-exercise personal bests, weekly volume, and recent sets.
- **Body metrics** — weight log with a trend chart.
- **CSV export** of your full history, and a shareable workout summary card.

### Around the app
- **Live Activity / Dynamic Island** for the rest timer.
- **Home Screen and Lock Screen widgets.**
- **Apple Watch companion** that mirrors your current set and rest countdown from the iPhone.
- **Siri and Shortcuts** — hands-free controls such as starting a routine, pausing, and skipping rest.
- **Reminders** — a daily nudge with selectable tone (Off / Gentle / Standard) and habit nudges. Reminders are deliberately low-pressure rather than guilt-based.
- **Apple Health** integration.
- **Light and dark mode**, Dynamic Type, and VoiceOver labels.

## How the streak works

The streak counts consecutive **required** days you trained, walking back from today:

- **Rest days are skipped**, not penalised. What counts as a rest day comes from your active programme when one covers that date, otherwise from your saved Training Schedule. With no schedule set, Sunday is treated as a rest day.
- **Deload weeks** are skipped the same way.
- **One missed required day per rolling 7 days is forgiven** (a streak freeze). A second miss in the same window ends the streak.
- **Today gets a grace pass** — not having trained yet never breaks anything.
- A **Quick Win** counts as training for the streak.
- When a streak resets, Home shows a dismissible banner naming the day that broke it.

The logic lives in [`StreakCalculator.swift`](Setflow/StreakCalculator.swift) as pure functions with no dependency on app state, so it can be unit tested in isolation.

## Requirements

- Xcode 26 or later
- iOS 26.2+ and a paired Apple Watch for the watchOS target
- A physical device is strongly recommended. Live Activities, HealthKit, notifications, and Watch connectivity are limited or unavailable in the simulator.

## Getting started

```bash
git clone https://github.com/<your-username>/Setflow.git
cd Setflow
open Setflow.xcodeproj
```

Before it will build and run on your own device:

1. **Set your signing team** under *Signing & Capabilities* for each target: `Setflow`, `SetflowWidgetExtension`, and `SetflowWatch Watch App`.
2. **Change the bundle identifiers** from `com.theoatuah.Setflow` (and its `.SetflowWidget` and `.watchkitapp` variants) to ones you own.
3. **Change the App Group.** The app, widget, and Siri intents share data on the iPhone through `group.com.theoatuah.Setflow`. Search the project for that string, replace it with your own group ID, and make sure the same group is enabled on the `Setflow` and `SetflowWidgetExtension` targets.
4. **iCloud sync is optional.** The app asks SwiftData for a CloudKit-backed store first and falls back to local-only storage if that isn't available. CloudKit needs a paid Apple Developer account; everything else works with a free personal team.

## Architecture

```
Setflow/
├── Setflow/                     iOS app
│   ├── SetflowApp.swift         Entry point; builds the SwiftData container
│   ├── WorkoutViewModel.swift   @Observable app state: sessions, rest timer, history
│   ├── StreakCalculator.swift   Pure streak logic
│   ├── SessionAnalytics.swift   Pure calculations over session history
│   ├── SetflowTheme.swift       Adaptive light/dark design tokens
│   ├── TrainingSchedule.swift   Weekly training days
│   ├── TrainingProgramme.swift  Multi-week programmes
│   ├── NotificationManager.swift, Habitnudge.swift, Notificationpreference.swift
│   ├── HealthKitManager.swift
│   ├── SiriCommands.swift, SetflowIntents.swift
│   └── *View.swift              SwiftUI screens
├── SetflowWidget/               Widgets and Live Activity UI
└── SetflowWatch Watch App/      watchOS companion
```

**State.** A single `@MainActor @Observable` view model owns session state and the rest timer. Logic that doesn't need that state, such as streaks and analytics, is split out into pure functions.

**Two history records.** `SessionHistory` is the rich record (per-exercise results) that powers the History tab and analytics. `WorkoutHistory` is a lightweight marker the streak calculator reads. A completed session writes both.

**Theming.** Colors come from tokens in `SetflowTheme.swift`, which resolve per color scheme. Use `Color.primary` for text and the `setflow*` / `card*` tokens for surfaces rather than literal `.white` or `.black`.

**Watch sync.** The iPhone sends session snapshots to the Watch over WatchConnectivity, only when something changes. During a rest it sends the rest's *end time*, and the Watch counts down locally. (An App Group can't be used for this: it only shares storage between apps on the same device.)

**Cross-target files.** A few files are compiled into more than one target, for example `Exercise.swift` and `SetflowLiveActivityAttributes.swift` into the widget, and `Watchshareddata.swift` into the iOS app. The project uses synchronized folders, so this is configured as membership exceptions on the target rather than per-file checkboxes.

## Status and known limitations

- iCloud sync has not yet been verified across two real devices.
- Watch session mirroring needs validating on paired hardware.
- The test targets exist, but automated test coverage is minimal. `StreakCalculator` is the natural place to start.
- The rest timer still lives inside `WorkoutViewModel` and could be extracted.
- Reminder improvements are planned (see below).
- A Privacy Manifest has not been added yet.

## Roadmap

- Reminder polish: manual time takes precedence, per-routine reminders, and an evening nudge that only fires if you haven't trained
- Large Home Screen widget
- Supersets and circuits
- Progressive-overload suggestions
- kg / lb unit toggle
- Personal-record celebration
- Unit tests for streak and analytics logic

## License

No license has been chosen yet. Add a `LICENSE` file and name it here.
