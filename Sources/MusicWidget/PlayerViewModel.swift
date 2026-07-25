import AppKit
import Combine
import Foundation

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published private(set) var track: Track?
    @Published private(set) var state: PlayerState = .stopped
    @Published private(set) var artworkImage: NSImage?
    @Published private(set) var isSourceRunning = false
    @Published private(set) var queue: [QueueTrack] = []
    @Published private(set) var isLoadingQueue = false

    /// Whether the active app's scripting interface can enumerate upcoming
    /// tracks at all (false for Spotify — see `MediaAppController.supportsQueue`).
    var queueSupported: Bool { activeController?.supportsQueue ?? false }

    private nonisolated static let controllers: [MediaAppController.Type] = [SpotifyController.self, AppleMusicController.self]

    private var timer: Timer?
    private var activeController: MediaAppController.Type?
    private var lastArtworkKey: String?

    func startPolling() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.refresh() }
        }
    }

    func refresh() {
        Task.detached(priority: .userInitiated) { [weak self] in
            let snapshot = Self.poll()
            await self?.apply(snapshot)
        }
    }

    /// Flips instantly so the button and the disc's spin animation update in
    /// the same frame, instead of waiting on the AppleScript round-trip.
    func togglePlayPause() {
        state = (state == .playing) ? .paused : .playing
        guard let controller = activeController else { return }
        Task.detached(priority: .userInitiated) { [weak self] in
            controller.playPause()
            let snapshot = Self.poll()
            await self?.apply(snapshot)
        }
    }

    func skipNext() {
        guard let controller = activeController else { return }
        Task.detached(priority: .userInitiated) { [weak self] in
            controller.next()
            let snapshot = Self.poll()
            await self?.apply(snapshot)
        }
    }

    func skipPrevious() {
        guard let controller = activeController else { return }
        Task.detached(priority: .userInitiated) { [weak self] in
            controller.previous()
            let snapshot = Self.poll()
            await self?.apply(snapshot)
        }
    }

    /// Fetched on demand (when the Menu screen opens) rather than on every
    /// poll tick, since it's an extra AppleScript round-trip nothing else needs.
    func fetchQueue() {
        guard let controller = activeController, controller.supportsQueue else {
            queue = []
            return
        }
        isLoadingQueue = true
        Task.detached(priority: .userInitiated) { [weak self] in
            let result = controller.queue()
            await MainActor.run {
                self?.queue = result
                self?.isLoadingQueue = false
            }
        }
    }

    /// Prefers whichever app is actively playing; if both are just open and
    /// paused, falls back to the first one (in `controllers` order). Nothing
    /// running means nothing to show.
    private nonisolated static func poll() -> (controller: MediaAppController.Type?, state: PlayerState, track: Track?) {
        let running = controllers.filter { $0.isRunning() }
        guard !running.isEmpty else { return (nil, .stopped, nil) }
        let states = running.map { (app: $0, state: $0.playerState()) }
        let chosen = states.first(where: { $0.state == .playing }) ?? states[0]
        return (chosen.app, chosen.state, chosen.app.currentTrack())
    }

    private func apply(_ snapshot: (controller: MediaAppController.Type?, state: PlayerState, track: Track?)) {
        isSourceRunning = snapshot.controller != nil
        if activeController != nil, snapshot.controller == nil {
            queue = []
        }
        activeController = snapshot.controller
        state = snapshot.state
        track = snapshot.track
        loadArtworkIfNeeded()
    }

    private func loadArtworkIfNeeded() {
        guard let track else {
            artworkImage = nil
            lastArtworkKey = nil
            return
        }
        let key = "\(track.name)|\(track.artist)|\(track.album)"
        guard key != lastArtworkKey else { return }
        lastArtworkKey = key

        switch track.artwork {
        case .url(let urlString):
            guard let url = URL(string: urlString) else { artworkImage = nil; return }
            Task {
                guard let (data, _) = try? await URLSession.shared.data(from: url), let image = NSImage(data: data) else { return }
                await MainActor.run { self.artworkImage = image }
            }
        case .data(let data):
            artworkImage = NSImage(data: data)
        case nil:
            artworkImage = nil
        }
    }
}
