import SwiftUI
import MiraiStreakKit

/// Medium-system widget content: flame + number on the left, week strip on the right.
public struct StreakMediumWidget: View {
    private let entry: StreakWidgetEntry

    @Environment(\.streakTheme) private var theme

    public init(entry: StreakWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
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
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                Text("This week")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.secondaryText)
                    .textCase(.uppercase)
                    .tracking(1)

                WeekStripView(streak: entry.streak, referenceDate: entry.date, dotSize: 26)

                HStack(spacing: 8) {
                    BestStreakBadge(best: entry.streak.bestStreak, compact: true)
                    FreezeTokenBadge(count: entry.streak.freezeTokens, compact: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
    }
}
