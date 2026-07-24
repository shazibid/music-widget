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
        isSpotifyRunning = SpotifyController.isRunning()
        state = SpotifyController.playerState()
        track = SpotifyController.currentTrack()
        position = SpotifyController.playerPosition()
        loadArtworkIfNeeded()
    }

    func togglePlayPause() {
        SpotifyController.playPause()
        refresh()
    }

    func skipNext() {
        SpotifyController.next()
        refresh()
    }

    func skipPrevious() {
        SpotifyController.previous()
        refresh()
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
