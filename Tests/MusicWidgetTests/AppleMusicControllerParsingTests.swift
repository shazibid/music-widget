import XCTest
@testable import MusicWidget

final class AppleMusicControllerParsingTests: XCTestCase {
    private let unitSeparator = "\u{241F}"
    private let recordSeparator = "\u{241E}"

    func testParsesWellFormedTrackFields() {
        let raw = ["Song Title", "Some Artist", "Some Album", "245"].joined(separator: unitSeparator)

        let fields = AppleMusicController.parseTrackFields(raw)

        XCTAssertEqual(fields?.name, "Song Title")
        XCTAssertEqual(fields?.artist, "Some Artist")
        XCTAssertEqual(fields?.album, "Some Album")
        // Music reports duration in seconds already — no conversion.
        XCTAssertEqual(fields?.duration, 245)
    }

    func testTrackFieldsReturnsNilForNilOrEmptyInput() {
        XCTAssertNil(AppleMusicController.parseTrackFields(nil))
        XCTAssertNil(AppleMusicController.parseTrackFields(""))
    }

    func testTrackFieldsReturnsNilForWrongFieldCount() {
        let raw = ["Song Title", "Some Artist"].joined(separator: unitSeparator)
        XCTAssertNil(AppleMusicController.parseTrackFields(raw))
    }

    func testParsesMultipleQueueItems() {
        let raw = [
            ["Next Song", "Next Artist"].joined(separator: recordSeparator),
            ["Later Song", "Later Artist"].joined(separator: recordSeparator)
        ].joined(separator: unitSeparator)

        let items = AppleMusicController.parseQueueItems(raw)

        XCTAssertEqual(items.map(\.name), ["Next Song", "Later Song"])
        XCTAssertEqual(items.map(\.artist), ["Next Artist", "Later Artist"])
    }

    func testQueueItemsReturnsEmptyForNilOrEmptyInput() {
        XCTAssertEqual(AppleMusicController.parseQueueItems(nil), [])
        XCTAssertEqual(AppleMusicController.parseQueueItems(""), [])
    }

    func testQueueItemsSkipsMalformedEntries() {
        let raw = [
            ["Good Song", "Good Artist"].joined(separator: recordSeparator),
            "malformed-entry-no-record-separator"
        ].joined(separator: unitSeparator)

        let items = AppleMusicController.parseQueueItems(raw)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "Good Song")
    }
}
