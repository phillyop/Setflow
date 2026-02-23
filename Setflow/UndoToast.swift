import SwiftUI

// MARK: - Undo Action

@Observable
class UndoAction {
    var isVisible = false
    var message: String = ""
    var onUndo: (() -> Void)?
    var onCommit: (() -> Void)?

    private var commitTask: Task<Void, Never>?

    func show(message: String, onUndo: @escaping () -> Void, onCommit: @escaping () -> Void) {
        commitTask?.cancel()
        self.message  = message
        self.onUndo   = onUndo
        self.onCommit = onCommit
        self.isVisible = true

        commitTask = Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000) // 3.5s window
            if !Task.isCancelled {
                await MainActor.run {
                    self.isVisible = false
                    onCommit()
                }
            }
        }
    }

    func undo() {
        commitTask?.cancel()
        isVisible = false
        onUndo?()
        Haptics.light()
    }

    func commit() {
        commitTask?.cancel()
        isVisible = false
        onCommit?()
    }
}

// MARK: - Toast View

struct UndoToastView: View {
    var action: UndoAction

    var body: some View {
        if action.isVisible {
            HStack(spacing: 14) {
                Text(action.message)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Button("Undo") {
                    action.undo()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.setflowBgCard)
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - View Modifier

struct UndoToastModifier: ViewModifier {
    var action: UndoAction

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            UndoToastView(action: action)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: action.isVisible)
                .zIndex(999)
        }
    }
}

extension View {
    func undoToast(_ action: UndoAction) -> some View {
        modifier(UndoToastModifier(action: action))
    }
}
