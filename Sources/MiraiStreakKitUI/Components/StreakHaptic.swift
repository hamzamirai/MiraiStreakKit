import Foundation

#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

#if os(watchOS)
import WatchKit
#endif

/// Lightweight haptic helper used by interactive streak components.
///
/// Compiled to a no-op on platforms (or extension types) where haptics are unavailable.
enum StreakHaptic {
    enum Style: Sendable {
        case light
        case medium
        case heavy
        case success
    }

    @MainActor
    static func play(_ style: Style) {
        #if canImport(UIKit) && !os(watchOS) && !os(visionOS) && !os(tvOS)
        switch style {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        #elseif os(watchOS)
        switch style {
        case .light, .medium:
            WKInterfaceDevice.current().play(.click)
        case .heavy:
            WKInterfaceDevice.current().play(.directionUp)
        case .success:
            WKInterfaceDevice.current().play(.success)
        }
        #endif
    }
}
