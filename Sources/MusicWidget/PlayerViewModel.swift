import AppKit
import Combine
import Foundation

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published private(set) var track: SpotifyTrack?
    @Published private(set) var state: SpotifyPlayerState = .stopped
    @Published private(set) var position: Double = 0
    @Published private(set) var artworkImage: NSImage?
    @Published private(set) var isSpotifyRunning = false

    private var timer: Timer?
    private var lastArtworkURL: String?

    func startPolling() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.refresh() }
        }
    }

    func refresh() {
        Task.detached(priority: .userInitiated) { [weak self] in
            let running = SpotifyController.isRunning()
            let state = running ? SpotifyController.playerState() : .stopped
            let track = running ? SpotifyController.currentTrack() : nil
            let position = running ? SpotifyController.playerPosition() : 0
            await self?.apply(running: running, state: state, track: track, position: position)
        }
    }

    /// Flips instantly so the button and the CD's spin animation update in
    /// the same frame, instead of waiting on Spotify's AppleScript round-trip.
    func togglePlayPause() {
        state = (state == .playing) ? .paused : .playing
        Task.detached(priority: .userInitiated) { [weak self] in
            SpotifyController.playPause()
            await self?.refreshFromBackground()
        }
    }

    func skipNext() {
        Task.detached(priority: .userInitiated) { [weak self] in
            SpotifyController.next()
            await self?.refreshFromBackground()
        }
    }

    func skipPrevious() {
        Task.detached(priority: .userInitiated) { [weak self] in
            SpotifyController.previous()
            await self?.refreshFromBackground()
        }
    }

    private nonisolated func refreshFromBackground() async {
        let running = SpotifyController.isRunning()
        let state = running ? SpotifyController.playerState() : .stopped
        let track = running ? SpotifyController.currentTrack() : nil
        let position = running ? SpotifyController.playerPosition() : 0
        await apply(running: running, state: state, track: track, position: position)
    }

    private func apply(running: Bool, state: SpotifyPlayerState, track: SpotifyTrack?, position: Double) {
        isSpotifyRunning = running
        self.state = state
        self.track = track
        self.position = position
        loadArtworkIfNeeded()
    }

    private func loadArtworkIfNeeded() {
        guard let urlString = track?.artworkURL, urlString != lastArtworkURL, let url = URL(string: urlString) else {
            if track == nil { artworkImage = nil; lastArtworkURL = nil }
            return
        }
        lastArtworkURL = urlString
        Task {
            guard let (data, _) = try? await URLSession.shared.data(from: url), let image = NSImage(data: data) else { return }
            await MainActor.run { self.artworkImage = image }
        }
    }
}
