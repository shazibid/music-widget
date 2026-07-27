import Foundation

/// Thin wrapper around the one Web API call this app needs. Spotify's
/// AppleScript dictionary has no queue concept (see `SpotifyController`), so
/// this is the only way to read what's coming up next.
enum SpotifyWebAPI {
    /// `localTrack` is what this Mac's own Spotify client reports playing
    /// (via AppleScript). The Web API's queue belongs to whichever device is
    /// the account's currently-*active* Spotify Connect device, which isn't
    /// necessarily this one — e.g. music is playing on the Mac but the phone
    /// was the last device to touch playback controls. When `currently_playing`
    /// in the response disagrees with `localTrack`, the queue we'd get back
    /// belongs to that other device's session, so it's suppressed rather than
    /// shown as if it were this Mac's.
    static func fetchQueue(matching localTrack: Track?) async throws -> QueueFetchResult {
        let token = try await SpotifyAuthManager.shared.validAccessToken()

        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player/queue")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // Playback state changes every second; never let URLSession's shared
        // HTTP cache serve back an old snapshot for this identical URL.
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(QueueResponse.self, from: data)
        guard matches(decoded.currentlyPlaying, localTrack) else {
            print("Spotify queue suppressed: active device isn't this Mac (API says \"\(decoded.currentlyPlaying?.name ?? "nothing")\", this Mac has \"\(localTrack?.name ?? "nothing")\")")
            return .otherDeviceActive
        }
        return .tracks(decoded.queue.map { QueueTrack(name: $0.name, artist: $0.artists?.first?.name ?? "") })
    }

    /// Internal (not `private`) so `@testable import` can exercise the
    /// active-device-matching logic directly, without a live network call.
    static func matches(_ item: Item?, _ track: Track?) -> Bool {
        guard let track else { return true }
        guard let item else { return false }
        return item.name == track.name && (item.artists?.first?.name ?? "") == track.artist
    }

    struct QueueResponse: Decodable {
        let queue: [Item]
        let currentlyPlaying: Item?

        enum CodingKeys: String, CodingKey {
            case queue
            case currentlyPlaying = "currently_playing"
        }
    }

    /// `artists` is optional because the queue can also hold podcast
    /// episodes, which use a `show` object instead — those just surface with
    /// a blank artist rather than failing the whole decode.
    struct Item: Decodable {
        let name: String
        let artists: [Artist]?

        struct Artist: Decodable { let name: String }
    }
}
