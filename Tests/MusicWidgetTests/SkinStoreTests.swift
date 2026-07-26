import AppKit
import XCTest
@testable import MusicWidget

@MainActor
final class SkinStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "SkinStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        try await super.tearDown()
    }

    func testDefaultsToPillWhenNothingSaved() {
        let store = SkinStore(defaults: defaults)
        XCTAssertEqual(store.skin, .pill)
    }

    func testSkinChangePersistsAcrossInstances() {
        let store = SkinStore(defaults: defaults)
        store.skin = .vinyl

        let reloaded = SkinStore(defaults: defaults)
        XCTAssertEqual(reloaded.skin, .vinyl)
    }

    func testPillWidthDefaultsToDesignWidthWhenUnset() {
        let store = SkinStore(defaults: defaults)
        XCTAssertEqual(store.pillWidth, WidgetSkin.pill.windowSize.width)
    }

    func testPillWidthClampsToMinAndMax() {
        let store = SkinStore(defaults: defaults)

        store.pillWidth = WidgetSkin.pillMinWidth - 100
        XCTAssertEqual(store.pillWidth, WidgetSkin.pillMinWidth)

        store.pillWidth = WidgetSkin.pillMaxWidth + 100
        XCTAssertEqual(store.pillWidth, WidgetSkin.pillMaxWidth)
    }

    func testPillWidthRoundTripsWithinBounds() {
        let store = SkinStore(defaults: defaults)
        let width = (WidgetSkin.pillMinWidth + WidgetSkin.pillMaxWidth) / 2
        store.pillWidth = width
        XCTAssertEqual(store.pillWidth, width)
    }

    func testWindowOriginIsNilUntilSet() {
        let store = SkinStore(defaults: defaults)
        XCTAssertNil(store.windowOrigin)
    }

    func testWindowOriginRoundTrips() {
        let store = SkinStore(defaults: defaults)
        let origin = NSPoint(x: 123, y: 456)
        store.windowOrigin = origin
        XCTAssertEqual(store.windowOrigin, origin)
    }
}
