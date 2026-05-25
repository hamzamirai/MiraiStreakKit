import SwiftUI
import MiraiStreakKit

/// Small-system widget content: animated flame + streak length.
public struct StreakSmallWidget: View {
    private let entry: StreakWidgetEntry

    @Environment(\.streakTheme) private var theme

    public init(entry: StreakWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        VStack(spacing: 4) {
            AnimatedFlameView(
                streak: entry.streak,
                milestone: entry.milestone,
                size: 56,
                animated: false,
                interactive: false
            )
            Text(verbatim: "\(entry.streak.length)")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        gradient: entry.streak.length > 0 ? theme.flameGradient : Gradient(colors: [theme.flameInactiveColor]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text("day streak")
                .font(.system(.caption2, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.secondaryText)
                .textCase(.uppercase)
                .tracking(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
