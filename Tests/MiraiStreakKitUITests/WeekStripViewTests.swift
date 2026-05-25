import Foundation
import Testing
import MiraiStreakKit
@testable import MiraiStreakKitUI

@Suite
struct WeekStripViewTests {
    private var gregorian: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    @Test
    @MainActor
    func sevenDaysProduced() {
        let cal = gregorian
        let date = DateComponents(calendar: cal, year: 2026, month: 5, day: 8).date!
        let view = WeekStripView(streak: Streak(), referenceDate: date, calendar: cal)
        #expect(view.weekDays().count == 7)
    }

    @Test
    @MainActor
    func todayCellIsTodayWhenNotCompleted() {
        let cal = gregorian
        let today = DateComponents(calendar: cal, year: 2026, month: 5, day: 8).date!
        let view = WeekStripView(streak: Streak(), referenceDate: today, calendar: cal)
        let days = view.weekDays()

        let todayIndex = days.firstIndex { cal.isDate($0.date, inSameDayAs: today) }
        #expect(todayIndex != nil)
        #expect(days[todayIndex!].state == .today)
    }

    @Test
    @MainActor
    func completedDayIsCompleted() {
        let cal = gregorian
        let today = DateComponents(calendar: cal, year: 2026, month: 5, day: 8).date!
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let streak = Streak(
            length: 1,
            lastDate: yesterday,
            completedDates: [cal.startOfDay(for: yesterday)]
        )
        let view = WeekStripView(streak: streak, referenceDate: today, calendar: cal)
        let days = view.weekDays()

        let yIndex = days.firstIndex { cal.isDate($0.date, inSameDayAs: yesterday) }!
        #expect(days[yIndex].state == .completed)
    }

    @Test
    @MainActor
    func futureDayIsFuture() {
        let cal = gregorian
        let today = DateComponents(calendar: cal, year: 2026, month: 5, day: 4).date! // Mon-ish
        let view = WeekStripView(streak: Streak(), referenceDate: today, calendar: cal)
        let days = view.weekDays()

        // At least one of the 7 days in the week is strictly after today.
        let hasFuture = days.contains { $0.state == .future }
        #expect(hasFuture)
    }
}
