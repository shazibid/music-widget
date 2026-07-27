import AppKit
import Combine
import QuartzCore
import SwiftUI

/// Plain `NSWindow` refuses key/main status when borderless, which breaks
/// right-click context menus and click-to-focus. Overriding both fixes it.
final class FloatingWidgetWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Without this, the widget's first click while the app is inactive (which is
/// nearly always, since Spotify/whatever else is frontmost) is swallowed just
/// to bring the window forward instead of being delivered as a real click.
final class ClickableHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private let viewModel = PlayerViewModel()
    private let skinStore = SkinStore()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let hosting = ClickableHostingView(
            rootView: RootView(viewModel: viewModel, skinStore: skinStore, onMinimize: { [weak self] in self?.minimizeToDock() })
        )

        let initialSize = size(for: skinStore.skin)
        let window = FloatingWidgetWindow(
            contentRect: NSRect(x: 0, y: 0, width: initialSize.width, height: initialSize.height),
            // `.miniaturizable` has no visual effect without `.titled` (no
            // title bar appears) but is required for `miniaturize(_:)` to
            // work — without it the window just refuses to minimize.
            // `.resizable` is added/removed per-skin in `configureResizability`.
            styleMask: [.borderless, .fullSizeContentView, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = hosting
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.delegate = self
        configureResizability(of: window, for: skinStore.skin)
        applyCornerMask(to: hosting, for: skinStore.skin)

        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            if var origin = skinStore.windowOrigin {
                // Clamp in case the saved spot came from a screen/resolution
                // that's no longer available (e.g. an external monitor).
                origin.x = min(max(origin.x, visible.minX), visible.maxX - initialSize.width)
                origin.y = min(max(origin.y, visible.minY), visible.maxY - initialSize.height)
                window.setFrameOrigin(origin)
            } else {
                let origin = NSPoint(x: visible.maxX - 20 - initialSize.width, y: visible.maxY - 20 - initialSize.height)
                window.setFrameOrigin(origin)
            }
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window

        skinStore.$skin
            .dropFirst()
            .sink { [weak self] newSkin in
                self?.resizeWindow(for: newSkin)
            }
            .store(in: &cancellables)

        viewModel.startPolling()
    }

    /// Sends the widget into the Dock as a live thumbnail, same as clicking a
    /// normal window's minimize button — works even though the app itself
    /// has no permanent Dock icon (`.accessory` policy). Clicking that Dock
    /// tile restores the window; no extra handling needed.
    private func minimizeToDock() {
        window?.miniaturize(nil)
    }

    private func resizeWindow(for skin: WidgetSkin) {
        guard let window else { return }
        configureResizability(of: window, for: skin)
        if let contentView = window.contentView {
            applyCornerMask(to: contentView, for: skin)
        }
        let newSize = size(for: skin)
        // Anchor on the old frame's center, not a corner, so switching to a
        // much taller/narrower skin grows or shrinks symmetrically instead
        // of appearing to leap toward one edge.
        let center = NSPoint(x: window.frame.midX, y: window.frame.midY)
        var newFrame = NSRect(
            x: center.x - newSize.width / 2,
            y: center.y - newSize.height / 2,
            width: newSize.width,
            height: newSize.height
        )
        // Clamp to the screen the window is actually on so a big size swing
        // (e.g. pill's 68pt height to vinyl/CD's 300pt) can't push any edge
        // past the visible screen bounds.
        if let visible = (window.screen ?? NSScreen.main)?.visibleFrame {
            newFrame.origin.x = min(max(newFrame.origin.x, visible.minX), visible.maxX - newFrame.width)
            newFrame.origin.y = min(max(newFrame.origin.y, visible.minY), visible.maxY - newFrame.height)
        }
        // Matches the SwiftUI content's transition duration/easing (see
        // RootView) so the frame and the widget inside it move as one.
        NSAnimationContext.runAnimationGroup { context in
            context.duration = WidgetSkin.transitionDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(newFrame, display: true)
        }
    }

    /// A skin's window size, substituting the user's last hand-dragged
    /// width for the pill (height never changes — see `isWidthResizable`).
    private func size(for skin: WidgetSkin) -> NSSize {
        guard skin.isWidthResizable else { return skin.windowSize }
        return NSSize(width: skinStore.pillWidth, height: skin.windowSize.height)
    }

    /// `minSize`/`maxSize` sharing one height is what pins the height while
    /// leaving width free — AppKit clamps any drag's height component to
    /// that single value no matter which edge/corner the user grabs, so no
    /// `windowWillResize` override is needed.
    private func configureResizability(of window: NSWindow, for skin: WidgetSkin) {
        guard skin.isWidthResizable else {
            window.styleMask.remove(.resizable)
            return
        }
        window.styleMask.insert(.resizable)
        let height = skin.windowSize.height
        window.minSize = NSSize(width: WidgetSkin.pillMinWidth, height: height)
        window.maxSize = NSSize(width: WidgetSkin.pillMaxWidth, height: height)
    }

    /// Clips the window's content to each skin's card shape, so system-drawn
    /// chrome (e.g. the glass material's key-window highlight) can't bleed
    /// past the rounded corners onto the window's true rectangular edge.
    private func applyCornerMask(to contentView: NSView, for skin: WidgetSkin) {
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = skin.cornerRadius
        contentView.layer?.masksToBounds = skin.cornerRadius > 0
    }
}

