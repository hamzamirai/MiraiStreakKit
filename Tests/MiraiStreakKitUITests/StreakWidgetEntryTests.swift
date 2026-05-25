import Foundation
import Testing
import MiraiStreakKit
@testable import MiraiStreakKitUI

@Suite
struct StreakWidgetEntryTests {
    @Test
    func codableRoundTrip() throws {
        let streak = Streak(length: 5, lastDate: .now, bestStreak: 10, freezeTokens: 2)
        let entry = StreakWidgetEntry(date: .now, streak: streak, milestone: 7)

        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(StreakWidgetEntry.self, from: data)

        #expect(decoded.streak.length == 5)
        #expect(decoded.milestone == 7)
        #expect(decoded.streak.bestStreak == 10)
    }

    @Test
    func currentReturnsEmptyStreakWhenStoreIsEmpty() {
        let store = InMemoryStreakStore()
        let entry = StreakWidgetEntry.current(from: store, milestone: 7)
        #expect(entry.streak.length == 0)
        #expect(entry.streak.bestStreak == 0)
        #expect(entry.milestone == 7)
    }

    @Test
    func currentDecodesFromStore() throws {
        let original = Streak(length: 3, lastDate: .now, bestStreak: 4, freezeTokens: 1)
        let data = try JSONEncoder().encode(original)
        let store = InMemoryStreakStore(initialData: data)

        let entry = StreakWidgetEntry.current(from: store, milestone: 5)
        #expect(entry.streak.length == 3)
        #expect(entry.streak.bestStreak == 4)
        #expect(entry.milestone == 5)
    }

    @Test
    func placeholderReturnsSampleData() {
        let entry = StreakWidgetEntry.placeholder()
        #expect(entry.streak.length > 0)
    }
}
