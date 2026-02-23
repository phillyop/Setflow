import Foundation
import SwiftUI
import SwiftData
import Observation
import UserNotifications
import ActivityKit

@MainActor
@Observable
final class WorkoutViewModel {

    // MARK: - SwiftData
    private var storedContext: ModelContext
    private var context: ModelContext { storedContext }

    // MARK: - Library
    var exercises: [Exercise] = []
    var routines: [WorkoutRoutine] = []

    // MARK: - Programmes
    var programmes: [TrainingProgramme] = []
    var activeProgramme: TrainingProgramme? { programmes.first(where: { $0.isActive }) }

    // MARK: - Body Metrics
    var bodyMetrics: [BodyMetric] = []

    // MARK: - History
    var history: [WorkoutHistory] = []
    var sessionHistory: [SessionHistory] = []

    // MARK: - Streak
    var currentStreak: Int = 0
    /// Set when calculateStreak() detects the streak just dropped due to a
    /// real break (not a freeze, not just sitting at zero) — surfaced once
    /// on Home, then cleared and remembered via dismissStreakBreakMessage()
    /// so it doesn't reappear for the same break after a relaunch.
    var streakBreakMessage: String?
    private var pendingStreakBreakDate: Date?
    var trainingSchedule: TrainingSchedule = TrainingSchedule.load()
    var notificationPref: NotificationPreference = NotificationPreference.load()

    // MARK: - Active Session State
    var activeRoutine: WorkoutRoutine?
    var sessionExercises: [RoutineExercise] = []   // ordered list for this session
    var currentExerciseIndex: Int = 0
    var currentSet: Int = 1
    var isSessionActive: Bool = false
    var sessionStartedAt: Date = Date()
    var sessionResults: [SessionExerciseResult] = []

    // Rest timer
    var isResting: Bool = false
    var isPaused: Bool = false
    var restCountdown: Int = 0

    // Completion states
    var isFinishingExercise: Bool = false   // brief animation between exercises
    var sessionSummary: SessionSummary?     // shown on SessionCompleteView

    // Set logging — pendingSetLog non-nil means the log overlay is showing
    var pendingSetLog: SetLog? = nil
    var currentSetLogs: [SetLog] = []       // accumulates set logs for current exercise
    var isFinishingLastSet: Bool = false     // last set tapped — waiting for log before advancing

    // Legacy single-exercise mode (kept for backwards compat with direct exercise tap)
    var selectedExercise: Exercise?
    var isWorkoutActive: Bool = false
    var workoutSummary: WorkoutSummary?
    var isFinishingWorkout: Bool = false

    private var timerTask: Task<Void, Never>?
    private var liveActivity: Activity<SetflowLiveActivityAttributes>?

    // MARK: - Computed helpers
    var currentRoutineExercise: RoutineExercise? {
        guard currentExerciseIndex < sessionExercises.count else { return nil }
        return sessionExercises[currentExerciseIndex]
    }
    var nextRoutineExercise: RoutineExercise? {
        let next = currentExerciseIndex + 1
        guard next < sessionExercises.count else { return nil }
        return sessionExercises[next]
    }
    var sessionProgress: Double {
        guard !sessionExercises.isEmpty else { return 0 }
        return Double(currentExerciseIndex) / Double(sessionExercises.count)
    }
    var isLastExercise: Bool {
        currentExerciseIndex >= sessionExercises.count - 1
    }

    // MARK: - Init

    init(context: ModelContext) {
        self.storedContext = context
        fetchAll()
    }

    func reinitialise(with realContext: ModelContext) {
        // No-op — kept for call-site compatibility during transition.
        // Context is now injected correctly at init time via onAppear.
    }

    private func fetchAll() {
        fetchExercises()
        fetchRoutines()
        fetchHistory()
        fetchSessionHistory()
        fetchProgrammes()
        fetchBodyMetrics()
        calculateStreak()
        rescheduleAllReminders()
        writeWidgetSnapshot()
    }

    // MARK: - Fetch

