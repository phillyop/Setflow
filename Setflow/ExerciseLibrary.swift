import Foundation

// MARK: - Preset Exercise

struct PresetExercise: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: String
    let sets: Int
    let reps: Int
    let restSeconds: Int
    let trackingType: String
    let defaultWeight: Double

    init(name: String, category: String, sets: Int, reps: Int,
         restSeconds: Int, trackingType: ExerciseTrackingType, defaultWeight: Double = 0) {
        self.id            = UUID()
        self.name          = name
        self.category      = category
        self.sets          = sets
        self.reps          = reps
        self.restSeconds   = restSeconds
        self.trackingType  = trackingType.rawValue
        self.defaultWeight = defaultWeight
    }

    var tracking: ExerciseTrackingType {
        ExerciseTrackingType(rawValue: trackingType) ?? .bodyweight
    }

    func toExercise(sortOrder: Int) -> Exercise {
        Exercise(
            name: name, sets: sets, reps: reps,
            restSeconds: restSeconds, sortOrder: sortOrder,
            trackingType: tracking, defaultWeight: defaultWeight
        )
    }
}

// MARK: - Library

enum ExerciseLibrary {

    static let categories = ["Chest", "Back", "Shoulders", "Arms", "Legs", "Core", "Cardio", "Full Body"]

