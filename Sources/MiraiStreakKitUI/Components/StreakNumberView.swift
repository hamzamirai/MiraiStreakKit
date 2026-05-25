import SwiftUI

/// Renders the streak length as a giant rounded numeral with smooth digit transitions.
///
/// Uses `.contentTransition(.numericText)` so each digit rolls when the
/// streak increments — the Duolingo signature.
public struct StreakNumberView: View {
    private let length: Int
    private let size: CGFloat?

    @Environment(\.streakTheme) private var theme

    public init(length: Int, size: CGFloat? = nil) {
        self.length = length
        self.size = size
    }

    public var body: some View {
        Text(verbatim: "\(length)")
            .font(font)
            .foregroundStyle(foreground)
            .contentTransition(.numericText(value: Double(length)))
            .animation(.smooth(duration: 0.45), value: length)
            .accessibilityLabel(Text("Streak \(length)"))
    }

    private var font: Font {
        if let size {
            return .system(size: size, weight: .heavy, design: .rounded)
        }
        return theme.headlineFont
    }

    private var foreground: AnyShapeStyle {
        if length <= 0 {
            return AnyShapeStyle(theme.flameInactiveColor)
        }
        return AnyShapeStyle(
            LinearGradient(
                gradient: theme.flameGradient,
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
