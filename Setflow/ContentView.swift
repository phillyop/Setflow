import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        RootView()
    }
}

private struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm: WorkoutViewModel? = nil

    var body: some View {
        Group {
            if let vm {
                AppRootView(vm: vm)
            } else {
                Color.setflowBg.ignoresSafeArea()
                    .onAppear { bootstrap() }
            }
        }
    }

    private func bootstrap() {
        guard vm == nil else { return }
        MigrationManager.migrateIfNeeded(context: modelContext)
        vm = WorkoutViewModel(context: modelContext)
    }
}

private struct AppRootView: View {
    @State var vm: WorkoutViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var selectedTab: AppTab = .home

    enum AppTab { case home, progress, history, profile }

    var body: some View {
        ZStack {
            // Tab bar — always present underneath
            TabView(selection: $selectedTab) {
                HomeTabView(vm: vm)
                    .tabItem { Label("Home",     systemImage: "house.fill") }
                    .tag(AppTab.home)

                ProgressTabView(vm: vm)
                    .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                    .tag(AppTab.progress)

                NavigationStack { HistoryView(vm: vm) }
                    .tabItem { Label("History",  systemImage: "clock.arrow.circlepath") }
                    .tag(AppTab.history)

                ProfileView(vm: vm)
                    .tabItem { Label("Profile",  systemImage: "person.fill") }
                    .tag(AppTab.profile)
            }
            .tint(.setflowAccent)
            .onAppear {
                styleTabBar()
                vm.handlePendingNotificationAction()
            }

            // Fullscreen overlays — sessions and onboarding sit above the tab bar
            if showOnboarding {
                OnboardingView(vm: vm) {
                    withAnimation(.easeInOut(duration: 0.4)) { showOnboarding = false }
                }
                .transition(.opacity)
                .zIndex(10)

            } else if let summary = vm.sessionSummary {
                SessionCompleteView(vm: vm, summary: summary)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(5)

            } else if vm.isSessionActive {
                SessionScreenUI(vm: vm)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(5)

            } else if let summary = vm.workoutSummary {
                WorkoutCompleteView(vm: vm, summary: summary)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(5)

            } else if vm.isWorkoutActive, let exercise = vm.selectedExercise {
                WorkoutScreenUI(vm: vm, exercise: exercise)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(5)
            }

            if vm.isQuickWinActive {
                QuickWinView(vm: vm)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(6)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.isSessionActive)
        .animation(.easeInOut(duration: 0.3), value: vm.isWorkoutActive)
        .animation(.easeInOut(duration: 0.3), value: vm.isQuickWinActive)
        .animation(.easeInOut(duration: 0.3), value: showOnboarding)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background || phase == .active {
                vm.refreshWidgetSnapshot()
            }
            if phase == .active {
                // Route any notification the user tapped straight into action.
                vm.handlePendingNotificationAction()
            }
        }
    }

    private func styleTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.setflowBgCard)

        // Border line
        appearance.shadowColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.black.withAlphaComponent(0.08)
        }

        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Home Tab

private struct HomeTabView: View {
    var vm: WorkoutViewModel

    var body: some View {
        NavigationStack {
            ExerciseListUI(vm: vm)
        }
    }
}
