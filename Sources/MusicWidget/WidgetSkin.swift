import AppKit
import Combine

enum WidgetSkin: String, CaseIterable, Identifiable {
    case pill
    case cd
    case ipod

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pill: "Glass Pill"
        case .cd: "Rotating CD"
        case .ipod: "iPod"
        }
    }

    var windowSize: NSSize {
        switch self {
        case .pill: NSSize(width: 320, height: 68)
        case .cd: NSSize(width: 240, height: 300)
        case .ipod: NSSize(width: 220, height: 334)
        }
    }
}

@MainActor
final class SkinStore: ObservableObject {
    @Published var skin: WidgetSkin {
        didSet { UserDefaults.standard.set(skin.rawValue, forKey: Self.defaultsKey) }
    }

    private static let defaultsKey = "selectedSkin"

    init() {
        let saved = UserDefaults.standard.string(forKey: Self.defaultsKey).flatMap(WidgetSkin.init(rawValue:))
        skin = saved ?? .pill
    }
}
