import SwiftUI

/// A lightweight, self-contained confetti burst. No dependencies — just SwiftUI
/// shapes animated outward and down. Fires once when `trigger` flips true.
struct ConfettiView: View {
    var trigger: Bool
    var pieceCount: Int = 60

    @State private var pieces: [Piece] = []

    struct Piece: Identifiable {
        let id = UUID()
        let x: CGFloat            // horizontal start (0...1 of width)
        let color: Color
        let size: CGFloat
        let rotation: Double
        let delay: Double
        let drift: CGFloat        // horizontal drift
        let spin: Double
        let isRect: Bool
    }

    private let palette: [Color] = [
        Color(red: 0.25, green: 0.45, blue: 1.0),   // accent blue
        Color(red: 0.2,  green: 0.85, blue: 0.45),  // success green
        Color(red: 1.0,  green: 0.62, blue: 0.15),  // amber
        Color(red: 1.0,  green: 0.42, blue: 0.55),  // pink
        Color.primary
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiPiece(piece: piece, size: geo.size, active: trigger)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { generate() }
    }

    private func generate() {
        pieces = (0..<pieceCount).map { _ in
            Piece(
                x: CGFloat.random(in: 0...1),
                color: palette.randomElement()!,
                size: CGFloat.random(in: 6...11),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.25),
                drift: CGFloat.random(in: -60...60),
                spin: Double.random(in: -360...360),
                isRect: Bool.random()
            )
        }
    }
}

private struct ConfettiPiece: View {
    let piece: ConfettiView.Piece
    let size: CGSize
    let active: Bool

    @State private var fall = false

    var body: some View {
        Group {
            if piece.isRect {
                Rectangle().fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 0.5)
            } else {
                Circle().fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
            }
        }
        .rotationEffect(.degrees(piece.rotation + (fall ? piece.spin : 0)))
        .position(
            x: piece.x * size.width + (fall ? piece.drift : 0),
            y: fall ? size.height + 40 : -40
        )
        .opacity(fall ? 0 : 1)
        .onChange(of: active) { _, newValue in
            if newValue { launch() }
        }
        .onAppear { if active { launch() } }
    }

    private func launch() {
        withAnimation(.easeIn(duration: 2.2).delay(piece.delay)) {
            fall = true
        }
    }
}
