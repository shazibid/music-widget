import Foundation

/// Stores only the refresh token — the access token is short-lived and kept
/// in memory by `SpotifyAuthManager`, so there's nothing else worth
/// persisting across launches. Kept as a plain permissions-locked file
/// rather than the system Keychain: Keychain's access check is gated on the
/// app's code signature, and SwiftPM ad-hoc-signs debug builds with a new
/// identity on every rebuild, which would reprompt for the login password
/// on every `swift build` — untenable for a repo other people clone and
/// build themselves.
enum SpotifyTokenStore {
    private static let fileURL: URL = {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MusicWidget", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: supportDir,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        return supportDir.appendingPathComponent("spotify-refresh-token")
    }()

    static func save(refreshToken: String) {
        FileManager.default.createFile(
            atPath: fileURL.path,
            contents: Data(refreshToken.utf8),
            attributes: [.posixPermissions: 0o600]
        )
        TokenPresenceCache.set(true)
    }

    /// Cheap existence check safe to call from UI polling — the cache below
    /// means it usually doesn't even touch disk.
    static func hasRefreshToken() -> Bool {
        if let cached = TokenPresenceCache.get() { return cached }
        let has = FileManager.default.fileExists(atPath: fileURL.path)
        TokenPresenceCache.set(has)
        return has
    }

    static func loadRefreshToken() -> String? {
        guard let data = FileManager.default.contents(atPath: fileURL.path) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
        TokenPresenceCache.set(false)
    }
}

/// Caches the existence check above so polling code (`supportsQueue`,
/// `isSpotifyConnected`) doesn't hit disk on every timer tick. Backed by a
/// lock since it's read from the main actor (UI polling) and written from
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
