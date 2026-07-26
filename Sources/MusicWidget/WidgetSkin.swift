import AppKit
import Combine

enum WidgetSkin: String, CaseIterable, Identifiable {
    case pill
    case cd
    case vinyl
    case ipod

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pill: "Glass Pill"
        case .cd: "CD Player"
        case .vinyl: "Vinyl Record"
        case .ipod: "iPod"
        }
    }

    var windowSize: NSSize {
        switch self {
        case .pill: NSSize(width: 320, height: 68)
        case .cd: NSSize(width: 240, height: 300)
        case .vinyl: NSSize(width: 240, height: 300)
        // Matches IPodView's `deviceBounds`: the artwork's canvas (295×486)
        // pads out to a 210×346 rect, but the device itself only fills
        // 271×456 of that — trimmed here so the window doesn't carry
        // leftover margin now that IPodView crops that padding away too.
        case .ipod: NSSize(width: 210 * 271.0 / 295.0, height: 210 * 456.0 / 295.0)
        }
    }

    /// Only the pill supports interactive resizing right now, and only
    /// along its width — like Spotify's mini player, the bar stretches
    /// while everything inside (fonts, artwork, controls) stays the same
    /// size and simply repositions toward the edges.
    var isWidthResizable: Bool { self == .pill }

    /// Matches each skin's `glassEffect` corner radius. Masking the window's
    /// content view to this shape keeps system-drawn chrome (e.g. the glass
    /// material's key-window highlight) from bleeding past the rounded card
    /// onto the window's true rectangular edge.
    var cornerRadius: CGFloat {
        switch self {
        case .pill: 20
        case .cd, .vinyl: 28
        case .ipod: 0
        }
    }

    static let pillMinWidth: CGFloat = 260
    static let pillMaxWidth: CGFloat = 640

    /// Shared with the AppKit-side window resize so the frame and the
    /// SwiftUI content transition move together instead of drifting apart.
    static let transitionDuration: TimeInterval = 0.32
}

@MainActor
final class SkinStore: ObservableObject {
    @Published var skin: WidgetSkin {
        didSet { defaults.set(skin.rawValue, forKey: Self.defaultsKey) }
    }

    private static let defaultsKey = "selectedSkin"
    private static let pillWidthDefaultsKey = "pillWidth"
    private static let windowOriginXKey = "windowOriginX"
    private static let windowOriginYKey = "windowOriginY"

    private let defaults: UserDefaults

    /// `defaults` is injectable so tests can point at an isolated
    /// `UserDefaults(suiteName:)` instead of polluting the real app's
    /// `.standard` domain.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = defaults.string(forKey: Self.defaultsKey).flatMap(WidgetSkin.init(rawValue:))
        skin = saved ?? .pill
    }

    /// The user's last hand-dragged pill width, remembered across launches
    /// and skin switches. Defaults to the pill's original design width.
    var pillWidth: CGFloat {
        get {
            let stored = defaults.double(forKey: Self.pillWidthDefaultsKey)
            let width = stored > 0 ? CGFloat(stored) : WidgetSkin.pill.windowSize.width
            return min(max(width, WidgetSkin.pillMinWidth), WidgetSkin.pillMaxWidth)
        }
        set {
            defaults.set(Double(newValue), forKey: Self.pillWidthDefaultsKey)
        }
    }

    /// The window's last on-screen position, remembered across launches.
    /// `nil` until the window has moved at least once, so a fresh install
    /// falls back to `AppDelegate`'s default top-right placement.
    var windowOrigin: NSPoint? {
        get {
            guard defaults.object(forKey: Self.windowOriginXKey) != nil else { return nil }
            let x = defaults.double(forKey: Self.windowOriginXKey)
            let y = defaults.double(forKey: Self.windowOriginYKey)
            return NSPoint(x: x, y: y)
        }
        set {
            guard let newValue else { return }
            defaults.set(Double(newValue.x), forKey: Self.windowOriginXKey)
            defaults.set(Double(newValue.y), forKey: Self.windowOriginYKey)
        }
    }
}
