import SwiftUI

/// A trophy badge showing the user's best (longest) streak.
public struct BestStreakBadge: View {
    private let best: Int
    private let compact: Bool

    @Environment(\.streakTheme) private var theme

    public init(best: Int, compact: Bool = false) {
        self.best = best
        self.compact = compact
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "trophy.fill")
                .font(.system(size: compact ? 13 : 17, weight: .bold))
                .foregroundStyle(theme.trophyColor)
            Text(verbatim: "\(best)")
                .font(.system(.body, design: .rounded).weight(.bold))
                .foregroundStyle(theme.primaryText)
                .contentTransition(.numericText(value: Double(best)))
                .animation(.smooth(duration: 0.3), value: best)
        }
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 4 : 8)
        .background(theme.cardBackground, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Best streak \(best) days"))
    }
}
