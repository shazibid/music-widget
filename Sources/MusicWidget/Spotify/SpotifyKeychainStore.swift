import Foundation
import Security

/// Stores only the refresh token — the access token is short-lived and kept
/// in memory by `SpotifyAuthManager`, so there's nothing else worth
/// persisting across launches.
enum SpotifyKeychainStore {
    private static let service = "com.musicwidget.spotify"
    private static let account = "refresh-token"

    static func save(refreshToken: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = Data(refreshToken.utf8)
        SecItemAdd(attributes as CFDictionary, nil)
        TokenPresenceCache.set(true)
    }

    /// Existence-only check (no `kSecReturnData`) so it doesn't touch the
    /// protected secret and doesn't trigger a Keychain authorization prompt —
    /// safe to call from UI polling. Use `loadRefreshToken()` when the actual
    /// token value is needed.
    static func hasRefreshToken() -> Bool {
        if let cached = TokenPresenceCache.get() { return cached }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        let has = SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
        TokenPresenceCache.set(has)
        return has
    }

    static func loadRefreshToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        TokenPresenceCache.set(false)
    }
}

/// Caches the existence check above so polling code (`supportsQueue`,
/// `isSpotifyConnected`) doesn't hit Keychain on every timer tick. Backed by
/// a lock since it's read from the main actor (UI polling) and written from
/// `SpotifyAuthManager`'s actor (login/refresh).
private enum TokenPresenceCache {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var value: Bool?

    static func get() -> Bool? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    static func set(_ newValue: Bool) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}
