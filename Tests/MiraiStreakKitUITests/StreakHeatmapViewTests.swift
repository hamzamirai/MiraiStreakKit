import Foundation
import Testing
import MiraiStreakKit
@testable import MiraiStreakKitUI

@Suite
struct StreakHeatmapViewTests {
    private var gregorian: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    @Test
    @MainActor
    func cellCountMatchesWeeksTimesSeven() {
        let cal = gregorian
        let date = DateComponents(calendar: cal, year: 2026, month: 5, day: 8).date!
        let view = StreakHeatmapView(streak: Streak(), weeks: 12, calendar: cal, referenceDate: date)
        #expect(view.buildCells().count == 12 * 7)
    }

    @Test
    @MainActor
    func completedDateRendersCompleted() {
        let cal = gregorian
        let today = DateComponents(calendar: cal, year: 2026, month: 5, day: 8).date!
        let completed = cal.date(byAdding: .day, value: -3, to: today)!
        let streak = Streak(completedDates: [cal.startOfDay(for: completed)])
        let view = StreakHeatmapView(
            streak: streak,
            weeks: 4,
            calendar: cal,
            referenceDate: today
        )
        let cells = view.buildCells()
        let match = cells.first { cal.isDate($0.date, inSameDayAs: completed) }
        #expect(match?.state == .completed)
    }

    @Test
    @MainActor
    func zeroWeeksClampsToOne() {
        let view = StreakHeatmapView(streak: Streak(), weeks: 0)
        #expect(view.buildCells().count == 7)
    }
}
