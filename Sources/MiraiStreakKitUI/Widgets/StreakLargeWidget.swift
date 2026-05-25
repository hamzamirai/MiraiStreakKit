import SwiftUI
import MiraiStreakKit

/// Large-system widget content: flame + number, week strip, and 12-week heatmap.
public struct StreakLargeWidget: View {
    private let entry: StreakWidgetEntry

    @Environment(\.streakTheme) private var theme

    public init(entry: StreakWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                AnimatedFlameView(
                    streak: entry.streak,
                    milestone: entry.milestone,
                    size: 64,
                    animated: false,
                    interactive: false
                )
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: "\(entry.streak.length)")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
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
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.secondaryText)
                        .textCase(.uppercase)
                        .tracking(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    BestStreakBadge(best: entry.streak.bestStreak, compact: true)
                    FreezeTokenBadge(count: entry.streak.freezeTokens, compact: true)
                }
            }

            WeekStripView(streak: entry.streak, referenceDate: entry.date, dotSize: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text("Last 12 weeks")
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.secondaryText)
                    .textCase(.uppercase)
                    .tracking(1)
                StreakHeatmapView(
                    streak: entry.streak,
                    weeks: 12,
                    referenceDate: entry.date,
                    cellSize: 14,
                    cellSpacing: 3
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
    }
}
