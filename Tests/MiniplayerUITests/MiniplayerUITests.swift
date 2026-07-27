import XCTest

/// Drives the real, built `dist/Miniplayer-Debug.app` against the
/// fake-player harness (`MINIPLAYER_UI_TEST=1`, see
/// `main.swift`/`FakeMediaAppController`) so these tests exercise actual UI
/// states without needing Spotify/Music installed. Must be the *debug*
/// build specifically — the fake-player harness is `#if DEBUG`-gated and
/// isn't compiled into the release build that `dist/Miniplayer.app` is.
///
/// This lives in a standalone Xcode project (`MiniplayerUITests.xcodeproj`
/// at the repo root, "UI Testing Bundle" target with no host app) because
/// `XCUIApplication` cannot run inside a plain SwiftPM `swift test` bundle
/// at all — macOS refuses it outright ("Device is not configured for UI
/// testing"), regardless of permissions. Real XCUITest requires the runner
/// wrapper that only `xcodebuild test` produces.
///
/// The identifier strings below intentionally duplicate
/// `Sources/Miniplayer/AccessibilityID.swift` rather than importing it:
/// linking an executable SwiftPM target's implicit product into a separate
/// Xcode project for `@testable import` is unproven territory, and a UI
/// test target has no real need to compile against the app's internals
/// anyway — only its accessibility surface. Keep the literal values here in
/// sync with `AccessibilityID.swift` if either changes.
///
/// Requires `./Packaging/build-app.sh --debug` to have been run first, and
/// (for the very first run on a given Mac) Accessibility permission granted
/// to Xcode/the UI test runner under System Settings → Privacy & Security →
/// Accessibility — see the "Testing" section of the README.
@MainActor
final class MiniplayerUITests: XCTestCase {
    private enum ID {
        static let nowPlayingTitle = "nowPlayingTitle"
        static let nowPlayingSubtitle = "nowPlayingSubtitle"
        static let playPauseButton = "playPauseButton"
        static let pillRoot = "pillRoot"
        static let cdRoot = "cdRoot"
        static let vinylRoot = "vinylRoot"
        static let ipodRoot = "ipodRoot"

        static func skinMenuItem(_ rawValue: String) -> String { "skinMenuItem.\(rawValue)" }
        static func root(forSkinRawValue rawValue: String) -> String {
            switch rawValue {
            case "cd": cdRoot
            case "vinyl": vinylRoot
            case "ipod": ipodRoot
            default: pillRoot
            }
        }
    }

    private static let debugBundleID = "com.shazibid.Miniplayer.debug"

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        // SkinStore persists the selected skin (and window position/pill
        // width) to this bundle ID's real UserDefaults domain on disk, so a
        // previous run — especially one that failed mid-test, like partway
        // through switching skins — otherwise leaks its skin choice into
        // this run and breaks the "pill is the default on a fresh launch"
        // assumption below.
        UserDefaults(suiteName: Self.debugBundleID)?.removePersistentDomain(forName: Self.debugBundleID)

        let appURL = try Self.builtAppURL()
        app = XCUIApplication(url: appURL)
        app.launchEnvironment["MINIPLAYER_UI_TEST"] = "1"
        app.launch()
    }

    override func tearDown() {
        app.terminate()
    }

    func testShowsFakeTrackOnLaunch() {
        let title = app.staticTexts[ID.nowPlayingTitle]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.value as? String ?? title.label, "Test Song")

        let subtitle = app.staticTexts[ID.nowPlayingSubtitle]
        XCTAssertTrue(subtitle.exists)
    }

    func testPlayPauseButtonExistsAndIsTappable() {
        let playPause = app.buttons[ID.playPauseButton]
        XCTAssertTrue(playPause.waitForExistence(timeout: 10))
        XCTAssertTrue(playPause.isEnabled)
        playPause.click()
    }

    func testSkinSwitchingShowsEachRoot() {
        XCTAssertTrue(
            app.groups[ID.pillRoot].firstMatch.waitForExistence(timeout: 10),
            "Pill is the default skin on a fresh launch"
        )

        // Right-click the window itself rather than a specific skin's root
        // element: the context menu is attached to RootView's full content,
        // so this works no matter which skin is currently showing — unlike
        // caching one skin's root, which stops existing once we switch away
        // from it.
        let window = app.windows.firstMatch

        for skin in ["cd", "vinyl", "ipod", "pill"] {
            window.rightClick()
            let menuItem = app.menuItems[ID.skinMenuItem(skin)]
            XCTAssertTrue(menuItem.waitForExistence(timeout: 5), "Missing context menu item for \(skin)")
            menuItem.click()

            let root = app.groups[ID.root(forSkinRawValue: skin)].firstMatch
            XCTAssertTrue(root.waitForExistence(timeout: 5), "\(skin) root element didn't appear after switching")
        }
    }

    /// Resolves `dist/Miniplayer-Debug.app`, built by
    /// `Packaging/build-app.sh --debug`, relative to this file's location
    /// (`Tests/MiniplayerUITests/`, two levels below the package root).
    private static func builtAppURL() throws -> URL {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let appURL = packageRoot.appendingPathComponent("dist/Miniplayer-Debug.app")
        guard FileManager.default.fileExists(atPath: appURL.path) else {
            throw XCTSkip("dist/Miniplayer-Debug.app not found — run ./Packaging/build-app.sh --debug first.")
        }
        return appURL
    }
}
