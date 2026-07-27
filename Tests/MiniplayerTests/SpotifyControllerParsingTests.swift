import XCTest
@testable import Miniplayer

final class SpotifyControllerParsingTests: XCTestCase {
    private let unitSeparator = "\u{241F}"

    func testParsesWellFormedTrack() {
        let raw = ["Song Title", "Some Artist", "Some Album", "https://example.com/art.jpg", "245000"]
            .joined(separator: unitSeparator)

        let track = SpotifyController.parseTrackFields(raw)

        XCTAssertEqual(track?.name, "Song Title")
        XCTAssertEqual(track?.artist, "Some Artist")
        XCTAssertEqual(track?.album, "Some Album")
        XCTAssertEqual(track?.artwork, .url("https://example.com/art.jpg"))
        // Spotify reports duration in milliseconds; parseTrackFields converts to seconds.
        XCTAssertEqual(track?.duration, 245)
    }

    func testReturnsNilForNilInput() {
        XCTAssertNil(SpotifyController.parseTrackFields(nil))
    }

    func testReturnsNilForEmptyString() {
        XCTAssertNil(SpotifyController.parseTrackFields(""))
    }

    func testReturnsNilForWrongFieldCount() {
        let raw = ["Song Title", "Some Artist"].joined(separator: unitSeparator)
        XCTAssertNil(SpotifyController.parseTrackFields(raw))
    }

    func testMissingDurationFallsBackToZero() {
        let raw = ["Song Title", "Some Artist", "Some Album", "https://example.com/art.jpg", "not-a-number"]
            .joined(separator: unitSeparator)

        XCTAssertEqual(SpotifyController.parseTrackFields(raw)?.duration, 0)
    }
}
