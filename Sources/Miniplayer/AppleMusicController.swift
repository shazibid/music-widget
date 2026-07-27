import AppKit
import Foundation

enum AppleMusicController: MediaAppController {
    /// Music.app's `current playlist` exposes real track indices, so the
    /// tracks after `current track` can stand in for "up next" — unlike
    /// Spotify, which has no such access at all.
    static let supportsQueue = true

    static func isRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.apple.Music" }
    }

    static func currentTrack() -> Track? {
        guard isRunning() else { return nil }
        let script = """
        tell application "Music"
            if player state is stopped then return ""
            return (name of current track) & "\u{241F}" & (artist of current track) & "\u{241F}" & (album of current track) & "\u{241F}" & (duration of current track)
        end tell
        """
        guard let fields = parseTrackFields(runAppleScript(script)) else { return nil }
        let artwork = fetchArtwork().map(ArtworkSource.data)
        return Track(name: fields.name, artist: fields.artist, album: fields.album, artwork: artwork, duration: fields.duration)
    }

    /// Splits the `\u{241F}`-delimited AppleScript result into the plain
    /// text fields (artwork is fetched separately — see `fetchArtwork`).
    /// Pure and testable without `NSAppleScript` or a running Music.app.
    static func parseTrackFields(_ raw: String?) -> (name: String, artist: String, album: String, duration: TimeInterval)? {
        guard let raw, !raw.isEmpty else { return nil }
        let parts = raw.components(separatedBy: "\u{241F}")
        guard parts.count == 4 else { return nil }
        // Music reports `duration of current track` in seconds already.
        let duration = Double(parts[3]) ?? 0
        return (parts[0], parts[1], parts[2], duration)
    }

    static func playerState() -> PlayerState {
        guard isRunning(), let result = runAppleScript(#"tell application "Music" to player state as string"#) else {
            return .stopped
        }
        return PlayerState(rawValue: result) ?? .stopped
    }

    static func playbackPosition() -> TimeInterval {
        guard isRunning(), let result = runAppleScript(#"tell application "Music" to player position as string"#) else {
            return 0
        }
        return Double(result) ?? 0
    }

    static func playPause() {
        runAppleScript(#"tell application "Music" to playpause"#)
    }

    static func next() {
        runAppleScript(#"tell application "Music" to next track"#)
    }

    static func previous() {
        runAppleScript(#"tell application "Music" to previous track"#)
    }

    /// Walks forward from `current track`'s index within `current playlist`.
    /// Capped at 15 tracks so AppleScript doesn't have to resolve every
    /// remaining track in a long playlist. Radio/algorithmic playback has no
    /// indexable "current playlist", so that case (and any other scripting
    /// error) just yields an empty queue via the try block.
    static func queue(matching localTrack: Track?) -> QueueFetchResult {
        guard isRunning() else { return .tracks([]) }
        let script = """
        tell application "Music"
            if player state is stopped then return ""
            try
                set cp to current playlist
                set idx to index of current track
                set total to count of tracks of cp
                set upperBound to idx + 15
                if upperBound > total then set upperBound to total
                set upcoming to {}
                repeat with i from (idx + 1) to upperBound
                    set t to track i of cp
                    set end of upcoming to ((name of t) & "\u{241E}" & (artist of t))
                end repeat
                set AppleScript's text item delimiters to "\u{241F}"
                set resultText to upcoming as text
                set AppleScript's text item delimiters to ""
                return resultText
            on error
                return ""
            end try
        end tell
        """
        return .tracks(parseQueueItems(runAppleScript(script)))
    }

    /// Splits the `\u{241F}`/`\u{241E}`-delimited AppleScript queue result
    /// into `QueueTrack`s. Pure and testable without `NSAppleScript` or a
    /// running Music.app.
    static func parseQueueItems(_ raw: String?) -> [QueueTrack] {
        guard let raw, !raw.isEmpty else { return [] }
        return raw.components(separatedBy: "\u{241F}").compactMap { item in
            let parts = item.components(separatedBy: "\u{241E}")
            guard parts.count == 2 else { return nil }
            return QueueTrack(name: parts[0], artist: parts[1])
        }
    }

    /// Unlike Spotify, Music has no artwork URL — the artwork only exists as
    /// raw image bytes on the current track, so it's fetched separately.
    private static func fetchArtwork() -> Data? {
        let script = """
        tell application "Music"
            if (count of artworks of current track) is 0 then return
            return data of artwork 1 of current track
        end tell
        """
        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        let output = appleScript.executeAndReturnError(&error)
        guard error == nil, !output.data.isEmpty else { return nil }
        return output.data
    }
}
