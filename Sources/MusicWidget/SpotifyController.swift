import AppKit
import Foundation

enum SpotifyController: MediaAppController {
    /// Spotify's scripting dictionary exposes only `current track` — no
    /// queue or playlist enumeration — so upcoming tracks can only come from
    /// the Web API, and only once the user has connected their account.
    static var supportsQueue: Bool { SpotifyTokenStore.hasRefreshToken() }

    static func isRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.spotify.client" }
    }

    static func currentTrack() -> Track? {
        guard isRunning() else { return nil }
        let script = """
        tell application "Spotify"
            if player state is stopped then return ""
            return (name of current track) & "\u{241F}" & (artist of current track) & "\u{241F}" & (album of current track) & "\u{241F}" & (artwork url of current track) & "\u{241F}" & (duration of current track)
        end tell
        """
        return parseTrackFields(runAppleScript(script))
    }

    /// Splits the `\u{241F}`-delimited AppleScript result into a `Track`.
    /// Pure and testable without `NSAppleScript` or a running Spotify.
    static func parseTrackFields(_ raw: String?) -> Track? {
        guard let raw, !raw.isEmpty else { return nil }
        let parts = raw.components(separatedBy: "\u{241F}")
        guard parts.count == 5 else { return nil }
        // Unlike Music, Spotify reports `duration of current track` in milliseconds.
        let duration = (Double(parts[4]) ?? 0) / 1000
        return Track(name: parts[0], artist: parts[1], album: parts[2], artwork: .url(parts[3]), duration: duration)
    }

    static func playerState() -> PlayerState {
        guard isRunning(), let result = runAppleScript(#"tell application "Spotify" to player state as string"#) else {
            return .stopped
        }
        return PlayerState(rawValue: result) ?? .stopped
    }

    static func playbackPosition() -> TimeInterval {
        guard isRunning(), let result = runAppleScript(#"tell application "Spotify" to player position as string"#) else {
            return 0
        }
        return Double(result) ?? 0
    }

    static func playPause() {
        runAppleScript(#"tell application "Spotify" to playpause"#)
    }

    static func next() {
        runAppleScript(#"tell application "Spotify" to next track"#)
    }

    static func previous() {
        runAppleScript(#"tell application "Spotify" to previous track"#)
    }

    static func queue(matching localTrack: Track?) async -> QueueFetchResult {
        guard isRunning() else { return .tracks([]) }
        do {
            return try await SpotifyWebAPI.fetchQueue(matching: localTrack)
        } catch {
            print("Spotify fetchQueue failed: \(error)")
            return .tracks([])
        }
    }
}
