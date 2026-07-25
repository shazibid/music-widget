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
    let duration: Double
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
    static func isRunning() -> Bool
    static func currentTrack() -> Track?
    static func playerState() -> PlayerState
    static func playerPosition() -> Double
    static func playPause()
    static func next()
    static func previous()
}
