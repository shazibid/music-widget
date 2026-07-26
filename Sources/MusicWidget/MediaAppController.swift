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
    let duration: TimeInterval
}

struct QueueTrack: Equatable, Identifiable {
    let id = UUID()
    let name: String
    let artist: String
}

/// `.otherDeviceActive` is distinct from `.tracks([])` — the former means
/// "there may well be a queue, but it belongs to a different device's
/// session and can't be trusted," the latter means "genuinely nothing
/// upcoming." Only Spotify (a cross-device Web API) can hit the first case;
/// Apple Music's local AppleScript queue always resolves to `.tracks`.
enum QueueFetchResult {
    case tracks([QueueTrack])
    case otherDeviceActive
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
    /// Whether upcoming tracks can be enumerated right now. Apple Music
    /// always can (via MusicKit); Spotify only once the user has connected
    /// their account through the Web API, since its AppleScript dictionary
    /// has no queue/playlist concept of its own.
    static var supportsQueue: Bool { get }

    static func isRunning() -> Bool
    static func currentTrack() -> Track?
    static func playerState() -> PlayerState
    /// Elapsed seconds into the current track. Polled alongside `currentTrack()`
    /// to drive the pill's progress bar.
    static func playbackPosition() -> TimeInterval
    static func playPause()
    static func next()
    static func previous()
    /// `localTrack` is the currently-playing track as this controller itself
    /// reports it (from `currentTrack()`), passed in so an implementation
    /// backed by a cross-device API (Spotify) can tell whether the data it
    /// got back actually belongs to this machine's session.
    /// Async because Spotify's implementation is a real network round-trip
    /// to the Web API; Apple Music's stays a synchronous AppleScript call.
    static func queue(matching localTrack: Track?) async -> QueueFetchResult
}
