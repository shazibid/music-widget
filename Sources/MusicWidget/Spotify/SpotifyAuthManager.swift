import AppKit
import CryptoKit
import Foundation

/// Owns the Spotify OAuth (Authorization Code + PKCE) lifecycle: kicking off
/// the browser login, exchanging/refreshing tokens, and handing out a live
/// access token to `SpotifyWebAPI`.
actor SpotifyAuthManager {
    static let shared = SpotifyAuthManager()

    enum AuthError: Error {
        case userDenied
        case stateMismatch
        case missingCode
        case tokenRequestFailed
        case notAuthenticated
    }

    private var accessToken: String?
    private var accessTokenExpiry: Date?

    /// Opens the system browser for the user to approve access, then waits
    /// on the loopback listener for Spotify's redirect to complete the PKCE
    /// exchange. Throws if the user denies access or the exchange fails.
    func login() async throws {
        let verifier = Self.randomURLSafeString(length: 64)
        let challenge = Self.codeChallenge(for: verifier)
        let state = Self.randomURLSafeString(length: 16)

        var authorize = URLComponents(string: "https://accounts.spotify.com/authorize")!
        authorize.queryItems = [
            URLQueryItem(name: "client_id", value: SpotifyAuthConfig.clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: SpotifyAuthConfig.redirectURI),
            URLQueryItem(name: "scope", value: SpotifyAuthConfig.scopes),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "state", value: state)
        ]

        async let redirect = LoopbackCallbackServer.waitForCallback(port: SpotifyAuthConfig.redirectPort)
        await MainActor.run { NSWorkspace.shared.open(authorize.url!) }

        let components = try await redirect
        let query = components.queryItems ?? []
        if query.first(where: { $0.name == "error" }) != nil {
            throw AuthError.userDenied
        }
        guard query.first(where: { $0.name == "state" })?.value == state else {
            throw AuthError.stateMismatch
        }
        guard let code = query.first(where: { $0.name == "code" })?.value else {
            throw AuthError.missingCode
        }

        try await exchange(code: code, verifier: verifier)
    }

    func logout() {
        accessToken = nil
        accessTokenExpiry = nil
        SpotifyTokenStore.clear()
    }

    /// Returns a live access token, refreshing via the stored refresh token
    /// whenever the cached one is missing or about to expire.
    func validAccessToken() async throws -> String {
        if let accessToken, let accessTokenExpiry, accessTokenExpiry > Date() {
            return accessToken
        }
        guard let refreshToken = SpotifyTokenStore.loadRefreshToken() else {
            throw AuthError.notAuthenticated
        }
        try await refresh(using: refreshToken)
        guard let accessToken else { throw AuthError.notAuthenticated }
        return accessToken
    }

    private func exchange(code: String, verifier: String) async throws {
        let decoded = try await requestToken(body: [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": SpotifyAuthConfig.redirectURI,
            "client_id": SpotifyAuthConfig.clientID,
            "code_verifier": verifier
        ])
        if let newRefreshToken = decoded.refreshToken {
            SpotifyTokenStore.save(refreshToken: newRefreshToken)
        }
    }

    private func refresh(using refreshToken: String) async throws {
        let decoded = try await requestToken(body: [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": SpotifyAuthConfig.clientID
        ])
        // Spotify usually rotates the refresh token on every use, but not
        // always — only write to Keychain (and re-trigger its access
        // prompt) when the value actually changed.
        if let newRefreshToken = decoded.refreshToken, newRefreshToken != refreshToken {
            SpotifyTokenStore.save(refreshToken: newRefreshToken)
        }
    }

    @discardableResult
    private func requestToken(body: [String: String]) async throws -> TokenResponse {
        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.formEncode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AuthError.tokenRequestFailed
        }
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        accessToken = decoded.accessToken
        // Refresh a minute early so a fetch started right at the boundary
        // doesn't race the token's actual expiry.
        accessTokenExpiry = Date().addingTimeInterval(TimeInterval(decoded.expiresIn - 60))
        return decoded
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let expiresIn: Int
        let refreshToken: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn = "expires_in"
            case refreshToken = "refresh_token"
        }
    }

    private static func randomURLSafeString(length: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    private static func codeChallenge(for verifier: String) -> String {
        Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncodedString()
    }

    private static func formEncode(_ params: [String: String]) -> Data {
        params.map { key, value in
            let encoded = value.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? value
            return "\(key)=\(encoded)"
        }.joined(separator: "&").data(using: .utf8)!
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-._~")
        return set
    }()
}
