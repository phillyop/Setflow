import SwiftUI

struct WatchRootView: View {
    @State private var state: WatchSessionState? = nil
    @State private var timer: Timer? = nil

    var body: some View {
        Group {
            if let state, state.isActive {
                WatchSessionView(state: state)
            } else {
                WatchIdleView()
            }
        }
        .onAppear {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                state = WatchDataReader.load()
            }
        }
        .onDisappear { timer?.invalidate() }
    }
}

struct WatchIdleView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 36))
                .foregroundColor(.blue)
            Text("Setflow")
                .font(.headline)
                .foregroundColor(.white)
            Text("Start a session\non your iPhone")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }
}