    static let presets: [PresetExercise] = [
        // CHEST
        PresetExercise(name: "Push-ups",          category: "Chest",     sets: 4, reps: 15, restSeconds: 60,  trackingType: .bodyweight),
        PresetExercise(name: "Bench Press",        category: "Chest",     sets: 4, reps: 8,  restSeconds: 90,  trackingType: .weighted, defaultWeight: 40),
        PresetExercise(name: "Incline DB Press",   category: "Chest",     sets: 3, reps: 10, restSeconds: 75,  trackingType: .weighted, defaultWeight: 20),
        PresetExercise(name: "Chest Dips",         category: "Chest",     sets: 3, reps: 12, restSeconds: 60,  trackingType: .bodyweight),
        PresetExercise(name: "Cable Flye",         category: "Chest",     sets: 3, reps: 12, restSeconds: 60,  trackingType: .weighted, defaultWeight: 15),
        PresetExercise(name: "Decline Push-ups",   category: "Chest",     sets: 3, reps: 15, restSeconds: 45,  trackingType: .bodyweight),

        // BACK
        PresetExercise(name: "Pull-ups",           category: "Back",      sets: 3, reps: 8,  restSeconds: 90,  trackingType: .bodyweight),
        PresetExercise(name: "Barbell Row",        category: "Back",      sets: 4, reps: 8,  restSeconds: 90,  trackingType: .weighted, defaultWeight: 50),
        PresetExercise(name: "DB Row",             category: "Back",      sets: 3, reps: 10, restSeconds: 60,  trackingType: .weighted, defaultWeight: 20),
        PresetExercise(name: "Lat Pulldown",       category: "Back",      sets: 3, reps: 12, restSeconds: 60,  trackingType: .weighted, defaultWeight: 40),
        PresetExercise(name: "Seated Cable Row",   category: "Back",      sets: 3, reps: 12, restSeconds: 60,  trackingType: .weighted, defaultWeight: 35),
        PresetExercise(name: "Deadlift",           category: "Back",      sets: 3, reps: 5,  restSeconds: 120, trackingType: .weighted, defaultWeight: 60),

        // SHOULDERS
        PresetExercise(name: "Overhead Press",     category: "Shoulders", sets: 4, reps: 8,  restSeconds: 90,  trackingType: .weighted, defaultWeight: 30),
        PresetExercise(name: "DB Shoulder Press",  category: "Shoulders", sets: 3, reps: 10, restSeconds: 75,  trackingType: .weighted, defaultWeight: 15),
        PresetExercise(name: "Lateral Raises",     category: "Shoulders", sets: 3, reps: 15, restSeconds: 45,  trackingType: .weighted, defaultWeight: 8),
        PresetExercise(name: "Front Raises",       category: "Shoulders", sets: 3, reps: 12, restSeconds: 45,  trackingType: .weighted, defaultWeight: 8),
        PresetExercise(name: "Face Pulls",         category: "Shoulders", sets: 3, reps: 15, restSeconds: 45,  trackingType: .weighted, defaultWeight: 15),
        PresetExercise(name: "Pike Push-ups",      category: "Shoulders", sets: 3, reps: 12, restSeconds: 60,  trackingType: .bodyweight),

        // ARMS
        PresetExercise(name: "Bicep Curl",         category: "Arms",      sets: 3, reps: 12, restSeconds: 60,  trackingType: .weighted, defaultWeight: 12),
        PresetExercise(name: "Hammer Curl",        category: "Arms",      sets: 3, reps: 12, restSeconds: 60,  trackingType: .weighted, defaultWeight: 12),
        PresetExercise(name: "Tricep Dips",        category: "Arms",      sets: 3, reps: 12, restSeconds: 60,  trackingType: .bodyweight),
        PresetExercise(name: "Tricep Pushdown",    category: "Arms",      sets: 3, reps: 15, restSeconds: 45,  trackingType: .weighted, defaultWeight: 15),
        PresetExercise(name: "Skull Crushers",     category: "Arms",      sets: 3, reps: 10, restSeconds: 60,  trackingType: .weighted, defaultWeight: 15),
        PresetExercise(name: "Chin-ups",           category: "Arms",      sets: 3, reps: 8,  restSeconds: 90,  trackingType: .bodyweight),

        // LEGS
        PresetExercise(name: "Barbell Squat",      category: "Legs",      sets: 4, reps: 8,  restSeconds: 120, trackingType: .weighted, defaultWeight: 60),
        PresetExercise(name: "DB Goblet Squat",    category: "Legs",      sets: 3, reps: 12, restSeconds: 75,  trackingType: .weighted, defaultWeight: 20),
        PresetExercise(name: "Bodyweight Squat",   category: "Legs",      sets: 4, reps: 20, restSeconds: 45,  trackingType: .bodyweight),
        PresetExercise(name: "Romanian Deadlift",  category: "Legs",      sets: 3, reps: 10, restSeconds: 90,  trackingType: .weighted, defaultWeight: 40),
        PresetExercise(name: "Leg Press",          category: "Legs",      sets: 3, reps: 12, restSeconds: 90,  trackingType: .weighted, defaultWeight: 60),
        PresetExercise(name: "Walking Lunges",     category: "Legs",      sets: 3, reps: 12, restSeconds: 60,  trackingType: .weighted, defaultWeight: 12),
        PresetExercise(name: "Bulgarian Split Squat", category: "Legs",   sets: 3, reps: 10, restSeconds: 75,  trackingType: .weighted, defaultWeight: 15),
        PresetExercise(name: "Calf Raises",        category: "Legs",      sets: 4, reps: 20, restSeconds: 45,  trackingType: .weighted, defaultWeight: 20),
        PresetExercise(name: "Glute Bridge",       category: "Legs",      sets: 3, reps: 15, restSeconds: 45,  trackingType: .bodyweight),

        // CORE
        PresetExercise(name: "Plank",              category: "Core",      sets: 3, reps: 45, restSeconds: 45,  trackingType: .bodyweight),
        PresetExercise(name: "Crunches",           category: "Core",      sets: 3, reps: 20, restSeconds: 30,  trackingType: .bodyweight),
        PresetExercise(name: "Russian Twists",     category: "Core",      sets: 3, reps: 20, restSeconds: 30,  trackingType: .bodyweight),
        PresetExercise(name: "Leg Raises",         category: "Core",      sets: 3, reps: 15, restSeconds: 45,  trackingType: .bodyweight),
        PresetExercise(name: "Mountain Climbers",  category: "Core",      sets: 3, reps: 30, restSeconds: 30,  trackingType: .bodyweight),
        PresetExercise(name: "Ab Wheel Rollout",   category: "Core",      sets: 3, reps: 10, restSeconds: 60,  trackingType: .bodyweight),
        PresetExercise(name: "Side Plank",         category: "Core",      sets: 3, reps: 30, restSeconds: 30,  trackingType: .bodyweight),

        // CARDIO
        PresetExercise(name: "Jumping Jacks",      category: "Cardio",    sets: 3, reps: 40, restSeconds: 30,  trackingType: .bodyweight),
        PresetExercise(name: "Burpees",            category: "Cardio",    sets: 3, reps: 15, restSeconds: 60,  trackingType: .bodyweight),
        PresetExercise(name: "High Knees",         category: "Cardio",    sets: 3, reps: 40, restSeconds: 30,  trackingType: .bodyweight),
        PresetExercise(name: "Jump Rope",          category: "Cardio",    sets: 5, reps: 60, restSeconds: 30,  trackingType: .bodyweight),
        PresetExercise(name: "Box Jumps",          category: "Cardio",    sets: 3, reps: 10, restSeconds: 60,  trackingType: .bodyweight),

        // FULL BODY
        PresetExercise(name: "KB Swings",          category: "Full Body", sets: 4, reps: 20, restSeconds: 60,  trackingType: .weighted, defaultWeight: 16),
        PresetExercise(name: "Thrusters",          category: "Full Body", sets: 3, reps: 15, restSeconds: 75,  trackingType: .weighted, defaultWeight: 15),
        PresetExercise(name: "Clean & Press",      category: "Full Body", sets: 3, reps: 8,  restSeconds: 90,  trackingType: .weighted, defaultWeight: 30),
        PresetExercise(name: "Renegade Row",       category: "Full Body", sets: 3, reps: 10, restSeconds: 75,  trackingType: .weighted, defaultWeight: 12),
        PresetExercise(name: "Turkish Get-up",     category: "Full Body", sets: 3, reps: 5,  restSeconds: 90,  trackingType: .weighted, defaultWeight: 12),
    ]

    static func presets(for category: String) -> [PresetExercise] {
        presets.filter { $0.category == category }
    }

    static func search(_ query: String) -> [PresetExercise] {
        guard !query.isEmpty else { return presets }
        return presets.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}
