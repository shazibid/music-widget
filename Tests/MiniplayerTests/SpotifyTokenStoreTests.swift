import XCTest
@testable import Miniplayer

final class SpotifyTokenStoreTests: XCTestCase {
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        SpotifyTokenStore.directoryOverride = tempDir
    }

    override func tearDown() {
        SpotifyTokenStore.clear()
        try? FileManager.default.removeItem(at: tempDir)
        SpotifyTokenStore.directoryOverride = nil
        tempDir = nil
        super.tearDown()
    }

    func testHasRefreshTokenIsFalseInitially() {
        XCTAssertFalse(SpotifyTokenStore.hasRefreshToken())
    }

    func testSaveThenLoadRoundTrips() {
        SpotifyTokenStore.save(refreshToken: "the-refresh-token")
        XCTAssertEqual(SpotifyTokenStore.loadRefreshToken(), "the-refresh-token")
    }

    func testSaveSetsHasRefreshTokenTrue() {
        SpotifyTokenStore.save(refreshToken: "the-refresh-token")
        XCTAssertTrue(SpotifyTokenStore.hasRefreshToken())
    }

    func testClearRemovesToken() {
        SpotifyTokenStore.save(refreshToken: "the-refresh-token")
        SpotifyTokenStore.clear()

        XCTAssertFalse(SpotifyTokenStore.hasRefreshToken())
        XCTAssertNil(SpotifyTokenStore.loadRefreshToken())
    }

    func testLoadRefreshTokenIsNilWhenNeverSaved() {
        XCTAssertNil(SpotifyTokenStore.loadRefreshToken())
    }

    func testSaveOverwritesPreviousToken() {
        SpotifyTokenStore.save(refreshToken: "first-token")
        SpotifyTokenStore.save(refreshToken: "second-token")
        XCTAssertEqual(SpotifyTokenStore.loadRefreshToken(), "second-token")
    }
}
