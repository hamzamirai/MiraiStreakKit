import SwiftUI
import MiraiStreakKit

/// GitHub-style heatmap rendering the last `weeks` weeks of completion.
///
/// 7 rows (weekdays) × `weeks` columns. Cell color comes from the active
/// `StreakTheme` (completed → checkmark color; missed → muted card; future → clear).
public struct StreakHeatmapView: View {
    private let streak: Streak
    private let weeks: Int
    private let calendar: Calendar
    private let referenceDate: Date
    private let cellSize: CGFloat
    private let cellSpacing: CGFloat

    @Environment(\.streakTheme) private var theme

    public init(
        streak: Streak,
        weeks: Int = 12,
        calendar: Calendar = .current,
        referenceDate: Date = .now,
        cellSize: CGFloat = 14,
        cellSpacing: CGFloat = 4
    ) {
        self.streak = streak
        self.weeks = max(1, weeks)
        self.calendar = calendar
        self.referenceDate = referenceDate
        self.cellSize = cellSize
        self.cellSpacing = cellSpacing
    }

    public var body: some View {
        let cells = buildCells()
        let columns = Array(
            repeating: GridItem(.fixed(cellSize), spacing: cellSpacing),
            count: weeks
        )

        LazyVGrid(columns: columns, spacing: cellSpacing) {
            ForEach(cells.indices, id: \.self) { index in
                cellView(for: cells[index])
                    .frame(width: cellSize, height: cellSize)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Streak heatmap, last \(weeks) weeks"))
    }

    @ViewBuilder
    private func cellView(for cell: Cell) -> some View {
        switch cell.state {
        case .completed:
            RoundedRectangle(cornerRadius: cellSize * 0.25, style: .continuous)
                .fill(theme.checkmarkColor)
        case .missed:
            RoundedRectangle(cornerRadius: cellSize * 0.25, style: .continuous)
                .fill(theme.cardBackground.opacity(0.6))
        case .future:
            RoundedRectangle(cornerRadius: cellSize * 0.25, style: .continuous)
                .fill(Color.clear)
        }
    }

    // MARK: - Cell computation

    struct Cell: Sendable, Equatable {
        enum State: Sendable, Equatable {
            case completed, missed, future
        }
        let date: Date
        let state: State
    }

    func buildCells() -> [Cell] {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start,
              let firstDay = calendar.date(byAdding: .day, value: -7 * (weeks - 1), to: weekStart) else {
            return []
        }
        let totalDays = weeks * 7
        let today = calendar.startOfDay(for: referenceDate)

        return (0..<totalDays).compactMap { offset -> Cell? in
            // Layout is column-major (week down, then next week) but LazyVGrid lays
            // out row-major. Convert: row = weekday (0..6), col = weekIndex (0..weeks-1).
            let row = offset / weeks
            let col = offset % weeks
            let dayOffset = col * 7 + row

            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: firstDay) else { return nil }
            let dayStart = calendar.startOfDay(for: date)

            let state: Cell.State
            if dayStart > today {
                state = .future
            } else if streak.hasCompleted(on: dayStart, calendar: calendar) {
                state = .completed
            } else {
                state = .missed
            }
            return Cell(date: dayStart, state: state)
        }
    }
}
