import Foundation
import Testing
@testable import MiraiStreakKitUI

@Suite
struct StreakThemeTests {
    @Test
    func builtInThemesAreDistinct() {
        #expect(StreakTheme.duolingo != .healora)
        #expect(StreakTheme.healora != .aurielle)
        #expect(StreakTheme.duolingo != .aurielle)
    }

    @Test
    func themeIsValueEqualToItself() {
        #expect(StreakTheme.duolingo == .duolingo)
        #expect(StreakTheme.healora == .healora)
    }
}