    func fetchExercises() {
        let d = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)])
        exercises = (try? context.fetch(d)) ?? []
    }

    func fetchRoutines() {
        let d = FetchDescriptor<WorkoutRoutine>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)])
        routines = (try? context.fetch(d)) ?? []
    }

    func fetchHistory() {
        let d = FetchDescriptor<WorkoutHistory>(sortBy: [SortDescriptor(\.completedAt, order: .reverse)])
        history = (try? context.fetch(d)) ?? []
    }

    func fetchSessionHistory() {
        let d = FetchDescriptor<SessionHistory>(sortBy: [SortDescriptor(\.completedAt, order: .reverse)])
        sessionHistory = (try? context.fetch(d)) ?? []
    }

    func fetchProgrammes() {
        let d = FetchDescriptor<TrainingProgramme>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)])
        programmes = (try? context.fetch(d)) ?? []
    }

    func fetchBodyMetrics() {
        let d = FetchDescriptor<BodyMetric>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        bodyMetrics = (try? context.fetch(d)) ?? []
    }

    // MARK: - Programme CRUD

    func addProgramme(_ programme: TrainingProgramme) {
        programme.sortOrder = programmes.count
        context.insert(programme)
        saveContext()
        fetchProgrammes()
    }

    func updateProgramme(_ programme: TrainingProgramme) {
        saveContext()
        fetchProgrammes()
    }

    func deleteProgramme(_ programme: TrainingProgramme) {
        if programme.isActive { programme.isActive = false }
        context.delete(programme)
        saveContext()
        fetchProgrammes()
    }

    func activateProgramme(_ programme: TrainingProgramme) {
        // Deactivate all others first
        for p in programmes where p.isActive { p.isActive = false }
        programme.isActive  = true
        programme.startedAt = Date()
        saveContext()
        fetchProgrammes()
        Haptics.success()
    }

    func deactivateProgramme() {
        for p in programmes where p.isActive { p.isActive = false }
        saveContext()
        fetchProgrammes()
    }

    // MARK: - Body Metrics CRUD

    func addBodyMetric(_ metric: BodyMetric) {
        context.insert(metric)
        saveContext()
        fetchBodyMetrics()
    }

    func deleteBodyMetric(_ metric: BodyMetric) {
        context.delete(metric)
        saveContext()
        fetchBodyMetrics()
    }

    // Latest body weight
    var latestWeight: Double? { bodyMetrics.first?.weightKg }

    // Weight trend: positive = gaining, negative = losing
    var weightTrend: Double? {
        guard bodyMetrics.count >= 2 else { return nil }
        return bodyMetrics[0].weightKg - bodyMetrics[1].weightKg
    }

    // MARK: - Exercise CRUD

    func addExercise(_ exercise: Exercise) {
        exercise.sortOrder = exercises.count
        context.insert(exercise)
        saveContext()
        fetchExercises()
        NotificationManager.shared.scheduleReminders(for: exercise)
        writeWidgetSnapshot()
    }

    func updateExercise(_ exercise: Exercise) {
        saveContext()
        fetchExercises()
        NotificationManager.shared.scheduleReminders(for: exercise)
        writeWidgetSnapshot()
    }

    func deleteExercise(_ exercise: Exercise) {
        NotificationManager.shared.removeReminders(for: exercise)
        context.delete(exercise)
        saveContext()
        fetchExercises()
        writeWidgetSnapshot()
    }

    /// Soft delete — returns the exercise so the caller can undo within a window.
    /// Call commitDeleteExercise() after the undo window expires.
    func softDeleteExercise(_ exercise: Exercise, completion: @escaping () -> Void) {
        // Detach from notification system immediately
        NotificationManager.shared.removeReminders(for: exercise)
        // Remove from local array for instant UI feedback
        exercises.removeAll { $0.id == exercise.id }
        completion()
    }

    func commitDeleteExercise(_ exercise: Exercise) {
        context.delete(exercise)
        saveContext()
        fetchExercises()
        writeWidgetSnapshot()
    }

    func restoreExercise(_ exercise: Exercise) {
        // Re-insert into context if it was removed from local array only
        fetchExercises()
        NotificationManager.shared.scheduleReminders(for: exercise)
    }

    func moveExercises(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
        for (i, ex) in exercises.enumerated() { ex.sortOrder = i }
        saveContext()
    }

    // MARK: - Routine CRUD

    func addRoutine(_ routine: WorkoutRoutine) {
        routine.sortOrder = routines.count
        context.insert(routine)
        saveContext()
        fetchRoutines()
    }

    func updateRoutine(_ routine: WorkoutRoutine) {
        saveContext()
        fetchRoutines()
    }

    func deleteRoutine(_ routine: WorkoutRoutine) {
        context.delete(routine)
        saveContext()
        fetchRoutines()
    }

    func softDeleteRoutine(_ routine: WorkoutRoutine, completion: @escaping () -> Void) {
        routines.removeAll { $0.id == routine.id }
        completion()
    }

    func commitDeleteRoutine(_ routine: WorkoutRoutine) {
        context.delete(routine)
        saveContext()
        fetchRoutines()
    }

    func restoreRoutine(_ routine: WorkoutRoutine) {
        fetchRoutines()
    }

    func moveRoutines(from source: IndexSet, to destination: Int) {
        routines.move(fromOffsets: source, toOffset: destination)
        for (i, r) in routines.enumerated() { r.sortOrder = i }
        saveContext()
    }

    // MARK: - Notifications

    func rescheduleAllReminders() {
        for exercise in exercises { NotificationManager.shared.scheduleReminders(for: exercise) }
        rescheduleHabitNudge()
    }

    /// The hour the user most often completes workouts — used for smart nudge
    /// timing. Before any real history exists, falls back to the hour the user
    /// chose during onboarding, then to 17:00 as a last resort.
    private var usualTrainingHour: Int {
        let cal = Calendar.current
        let hours = history
            .filter { !$0.isQuickWin }
            .map { cal.component(.hour, from: $0.completedAt) }
        guard !hours.isEmpty else { return notificationPref.seedHour ?? 17 }
        // Mode (most frequent hour), not mean — a mean gets dragged by outliers.
        let counts = Dictionary(grouping: hours, by: { $0 }).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key ?? 17
    }

    private var daysSinceLastActivity: Int {
        let cal = Calendar.current
        guard let last = history.map(\.completedAt).max() else { return 999 }
        return cal.dateComponents([.day], from: cal.startOfDay(for: last),
                                  to: cal.startOfDay(for: Date())).day ?? 0
    }

    /// Recomputes and reschedules the daily habit nudge from current behaviour.
    /// Safe to call often — it clears and rebuilds the two nudge requests.
    func rescheduleHabitNudge() {
        NotificationManager.shared.scheduleHabitNudge(
            tone: notificationPref.tone,
            usualHour: usualTrainingHour,
            streak: currentStreak,
            trainedToday: streakSafeToday,
            daysSinceLastActivity: daysSinceLastActivity
        )
    }

    func updateNotificationTone(_ tone: NotificationTone) {
        notificationPref.tone = tone
        notificationPref.save()
        rescheduleHabitNudge()
    }

    /// Called from onboarding when the user picks when they'll train. Seeds the
    /// nudge timing so a reminder is anchored from day one — before there's any
    /// workout history to learn from — then the smart timing takes over later.
    func setOnboardingTrainingHour(_ hour: Int, tone: NotificationTone = .standard) {
        notificationPref.seedHour = hour
        notificationPref.tone     = tone
        notificationPref.save()
        rescheduleHabitNudge()
    }

    /// Acts on a notification the user tapped — called when the app becomes
    /// active. Routes straight into the relevant action so there's zero friction
    /// between the nudge and doing the thing.
    func handlePendingNotificationAction() {
        guard let pending = NotificationRouter.shared.consumePendingAction() else { return }

        switch pending.action {
        case .startQuickWin:
            guard !isSessionActive, !isWorkoutActive, !isQuickWinActive else { return }
            startQuickWin()

        case .openExercise:
            if let idString = pending.exerciseID,
               let id = UUID(uuidString: idString),
               let ex = exercises.first(where: { $0.id == id }) {
                startWorkout(for: ex)
            } else {
                startTodaysWorkout()
            }

        case .startToday:
            startTodaysWorkout()
        }
    }

    /// Best-guess "today's workout": the active programme's routine for today,
    /// else a routine matching today's schedule, else the first routine. Never
    /// auto-starts if the user is already mid-session.
    private func startTodaysWorkout() {
        guard !isSessionActive, !isWorkoutActive, !isQuickWinActive else { return }

        if let programme = activeProgramme,
           let today = programme.todayProgrammeDay(), !today.isRestDay,
           let routine = routines.first(where: { $0.id == today.routineID }) {
            startSession(routine: routine)
            return
        }
        // Otherwise just surface the app on Home — don't force a routine choice.
        // (Deep-linking to a specific routine only when we're confident avoids
        // dumping the user into the wrong workout.)
    }

    func updateNotification(for exercise: Exercise) {
        NotificationManager.shared.scheduleReminders(for: exercise)
    }

    // MARK: - Session Control

    func startSession(routine: WorkoutRoutine) {
        guard !routine.exercises.isEmpty else { return }

        activeRoutine        = routine
        sessionExercises     = routine.exercises.sorted { $0.sortOrder < $1.sortOrder }
        currentExerciseIndex = 0
        currentSet           = 1
        isSessionActive      = true
        sessionStartedAt     = Date()
        sessionResults       = []

        isResting            = false
        isPaused             = false
        restCountdown        = 0
        isFinishingExercise  = false
        currentSetLogs       = []
        pendingSetLog        = nil
        isFinishingLastSet   = false

        timerTask?.cancel()
        timerTask = nil
    }

    /// Sessions started today that ended early and have at least one exercise
    /// left fully or partially unfinished — surfaced on Home so the user can
    /// pick back up before the day ends.
    var resumableSessionsToday: [SessionHistory] {
        let cal = Calendar.current
        return sessionHistory.filter {
            !$0.wasCompleted && cal.isDateInToday($0.completedAt)
        }
    }

    /// Resumes a partial session — finds the matching routine, replays which
    /// exercises are already done, and drops the user into the first
    /// incomplete exercise at the correct set number.
    func resumeSession(from session: SessionHistory) {
        guard let routine = routines.first(where: { $0.name == session.routineName }) else { return }

        let sorted = routine.exercises.sorted { $0.sortOrder < $1.sortOrder }
        activeRoutine        = routine
        sessionExercises     = sorted
        sessionStartedAt     = session.startedAt   // keep original start time for accurate duration
        sessionResults       = session.results     // carry forward what's already completed
        isSessionActive      = true

        // Find the first exercise that isn't fully completed yet
        let doneIDs = Set(session.results.filter { $0.completedSets >= $0.sets }.map(\.exerciseID))
        if let resumeIndex = sorted.firstIndex(where: { !doneIDs.contains($0.exerciseID) }) {
            currentExerciseIndex = resumeIndex
            // If this exercise has a partial result already, continue from the next set
            if let partial = session.results.first(where: { $0.exerciseID == sorted[resumeIndex].exerciseID }) {
                currentSet     = partial.completedSets + 1
                currentSetLogs = partial.setLogs
                // Remove the partial result from sessionResults — it'll be re-recorded when finished
                sessionResults.removeAll { $0.exerciseID == partial.exerciseID }
            } else {
                currentSet     = 1
                currentSetLogs = []
            }
        } else {
            // Everything was actually finished — just go to the last exercise
            currentExerciseIndex = sorted.count - 1
            currentSet           = 1
            currentSetLogs       = []
        }

        isResting            = false
        isPaused             = false
        restCountdown        = 0
        isFinishingExercise  = false
        pendingSetLog        = nil
        isFinishingLastSet   = false

        // Remove the old partial record — it'll be replaced by a fresh one when this session ends
        context.delete(session)
        saveContext()
        fetchSessionHistory()
    }

    /// The routine behind the most recent fully completed session, if that
    /// routine still exists — powers the Home screen's "Repeat last workout"
    /// card. Matches by name, same lookup resumeSession already relies on, so
    /// if the routine's since been renamed or deleted this is simply nil
    /// rather than a new failure mode.
    var lastCompletedRoutine: WorkoutRoutine? {
        guard let last = sessionHistory.first(where: { $0.wasCompleted }) else { return nil }
        return routines.first(where: { $0.name == last.routineName })
    }

    /// Starts a fresh session using the same routine as the most recent
    /// completed workout.
    func repeatLastWorkout() {
        guard !isSessionActive, !isWorkoutActive, !isQuickWinActive else { return }
        guard let routine = lastCompletedRoutine else { return }
        startSession(routine: routine)
    }

    // User taps "Complete Set" — rest starts immediately, log sheet appears during rest
    func completeSessionSet() {
        guard let ex = currentRoutineExercise else { return }

        // Build the pre-filled log
        let last = lastSetLog(for: ex.exerciseID, setNumber: currentSet)
        pendingSetLog = SetLog(
            setNumber: currentSet,
            reps: last?.reps ?? ex.reps,
            weight: last?.weight ?? (ex.tracking == .weighted ? ex.defaultWeight : nil),
            customRest: ex.restSeconds,
            isWarmup: currentSet <= ex.warmupSets
        )

        if currentSet >= ex.sets {
            // Last set — no rest, go straight to exercise completion
            // Sheet appears briefly for logging then auto-advances
            isFinishingLastSet = true
        } else {
            // Mid-session set — start rest immediately, sheet overlays the timer
            let rest = pendingSetLog?.customRest ?? ex.restSeconds
            startRest(seconds: max(1, rest), forSession: true)
        }
    }

    // Called when user confirms the set log sheet
    func confirmSetLog(_ log: SetLog) {
        guard let ex = currentRoutineExercise else { return }
        currentSetLogs.append(log)
        pendingSetLog    = nil
        isFinishingLastSet = false

        Haptics.setConfirmed()

        if currentSet > ex.sets || (currentSet == ex.sets && !isResting) {
            // Last set confirmed — wrap up exercise
            finishCurrentExercise(ex: ex)
        }
        // If resting, the timer runs out normally and advances the set
    }

    // Auto-confirm with prefilled values when rest ends (user didn't interact with sheet)
    private func autoConfirmPendingLog() {
        guard let log = pendingSetLog, let ex = currentRoutineExercise else { return }
        currentSetLogs.append(log)
        pendingSetLog = nil
        // Set has already been incremented by the rest timer — nothing else to do
        _ = ex // suppress warning
    }

    private func finishCurrentExercise(ex: RoutineExercise) {
        recordExerciseResult(ex, logs: currentSetLogs)
        currentSetLogs = []

        if isLastExercise {
            finishSession(wasCompleted: true)
        } else {
            isFinishingExercise = true
            Haptics.exerciseComplete()
            SoundManager.playCompletion()
            Task {
                try? await Task.sleep(nanoseconds: 900_000_000)
                advanceToNextExercise()
                isFinishingExercise = false
            }
        }
    }

    func dismissSetLog() {
        pendingSetLog      = nil
        isFinishingLastSet = false
    }

    // Look up the most recent set log for a given exercise + set number
    func lastSetLog(for exerciseID: UUID, setNumber: Int) -> SetLog? {
        for session in sessionHistory {
            if let result = session.results.first(where: { $0.exerciseID == exerciseID }),
               let log = result.setLogs.first(where: { $0.setNumber == setNumber }) {
                return log
            }
        }
        return nil
    }

    // Last full result for an exercise (used to show "last time" on the sheet)
    func lastResult(for exerciseID: UUID) -> SessionExerciseResult? {
        for session in sessionHistory {
            if let result = session.results.first(where: { $0.exerciseID == exerciseID }) {
                return result
            }
        }
        return nil
    }

    private func advanceToNextExercise() {
        currentExerciseIndex += 1
        currentSet            = 1
        currentSetLogs        = []
        isResting             = false
        restCountdown         = 0
    }

    private func recordExerciseResult(_ ex: RoutineExercise, logs: [SetLog]) {
        let result = SessionExerciseResult(
            exerciseID:    ex.exerciseID,
            exerciseName:  ex.name,
            sets:          ex.sets,
            reps:          ex.reps,
            completedSets: logs.count,
            setLogs:       logs
        )
        sessionResults.append(result)

        // Legacy WorkoutHistory entry so streak + stats remain intact
        let entry = WorkoutHistory(exerciseName: ex.name, sets: logs.count, reps: ex.reps)
        context.insert(entry)
    }

    func endSessionEarly() {
        // If rest is currently running, the user has already completed that set —
        // capture it with its pre-filled values before discarding.
        if let pending = pendingSetLog {
            currentSetLogs.append(pending)
        }
        pendingSetLog      = nil
        isFinishingLastSet = false

        // Record whatever progress exists for the exercise currently in progress.
        // currentSetLogs already reflects every confirmed/auto-confirmed set —
        // no need to fabricate data for sets that were never actually logged.
        if let ex = currentRoutineExercise, !currentSetLogs.isEmpty {
            recordExerciseResult(ex, logs: currentSetLogs)
        }
        currentSetLogs = []
        finishSession(wasCompleted: false)
    }

    /// Exits the active session without creating any history entry. Only safe
    /// to call when truly nothing has been done — callers (e.g. the X/cancel
    /// button) should check that no set or exercise has been logged first.
    /// This intentionally bypasses finishSession entirely so there's no risk
    /// of a zero-progress session ever reaching SwiftData.
    func discardEmptySession() {
        timerTask?.cancel()
        timerTask = nil
        endLiveActivity()
        resetSessionState()
    }

    private func finishSession(wasCompleted: Bool) {
        timerTask?.cancel()
        timerTask = nil
        endLiveActivity()

        // Ending early with literally no exercise completed shouldn't create a
        // history entry — only save partial progress if at least one exercise
        // has at least one recorded set.
        if sessionResults.isEmpty {
            resetSessionState()
            return
        }

        let session = SessionHistory(
            routineName:  activeRoutine?.name ?? "Workout",
            startedAt:    sessionStartedAt,
            completedAt:  Date(),
            wasCompleted: wasCompleted,
            results:      sessionResults
        )
        context.insert(session)
        saveContext()
        fetchHistory()
        fetchSessionHistory()
        calculateStreak()

        sessionSummary = SessionSummary(
            routineName:   session.routineName,
            results:       session.results,
            durationSeconds: session.durationSeconds,
            wasCompleted:  wasCompleted,
            streak:        currentStreak
        )

        writeWidgetSnapshot()
        if wasCompleted {
            Haptics.sessionComplete()
            SoundManager.playCompletion()
            let trainedNames = sessionResults.map(\.exerciseName)
            NotificationManager.shared.suppressTodayReminders(for: trainedNames, in: exercises)
            // Write to Apple Health — non-blocking, failure is silent
            HealthKitManager.shared.writeWorkout(from: session)
        } else {
            Haptics.sessionEndedEarly()
        }

        resetSessionState()
    }

    /// Resets all active-session state without touching history. Used both after
    /// a session is saved and when a session is abandoned with zero progress.
    private func resetSessionState() {
        isSessionActive      = false
        activeRoutine        = nil
        sessionExercises     = []
        currentExerciseIndex = 0
        currentSet           = 1
        isResting            = false
        isPaused             = false
        restCountdown        = 0
        isFinishingExercise  = false
        currentSetLogs       = []
        pendingSetLog        = nil
        isFinishingLastSet   = false
        sessionResults       = []
        WatchDataWriter.clear()
    }

    func clearSessionSummary() {
        sessionSummary = nil
    }

    // MARK: - Rest Timer (shared between session and legacy modes)

    private func startRest(seconds: Int, forSession: Bool) {
        isResting     = true
        isPaused      = false
        restCountdown = seconds

        if forSession, let ex = currentRoutineExercise {
            startLiveActivity(name: ex.name, set: currentSet, totalSets: ex.sets, seconds: seconds)
        } else if let ex = selectedExercise {
            startLiveActivity(name: ex.name, set: currentSet, totalSets: ex.sets, seconds: seconds)
        }

        timerTask?.cancel()
        timerTask = Task { [weak self] in
            // The class is @MainActor, so this closure is already main-actor isolated;
            // property access below is synchronous and safe.
            while let self, self.restCountdown > 0, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }

                if self.isPaused {
                    // Paused: don't decrement. Keep Live Activity / Watch in sync so
                    // the paused state shows, and still poll Siri so "resume" works.
                    self.updateLiveActivityCountdown(seconds: self.restCountdown)
                    self.writeWatchState()
                    self.processSiriCommandIfNeeded()
                    continue
                }

                self.restCountdown -= 1
                if self.restCountdown > 0 && self.restCountdown <= 5 {
                    Haptics.countdownTick()
                }
                self.updateLiveActivityCountdown(seconds: self.restCountdown)
                self.writeWatchState()
                self.processSiriCommandIfNeeded()
            }

            if let self, !Task.isCancelled, self.restCountdown == 0 {
                self.isResting  = false
                self.currentSet += 1
                self.autoConfirmPendingLog()   // auto-confirm any unconfirmed set log
                Haptics.restEnded()
                SoundManager.playCompletion()
                self.endLiveActivity()
                self.writeWatchState()
            }
        }
    }

    func togglePause() {
        isPaused.toggle()
    }

    // MARK: - Legacy single-exercise mode

    func startWorkout(for exercise: Exercise) {
        selectedExercise = exercise
        currentSet       = 1
        isWorkoutActive  = true
        isResting        = false
        isPaused         = false
        restCountdown    = 0
        timerTask?.cancel()
        timerTask = nil
    }

    func completeSet() {
        guard let exercise = selectedExercise else { return }

        if currentSet >= exercise.sets {
            isFinishingWorkout = true
            Haptics.exerciseComplete()
            SoundManager.playCompletion()

            Task {
                try? await Task.sleep(nanoseconds: 900_000_000)
                recordLegacyWorkout(for: exercise)
                finishWorkout()
                isFinishingWorkout = false
            }
            return
        }
        startRest(seconds: max(1, exercise.restSeconds), forSession: false)
    }

    func finishWorkout() {
        timerTask?.cancel()
        timerTask = nil
        endLiveActivity()

        isWorkoutActive    = false
        selectedExercise   = nil
        isFinishingWorkout = false
        isResting          = false
        isPaused           = false
        restCountdown      = 0
        currentSet         = 1
        Haptics.light()
    }

    private func recordLegacyWorkout(for exercise: Exercise) {
        let now = Date()

        // Build synthetic set logs (no weight data — legacy mode doesn't collect it)
        let setLogs = (1...max(1, exercise.sets)).map { setNum in
            SetLog(setNumber: setNum, reps: exercise.reps, weight: nil)
        }

        let result = SessionExerciseResult(
            exerciseID:    exercise.id,
            exerciseName:  exercise.name,
            sets:          exercise.sets,
            reps:          exercise.reps,
            completedSets: exercise.sets,
            setLogs:       setLogs
        )

        // SessionHistory so it appears in HistoryView alongside routine sessions
        let session = SessionHistory(
            routineName:  exercise.name,
            startedAt:    now,
            completedAt:  now,
            wasCompleted: true,
            results:      [result]
        )
        context.insert(session)

        // Legacy WorkoutHistory entry — keeps streak + stats working
        let entry = WorkoutHistory(exerciseName: exercise.name, sets: exercise.sets, reps: exercise.reps)
        context.insert(entry)

        saveContext()
        fetchHistory()
        fetchSessionHistory()
        calculateStreak()

        workoutSummary = WorkoutSummary(
            exerciseName: exercise.name,
            sets: exercise.sets,
            reps: exercise.reps,
            completedAt: now
        )
        writeWidgetSnapshot()
    }

    func clearWorkoutSummary() { workoutSummary = nil }

    // MARK: - Session Log Editing

    /// Update a specific set log within a session result
    func updateSetLog(_ updatedLog: SetLog, inResult resultID: UUID, ofSession session: SessionHistory) {
        var results = session.results
        guard let rIdx = results.firstIndex(where: { $0.id == resultID }) else { return }
        var logs = results[rIdx].setLogs
        guard let lIdx = logs.firstIndex(where: { $0.id == updatedLog.id }) else { return }
        logs[lIdx] = updatedLog
        results[rIdx].setLogs = logs
        session.results = results
        saveContext()
        fetchSessionHistory()
        Haptics.saved()
    }

    /// Delete a specific set log within a session result
    func deleteSetLog(_ log: SetLog, inResult resultID: UUID, ofSession session: SessionHistory) {
        var results = session.results
        guard let rIdx = results.firstIndex(where: { $0.id == resultID }) else { return }
        results[rIdx].setLogs.removeAll { $0.id == log.id }
        results[rIdx].completedSets = results[rIdx].setLogs.count
        session.results = results
        saveContext()
        fetchSessionHistory()
        Haptics.light()
    }

    /// Delete an entire session from history
    func deleteSession(_ session: SessionHistory) {
        context.delete(session)
        saveContext()
        fetchSessionHistory()
        calculateStreak()
        writeWidgetSnapshot()
    }

    /// Exercises with a reminder configured for today's weekday — used to show
    /// "what's planned today" on Home without depending on an active Programme.
    var todaysScheduledExercises: [(exercise: Exercise, time: String, doneToday: Bool)] {
        let cal     = Calendar.current
        let weekday = cal.component(.weekday, from: Date())

        return exercises.compactMap { ex -> (Exercise, String, Bool)? in
            guard let reminder = ex.reminders.first(where: {
                $0.isEnabled && $0.weekdays.contains(weekday)
            }) else { return nil }

            var comps = DateComponents()
            comps.hour = reminder.hour
            comps.minute = reminder.minute
            let timeString = Calendar.current.date(from: comps)
                .map { $0.formatted(date: .omitted, time: .shortened) } ?? ""

            let doneToday = history.contains {
                $0.exerciseName == ex.name && cal.isDateInToday($0.completedAt)
            }
            return (ex, timeString, doneToday)
        }
        .sorted { $0.1 < $1.1 } // sort by time of day
    }

    func calculateStreak() {
        let result = StreakCalculator.compute(
            history: history, schedule: trainingSchedule, programme: activeProgramme
        )

        let previous = UserDefaults.shared.integer(forKey: Self.lastKnownStreakKey)
        let lastAcknowledged = UserDefaults.shared.object(forKey: Self.lastAcknowledgedBreakKey) as? Date

        if let brokenOn = result.brokenOn,
           result.count < previous,
           previous > 0,
           lastAcknowledged == nil || !Calendar.current.isDate(lastAcknowledged!, inSameDayAs: brokenOn) {
            let f = DateFormatter()
            f.dateFormat = "EEEE, MMM d"
            streakBreakMessage = "Your \(previous)-day streak reset — you missed \(f.string(from: brokenOn))."
            pendingStreakBreakDate = brokenOn
        }

        currentStreak = result.count
        UserDefaults.shared.set(result.count, forKey: Self.lastKnownStreakKey)
    }

    /// Call when the user dismisses the streak-break banner — remembers the
    /// break so it doesn't resurface after a relaunch, without suppressing
    /// a genuinely new break later.
    func dismissStreakBreakMessage() {
        if let date = pendingStreakBreakDate {
            UserDefaults.shared.set(date, forKey: Self.lastAcknowledgedBreakKey)
        }
        streakBreakMessage = nil
        pendingStreakBreakDate = nil
    }

    private static let lastKnownStreakKey = "lastKnownStreakCount"
    private static let lastAcknowledgedBreakKey = "lastAcknowledgedStreakBreakDate"

    func updateSchedule(_ schedule: TrainingSchedule) {
        trainingSchedule = schedule
        schedule.save()
        calculateStreak()
        writeWidgetSnapshot()
    }

    var totalWorkouts: Int { sessionHistory.count }

    var workoutsThisWeek: Int {
        let cal = Calendar.current, now = Date()
        return sessionHistory.filter {
            cal.isDate($0.completedAt, equalTo: now, toGranularity: .weekOfYear)
        }.count
    }

    var favoriteRoutine: String {
        let grouped = Dictionary(grouping: sessionHistory, by: { $0.routineName })
        return grouped.max { $0.value.count < $1.value.count }?.key ?? "N/A"
    }

    var longestStreak: Int {
        StreakCalculator.longestStreak(history: history)
    }

    func hasWorkout(on date: Date) -> Bool {
        StreakCalculator.hasWorkout(on: date, history: history)
    }

    // MARK: - Quick Win (streak floor)

    /// A short mobility / movement mini-session that keeps the streak alive on a
    /// day the user can't manage a full workout. It counts as a "worked day" for
    /// the streak but is deliberately excluded from volume, PR and session stats,
    /// so it never inflates real training numbers — it's the honest light option.

    struct QuickWinMove: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let detail: String
        let seconds: Int
        let symbol: String
    }

    /// The default Quick Win flow — ~4 minutes of gentle, universally-doable
    /// movement. No equipment, no floor space required.
    let quickWinMoves: [QuickWinMove] = [
        .init(name: "Neck & Shoulder Rolls", detail: "Slow circles, both directions", seconds: 40, symbol: "figure.cooldown"),
        .init(name: "Standing Forward Fold",  detail: "Let your spine decompress",     seconds: 45, symbol: "figure.flexibility"),
        .init(name: "World's Greatest Stretch", detail: "Alternate sides",             seconds: 60, symbol: "figure.strengthtraining.functional"),
        .init(name: "Cat–Cow Flow",            detail: "Move with your breath",         seconds: 45, symbol: "figure.mind.and.body"),
        .init(name: "Deep Breathing",          detail: "Four slow breaths to finish",   seconds: 30, symbol: "wind")
    ]

    var isQuickWinActive: Bool = false
    var quickWinIndex: Int = 0

    var hasTrainedToday: Bool {
        StreakCalculator.hasTrainedToday(history: history)
    }

    var hasQuickWinToday: Bool {
        StreakCalculator.hasQuickWinToday(history: history)
    }

    /// Whether the streak is currently held by today's activity of any kind.
    var streakSafeToday: Bool { hasTrainedToday || hasQuickWinToday }

    func startQuickWin() {
        quickWinIndex   = 0
        isQuickWinActive = true
    }

    func advanceQuickWin() {
        if quickWinIndex < quickWinMoves.count - 1 {
            quickWinIndex += 1
        } else {
            completeQuickWin()
        }
    }

    func cancelQuickWin() {
        isQuickWinActive = false
        quickWinIndex    = 0
    }

    private func completeQuickWin() {
        isQuickWinActive = false
        quickWinIndex    = 0

        // Only record one Quick Win per day — no stacking.
        guard !hasQuickWinToday else {
            Haptics.saved()
            return
        }

        let marker = WorkoutHistory(
            exerciseName: "Quick Win",
            completedAt: Date(),
            sets: 0, reps: 0,
            isQuickWin: true
        )
        context.insert(marker)
        saveContext()
        fetchHistory()
        calculateStreak()
        writeWidgetSnapshot()
        rescheduleHabitNudge()

        Haptics.sessionComplete()
        SoundManager.playSuccess()
    }

    func currentWeekDates() -> [Date] {
        let cal = Calendar.current
        guard let week = cal.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: week.start) }
    }


    // MARK: - Analytics

    /// All unique exercise names that appear in session history
    var trackedExerciseNames: [String] {
        SessionAnalytics.trackedExerciseNames(sessionHistory: sessionHistory)
    }

    /// Weekly volume data — last `weeks` weeks
    func weeklyVolume(for exerciseName: String, weeks: Int = 8) -> [WeeklyVolume] {
        SessionAnalytics.weeklyVolume(for: exerciseName, weeks: weeks, sessionHistory: sessionHistory)
    }

    /// Personal best set for an exercise. Warm-up sets never count toward a PR —
    /// a heavy warm-up shouldn't falsely register as a personal record.
    func personalBest(for exerciseName: String) -> PersonalBest? {
        SessionAnalytics.personalBest(for: exerciseName, sessionHistory: sessionHistory)
    }

    /// Recent set logs for an exercise
    func recentSetLogs(for exerciseName: String, limit: Int = 10) -> [(log: SetLog, date: Date, sessionName: String)] {
        SessionAnalytics.recentSetLogs(for: exerciseName, limit: limit, sessionHistory: sessionHistory)
    }

    /// Total sessions that included a given exercise
    func sessionCount(for exerciseName: String) -> Int {
        SessionAnalytics.sessionCount(for: exerciseName, sessionHistory: sessionHistory)
    }

    /// Total kg·reps volume lifted across all sessions
    var totalVolumeLifted: Double {
        SessionAnalytics.totalVolumeLifted(sessionHistory: sessionHistory)
    }

    /// Volume lifted this calendar month
    var volumeThisMonth: Double {
        SessionAnalytics.volumeThisMonth(sessionHistory: sessionHistory)
    }

    /// Volume lifted this calendar week
    var volumeThisWeek: Double {
        SessionAnalytics.volumeThisWeek(sessionHistory: sessionHistory)
    }

    /// Sessions per day for the last `days` days — returns array ordered oldest→newest
    func dailySessionCounts(days: Int = 28) -> [(date: Date, count: Int)] {
        SessionAnalytics.dailySessionCounts(days: days, sessionHistory: sessionHistory)
    }

    /// Consistency: % of scheduled training days in last 30 days that had a workout
    var consistencyScore: Double {
        SessionAnalytics.consistencyScore(sessionHistory: sessionHistory, schedule: trainingSchedule)
    }

    /// Routine session counts sorted descending
    var sessionsByRoutine: [(routineName: String, count: Int)] {
        SessionAnalytics.sessionsByRoutine(sessionHistory: sessionHistory)
    }

    /// The week with the highest number of sessions
    var bestWeek: (start: Date, count: Int)? {
        SessionAnalytics.bestWeek(sessionHistory: sessionHistory)
    }

    // MARK: - Widget

    private func writeWidgetSnapshot() {
        SharedDataWriter.writeSnapshot(exercises: exercises, history: history, streak: currentStreak)
    }

    /// Public entry point to refresh the widget snapshot — call when the app
    /// backgrounds or returns to foreground so the Lock Screen / Home Screen
    /// widgets reflect the latest streak without waiting for iOS's own refresh
    /// budget. Recalculates the streak first in case a day boundary was crossed
    /// while the app sat open.
    func refreshWidgetSnapshot() {
        calculateStreak()
        writeWidgetSnapshot()
        rescheduleHabitNudge()
    }

    // MARK: - Watch

    private func writeWatchState() {
        let state = WatchSessionState(
            isActive:        isSessionActive,
            routineName:     activeRoutine?.name ?? "",
            exerciseName:    currentRoutineExercise?.name ?? "",
            currentSet:      currentSet,
            totalSets:       currentRoutineExercise?.sets ?? 0,
            isResting:       isResting,
            restCountdown:   restCountdown,
            totalRestSeconds: currentRoutineExercise?.restSeconds ?? 0,
            exerciseIndex:   currentExerciseIndex,
            totalExercises:  sessionExercises.count,
            updatedAt:       Date()
        )
        WatchDataWriter.write(state)
    }

    // MARK: - Siri Commands

    /// Called once per second from the rest timer loop and from onAppear.
    /// Consumes any pending Siri command and executes it on the main actor.
    func processSiriCommandIfNeeded() {
        guard let (command, routineName) = SiriCommandBus.consume() else { return }

        switch command {
        case .pauseRest:
            guard isSessionActive, isResting else { return }
            togglePause()

        case .skipRest:
            guard isSessionActive, isResting else { return }
            timerTask?.cancel()
            timerTask = nil
            isResting     = false
            restCountdown = 0
            currentSet   += 1
            autoConfirmPendingLog()
            endLiveActivity()
            writeWatchState()
            Haptics.light()

        case .completeSet:
            guard isSessionActive, !isResting, !isFinishingExercise else { return }
            completeSessionSet()

        case .endWorkout:
            guard isSessionActive || isWorkoutActive else { return }
            if isSessionActive { endSessionEarly() }
            else               { finishWorkout() }

        case .startRoutine:
            guard let name = routineName else { return }
            if let routine = routines.first(where: {
                $0.name.localizedCaseInsensitiveContains(name)
            }) {
                startSession(routine: routine)
            }
        }
    }

    // MARK: - Persistence

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("[Setflow] context.save() failed: \(error)")
        }
    }

    // MARK: - Reset / Data Management

    /// Deletes all session history (workout logs) but keeps routines, exercises,
    /// programmes, and body metrics intact. Streak resets to 0 as a result.
    func resetWorkoutHistory() {
        for session in sessionHistory { context.delete(session) }
        for entry in history { context.delete(entry) }
        saveContext()
        fetchHistory()
        fetchSessionHistory()
        calculateStreak()
        writeWidgetSnapshot()
    }

    /// Deletes all body metric entries.
    func resetBodyMetrics() {
        for metric in bodyMetrics { context.delete(metric) }
        saveContext()
        fetchBodyMetrics()
    }

    /// Deletes all programmes (and deactivates if one is active).
    func resetProgrammes() {
        for programme in programmes { context.delete(programme) }
        saveContext()
        fetchProgrammes()
    }

    /// Deletes every routine and exercise the user has created.
    func resetRoutinesAndExercises() {
        for routine in routines { context.delete(routine) }
        for exercise in exercises {
            NotificationManager.shared.removeReminders(for: exercise)
            context.delete(exercise)
        }
        saveContext()
        fetchRoutines()
        fetchExercises()
        writeWidgetSnapshot()
    }

    /// Full factory reset — wipes every model and all local preferences
    /// (schedule, onboarding flag). Does not affect data already written to
    /// Apple Health, since Health doesn't support programmatic bulk deletion
    /// of another app's past entries from here.
    func resetEverything() {
        resetWorkoutHistory()
        resetBodyMetrics()
        resetProgrammes()
        resetRoutinesAndExercises()

        trainingSchedule = .default
        trainingSchedule.save()

        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        WatchDataWriter.clear()
        writeWidgetSnapshot()
    }

    // MARK: - Live Activity

    private func startLiveActivity(name: String, set: Int, totalSets: Int, seconds: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let now   = Date()
        let end   = now.addingTimeInterval(TimeInterval(seconds))
        let attrs = SetflowLiveActivityAttributes(workoutName: name)
        let state = SetflowLiveActivityAttributes.ContentState(
            exerciseName: name, currentSet: set, totalSets: totalSets,
            secondsRemaining: seconds, totalRestSeconds: seconds, isPaused: false,
            endDate: end, startDate: now
        )
        liveActivity = try? Activity.request(
            attributes: attrs, content: .init(state: state, staleDate: end.addingTimeInterval(5)), pushType: nil
        )
    }

    private func updateLiveActivityCountdown(seconds: Int) {
        guard let la = liveActivity else { return }
        guard let ex = currentRoutineExercise ?? selectedExercise.map({
            RoutineExercise(exerciseID: $0.id, name: $0.name,
                            sets: $0.sets, reps: $0.reps,
                            restSeconds: $0.restSeconds, sortOrder: 0,
                            trackingType: $0.trackingType, defaultWeight: $0.defaultWeight)
        }) else { return }

        // Recompute the interval end from the CURRENT remaining seconds so the
        // on-device timer view stays in sync even after pause/resume. While
        // paused, endDate tracks forward each tick so the displayed time holds.
        let now = Date()
        let end = now.addingTimeInterval(TimeInterval(max(0, seconds)))

        let state = SetflowLiveActivityAttributes.ContentState(
            exerciseName: ex.name, currentSet: currentSet, totalSets: ex.sets,
            secondsRemaining: seconds, totalRestSeconds: ex.restSeconds, isPaused: isPaused,
            endDate: end, startDate: now.addingTimeInterval(-TimeInterval(ex.restSeconds - max(0, seconds)))
        )
        Task { await la.update(.init(state: state, staleDate: end.addingTimeInterval(5))) }
    }

    private func endLiveActivity() {
        guard let la = liveActivity else { return }
        Task {
            await la.end(ActivityContent(state: la.content.state, staleDate: nil),
                         dismissalPolicy: .immediate)
        }
        liveActivity = nil
    }
}
