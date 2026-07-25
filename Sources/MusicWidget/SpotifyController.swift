import AppKit
import Foundation

enum SpotifyController: MediaAppController {
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
        guard let result = runAppleScript(script), !result.isEmpty else { return nil }
        let parts = result.components(separatedBy: "\u{241F}")
        guard parts.count == 5, let durationMs = Double(parts[4]) else { return nil }
        return Track(name: parts[0], artist: parts[1], album: parts[2], artwork: .url(parts[3]), duration: durationMs / 1000)
    }

    static func playerState() -> PlayerState {
        guard isRunning(), let result = runAppleScript(#"tell application "Spotify" to player state as string"#) else {
            return .stopped
        }
        return PlayerState(rawValue: result) ?? .stopped
    }

    static func playerPosition() -> Double {
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
