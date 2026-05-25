import SwiftUI
import MiraiStreakKit

/// A 7-day strip showing completion state for the current week.
///
/// Day order respects `Calendar.firstWeekday`. Each day is one of:
/// - **completed** — filled circle with checkmark in `theme.checkmarkColor`
/// - **today (incomplete)** — outlined ring in `theme.glowColor`
/// - **future** — dimmed empty circle
/// - **missed** — dim circle with subtle `xmark`
public struct WeekStripView: View {
    private let streak: Streak
    private let referenceDate: Date
    private let calendar: Calendar
    private let dotSize: CGFloat

    @Environment(\.streakTheme) private var theme
    @State private var hasAppeared = false

    public init(
        streak: Streak,
        referenceDate: Date = .now,
        calendar: Calendar = .current,
        dotSize: CGFloat = 36
    ) {
        self.streak = streak
        self.referenceDate = referenceDate
        self.calendar = calendar
        self.dotSize = dotSize
    }

    public var body: some View {
        let days = weekDays()

        HStack(spacing: 8) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                VStack(spacing: 6) {
                    Text(verbatim: weekdaySymbol(for: day.date))
                        .font(theme.captionFont)
                        .foregroundStyle(theme.secondaryText)

                    dot(for: day)
                        .frame(width: dotSize, height: dotSize)
                        .scaleEffect(hasAppeared ? 1.0 : 0.6)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .animation(
                            .spring(duration: 0.45, bounce: 0.35).delay(Double(index) * 0.05),
                            value: hasAppeared
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { hasAppeared = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(days: days))
    }

    @ViewBuilder
    private func dot(for day: Day) -> some View {
        switch day.state {
        case .completed:
            ZStack {
                Circle().fill(theme.checkmarkColor)
                Image(systemName: "checkmark")
                    .font(.system(size: dotSize * 0.45, weight: .bold))
                    .foregroundStyle(.white)
            }
        case .today:
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: theme.flameGradient,
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
                Circle()
                    .fill(theme.glowColor.opacity(0.12))
            }
        case .missed:
            ZStack {
                Circle().fill(theme.cardBackground)
                Image(systemName: "xmark")
                    .font(.system(size: dotSize * 0.35, weight: .semibold))
                    .foregroundStyle(theme.secondaryText.opacity(0.6))
            }
        case .future:
            Circle().fill(theme.cardBackground.opacity(0.6))
        }
    }

    // MARK: - Week computation

    struct Day: Sendable, Equatable {
        enum State: Sendable, Equatable {
            case completed, today, missed, future
        }
        let date: Date
        let state: State
    }

    func weekDays() -> [Day] {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start else {
            return []
        }
        let today = calendar.startOfDay(for: referenceDate)

        return (0..<7).compactMap { offset -> Day? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            let dayStart = calendar.startOfDay(for: date)
            let isToday = calendar.isDate(dayStart, inSameDayAs: today)
            let isFuture = dayStart > today
            let completed = streak.hasCompleted(on: dayStart, calendar: calendar)

            let state: Day.State = {
                if completed { return .completed }
                if isToday { return .today }
                if isFuture { return .future }
                return .missed
            }()
            return Day(date: dayStart, state: state)
        }
    }

    private func weekdaySymbol(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? .current
        let symbols = formatter.veryShortStandaloneWeekdaySymbols ?? formatter.veryShortWeekdaySymbols ?? []
        let index = calendar.component(.weekday, from: date) - 1
        guard symbols.indices.contains(index) else { return "" }
        return symbols[index]
    }

    private func accessibilityLabel(days: [Day]) -> Text {
        let completed = days.filter { $0.state == .completed }.count
        return Text("\(completed) of 7 days completed this week")
    }
}
