import XCTest
@testable import Miniplayer

final class SpotifyWebAPITests: XCTestCase {
    private let track = Track(name: "Song Title", artist: "Some Artist", album: "Some Album", artwork: nil, duration: 200)

    // MARK: - matches

    func testMatchesTrueWhenNameAndArtistAgree() {
        let item = SpotifyWebAPI.Item(name: "Song Title", artists: [.init(name: "Some Artist")])
        XCTAssertTrue(SpotifyWebAPI.matches(item, track))
    }

    func testMatchesFalseWhenNameDiffers() {
        let item = SpotifyWebAPI.Item(name: "Different Song", artists: [.init(name: "Some Artist")])
        XCTAssertFalse(SpotifyWebAPI.matches(item, track))
    }

    func testMatchesFalseWhenArtistDiffers() {
        let item = SpotifyWebAPI.Item(name: "Song Title", artists: [.init(name: "Different Artist")])
        XCTAssertFalse(SpotifyWebAPI.matches(item, track))
    }

    func testMatchesFalseWhenItemIsNilButLocalTrackExists() {
        XCTAssertFalse(SpotifyWebAPI.matches(nil, track))
    }

    func testMatchesTrueWhenLocalTrackIsNilRegardlessOfItem() {
        // No local track to compare against means there's nothing to disagree with.
        let item = SpotifyWebAPI.Item(name: "Anything", artists: nil)
        XCTAssertTrue(SpotifyWebAPI.matches(item, nil))
        XCTAssertTrue(SpotifyWebAPI.matches(nil, nil))
    }

    func testMatchesTreatsMissingArtistsAsBlankArtist() {
        // Podcast episodes surface with no `artists` array (see doc comment on Item).
        let track = Track(name: "Episode Title", artist: "", album: "", artwork: nil, duration: 0)
        let item = SpotifyWebAPI.Item(name: "Episode Title", artists: nil)
        XCTAssertTrue(SpotifyWebAPI.matches(item, track))
    }

    // MARK: - QueueResponse decoding

    func testDecodesQueueResponseWithArtists() throws {
        let json = """
        {
          "currently_playing": { "name": "Song Title", "artists": [{ "name": "Some Artist" }] },
          "queue": [
            { "name": "Next Song", "artists": [{ "name": "Next Artist" }] },
            { "name": "Episode", "artists": null }
          ]
        }
        """
        let decoded = try JSONDecoder().decode(SpotifyWebAPI.QueueResponse.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.currentlyPlaying?.name, "Song Title")
        XCTAssertEqual(decoded.queue.count, 2)
        XCTAssertEqual(decoded.queue[0].artists?.first?.name, "Next Artist")
        XCTAssertNil(decoded.queue[1].artists)
    }

    func testDecodesQueueResponseWithNoCurrentlyPlaying() throws {
        let json = """
        { "currently_playing": null, "queue": [] }
        """
        let decoded = try JSONDecoder().decode(SpotifyWebAPI.QueueResponse.self, from: Data(json.utf8))

        XCTAssertNil(decoded.currentlyPlaying)
        XCTAssertTrue(decoded.queue.isEmpty)
    }
}
