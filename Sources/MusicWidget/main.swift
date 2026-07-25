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
        let hosting = ClickableHostingView(rootView: RootView(viewModel: viewModel, skinStore: skinStore))

        let initialSize = skinStore.skin.windowSize
        let window = FloatingWidgetWindow(
            contentRect: NSRect(x: 0, y: 0, width: initialSize.width, height: initialSize.height),
            styleMask: [.borderless, .fullSizeContentView],
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

        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let origin = NSPoint(x: visible.maxX - 20 - initialSize.width, y: visible.maxY - 20 - initialSize.height)
            window.setFrameOrigin(origin)
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

    private func resizeWindow(for skin: WidgetSkin) {
        guard let window else { return }
        let newSize = skin.windowSize
        let topRight = NSPoint(x: window.frame.maxX, y: window.frame.maxY)
        let newFrame = NSRect(
            x: topRight.x - newSize.width,
            y: topRight.y - newSize.height,
            width: newSize.width,
            height: newSize.height
        )
        // Matches the SwiftUI content's transition duration/easing (see
        // RootView) so the frame and the widget inside it move as one.
        NSAnimationContext.runAnimationGroup { context in
            context.duration = WidgetSkin.transitionDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(newFrame, display: true)
        }
    }
}

/// `swift run MusicWidget --print-queue` — calls the same `SpotifyController.queue()`
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

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
