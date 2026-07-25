import Foundation

/// Spotify hands back an artwork URL directly; Music only exposes raw
/// artwork bytes through AppleScript, so callers need to handle either.
enum ArtworkSource: Equatable {
    case url(String)
    case data(Data)
}

struct Track: Equatable {
    let name: String
    let artist: String
    let album: String
    let artwork: ArtworkSource?
}

struct QueueTrack: Equatable, Identifiable {
    let id = UUID()
    let name: String
    let artist: String
}

enum PlayerState: String {
    case playing
    case paused
    case stopped
}

/// Common shape for scripting a media app (Spotify, Music, ...) so
/// `PlayerViewModel` can poll all of them and act on whichever is active
/// without app-specific branching.
protocol MediaAppController {
    /// Whether this app's scripting interface can enumerate upcoming tracks
    /// at all — Spotify's AppleScript dictionary has no queue/playlist
    /// concept, only the single current track, so it reports `false`.
    static var supportsQueue: Bool { get }

    static func isRunning() -> Bool
    static func currentTrack() -> Track?
    static func playerState() -> PlayerState
    static func playPause()
    static func next()
    static func previous()
    static func queue() -> [QueueTrack]
}
