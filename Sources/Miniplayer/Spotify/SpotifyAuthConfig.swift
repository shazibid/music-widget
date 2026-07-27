import Foundation

/// Spotify Web API app registered at developer.spotify.com. The client ID
/// isn't secret (PKCE needs no client secret), but the redirect URI must
/// match exactly — including the port — what's registered on the dashboard.
enum SpotifyAuthConfig {
    static let clientID = "e96b547b336f4049ab66104312ee4985"
    static let redirectPort: UInt16 = 8888
    static let redirectURI = "http://127.0.0.1:8888/callback"
    static let scopes = "user-read-currently-playing user-read-playback-state"
}
