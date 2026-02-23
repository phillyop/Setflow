import AppIntents

// Tapping the widget deep-links into the app
struct OpenSetflowIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Setflow"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
