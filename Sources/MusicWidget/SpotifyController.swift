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
            return (name of current track) & "\u{241F}" & (artist of current track) & "\u{241F}" & (album of current track) & "\u{241F}" & (artwork url of current track)
        end tell
        """
        guard let result = runAppleScript(script), !result.isEmpty else { return nil }
        let parts = result.components(separatedBy: "\u{241F}")
        guard parts.count == 4 else { return nil }
        return Track(name: parts[0], artist: parts[1], album: parts[2], artwork: .url(parts[3]))
    }

    static func playerState() -> PlayerState {
        guard isRunning(), let result = runAppleScript(#"tell application "Spotify" to player state as string"#) else {
            return .stopped
        }
        return PlayerState(rawValue: result) ?? .stopped
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

    @discardableResult
    private static func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let output = script.executeAndReturnError(&error)
        if let error {
            print("AppleScript error: \(error)")
            return nil
        }
        return output.stringValue
    }
}
