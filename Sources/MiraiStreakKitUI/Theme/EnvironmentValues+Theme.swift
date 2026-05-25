import SwiftUI

private struct StreakThemeKey: EnvironmentKey {
    static let defaultValue: StreakTheme = .duolingo
}

public extension EnvironmentValues {
    /// The active `StreakTheme` for `MiraiStreakKitUI` views.
    var streakTheme: StreakTheme {
        get { self[StreakThemeKey.self] }
        set { self[StreakThemeKey.self] = newValue }
    }
}

public extension View {
    /// Applies a `StreakTheme` to the view hierarchy.
    ///
    /// All `MiraiStreakKitUI` components read this value from the environment.
    func streakTheme(_ theme: StreakTheme) -> some View {
        environment(\.streakTheme, theme)
    }
}
