import Foundation

/// Accessibility identifiers shared between the app's views and the
/// XCUITest smoke suite (`Tests/MusicWidgetUITests`), so both sides
/// reference the same string constants instead of duplicating literals.
enum AccessibilityID {
    static let nowPlayingTitle = "nowPlayingTitle"
    static let nowPlayingSubtitle = "nowPlayingSubtitle"
    static let playPauseButton = "playPauseButton"
    static let nextButton = "nextButton"
    static let previousButton = "previousButton"

    static let pillRoot = "pillRoot"
    static let cdRoot = "cdRoot"
    static let vinylRoot = "vinylRoot"
    static let ipodRoot = "ipodRoot"

    static let quitMenuItem = "quitMenuItem"

    static func skinMenuItem(_ skin: WidgetSkin) -> String { "skinMenuItem.\(skin.rawValue)" }

    static func root(for skin: WidgetSkin) -> String {
        switch skin {
        case .pill: pillRoot
        case .cd: cdRoot
        case .vinyl: vinylRoot
        case .ipod: ipodRoot
        }
    }
}
