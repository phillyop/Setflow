import SwiftUI

// MARK: - Setflow Design Tokens
// Single source of truth for colours, backgrounds, and spacing.
// Change here and it propagates everywhere.
//
// LIGHT/DARK MODE: every token below adapts automatically via Color(light:dark:).
// Screens should use these tokens (or Color.primary/.secondary for text) rather
// than literal Color.white/.black, so the whole app follows the system setting.

extension Color {
    /// Defines a color that resolves differently per color scheme, without
    /// needing an Asset Catalog entry for it.
    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    // Primary accent — blue-indigo. Reads well on both OLED black and white;
    // deepened very slightly for light mode so it doesn't wash out on white.
    static let setflowAccent = Color(
        light: Color(red: 0.15, green: 0.38, blue: 0.95),
        dark:  Color(red: 0.25, green: 0.45, blue: 1.0)
    )

    // Rest / pause state — amber, distinct from active blue
    static let setflowRest = Color(
        light: Color(red: 0.85, green: 0.5, blue: 0.0),
        dark:  Color(red: 1.0, green: 0.62, blue: 0.15)
    )

    // Success / complete
    static let setflowSuccess = Color(
        light: Color(red: 0.1, green: 0.65, blue: 0.32),
        dark:  Color(red: 0.2, green: 0.85, blue: 0.45)
    )

    // Card backgrounds — translucent lightening on dark, opaque raised white on light
    static let cardPrimary  = Color(light: .white, dark: Color.white.opacity(0.07))
    static let cardSelected = Color.setflowAccent.opacity(0.12)
    static let cardBorder   = Color(light: Color.black.opacity(0.08), dark: Color.white.opacity(0.08))

    // Page background (the "floor" screens sit on) and card/raised-surface tone.
    // Dark: near-black floor, slightly-lighter navy cards — an OLED-friendly raise.
    // Light: soft gray floor, white cards — the standard iOS grouped-list raise.
    static let setflowBg     = Color(light: Color(red: 0.95, green: 0.95, blue: 0.97),
                                      dark:  Color(red: 0.04, green: 0.04, blue: 0.08))
    static let setflowBgCard = Color(light: .white,
                                      dark:  Color(red: 0.08, green: 0.08, blue: 0.13))

    // The two stops of the standard full-screen background gradient, so every
    // screen can share one definition instead of hand-rolling its own (several
    // had drifted to slightly different literal values over time).
    static let setflowBgGradientTop = Color(light: .white, dark: .black)
    static let setflowBgGradientBottom = setflowBgCard
}

extension View {
    /// Standard Setflow card style
    func setflowCard(selected: Bool = false) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(selected ? Color.cardSelected : Color.cardPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(selected ? Color.setflowAccent.opacity(0.3) : Color.cardBorder,
                                    lineWidth: 1)
                    )
            )
    }

    /// The standard full-screen background used by session, completion, and
    /// Quick Win screens — a single definition so all of them move together
    /// and adapt to light/dark instead of each hard-coding its own gradient.
    func setflowScreenBackground() -> some View {
        self.background(
            LinearGradient(
                colors: [Color.setflowBgGradientTop, Color.setflowBgGradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
