import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private let viewModel = PlayerViewModel()
    private let skinStore = SkinStore()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let hosting = NSHostingView(rootView: RootView(viewModel: viewModel, skinStore: skinStore))

        let initialSize = skinStore.skin.windowSize
        let window = NSWindow(
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
        window.setFrame(newFrame, display: true, animate: true)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
