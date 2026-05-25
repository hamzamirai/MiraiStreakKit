import Foundation
import SwiftUI
import MiraiStreakKit

#if DEBUG

/// In-memory `StreakStore` for previews and tests.
public final class InMemoryStreakStore: StreakStore, @unchecked Sendable {
    private let lock = NSLock()
    private var data: Data?

    public init(initialData: Data? = nil) {
        self.data = initialData
    }

    public func read() -> Data? {
        lock.lock(); defer { lock.unlock() }
        return data
    }

    public func write(_ data: Data) throws {
        lock.lock(); defer { lock.unlock() }
        self.data = data
    }
}

public extension Streak {
    /// A sample streak with `length` consecutive completed days ending today.
    static func sample(length: Int, bestStreak: Int? = nil, freezeTokens: Int = 2) -> Streak {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let dates: [Date] = length > 0
            ? (0..<length).compactMap { offset in
                calendar.date(byAdding: .day, value: -offset, to: today)
            }
            : []
        return Streak(
            length: length,
            lastDate: dates.first,
            bestStreak: bestStreak ?? max(length, 0),
            freezeTokens: freezeTokens,
            lastFreezeDate: nil,
            completedDates: dates
        )
    }
}

public extension StreakManager {
    /// Builds a `StreakManager` seeded with the given streak — for previews.
    @MainActor
    static func preview(streak: Streak) -> StreakManager {
        let store = InMemoryStreakStore()
        if let data = try? JSONEncoder().encode(streak) {
            try? store.write(data)
        }
        return StreakManager(store: store)
    }
}

#endif