extension AppDelegate: NSWindowDelegate {
    /// Fires only for a user-driven drag (not the programmatic `setFrame`
    /// animation in `resizeWindow`), so this is where — and only where —
    /// the chosen width gets remembered for next launch/skin switch.
    func windowDidEndLiveResize(_ notification: Notification) {
        guard let window, skinStore.skin.isWidthResizable else { return }
        skinStore.pillWidth = window.frame.width
    }

    /// Remembers the widget's on-screen position for next launch. Fires for
    /// both a user drag and the programmatic skin-switch animation in
    /// `resizeWindow`, which is fine — either way it's where the window
    /// actually ended up. Guarding on `self.window` (unset until the initial
    /// placement in `applicationDidFinishLaunching` completes) keeps that
    /// startup placement from immediately overwriting itself.
    func windowDidMove(_ notification: Notification) {
        guard let window else { return }
        skinStore.windowOrigin = window.frame.origin
    }
}

/// `swift run Miniplayer --print-queue` — calls the same `SpotifyController.queue()`
/// the widget uses, prints it as plain JSON, and exits. No window, no GUI event
/// loop, so it's safe to script/pipe and won't leave a floating widget behind.
if CommandLine.arguments.contains("--print-queue") {
    struct QueueTrackJSON: Encodable { let name: String; let artist: String }

    let semaphore = DispatchSemaphore(value: 0)
    Task {
        defer { semaphore.signal() }
        guard SpotifyController.isRunning() else {
            FileHandle.standardError.write(Data("Spotify isn't running.\n".utf8))
            return
        }
        guard SpotifyController.supportsQueue else {
            FileHandle.standardError.write(Data("Not connected — run the app normally and use \"Connect Spotify Account\" first.\n".utf8))
            return
        }
        switch await SpotifyController.queue(matching: SpotifyController.currentTrack()) {
        case .otherDeviceActive:
            FileHandle.standardError.write(Data("Suppressed: Spotify's active device isn't this Mac.\n".utf8))
            print("[]")
        case .tracks(let queue):
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            let json = (try? encoder.encode(queue.map { QueueTrackJSON(name: $0.name, artist: $0.artist) }))
                .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
            print(json)
        }
    }
    semaphore.wait()
    exit(0)
}

#if DEBUG
// Lets the XCUITest smoke suite (Tests/MiniplayerUITests) drive the real
// UI against deterministic fake playback data instead of a live Spotify/
// Music session. Only reachable in debug builds — release/dist builds
// never check this env var.
if ProcessInfo.processInfo.environment["MINIPLAYER_UI_TEST"] == "1" {
    PlayerViewModel.useControllers([FakeMediaAppController.self])
}
#endif

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
