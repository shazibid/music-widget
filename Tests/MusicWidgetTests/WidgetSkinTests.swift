import XCTest
@testable import MusicWidget

final class WidgetSkinTests: XCTestCase {
    func testOnlyPillIsWidthResizable() {
        for skin in WidgetSkin.allCases {
            XCTAssertEqual(skin.isWidthResizable, skin == .pill, "\(skin) resizability")
        }
    }

    func testCornerRadiusPerSkin() {
        XCTAssertEqual(WidgetSkin.pill.cornerRadius, 20)
        XCTAssertEqual(WidgetSkin.cd.cornerRadius, 28)
        XCTAssertEqual(WidgetSkin.vinyl.cornerRadius, 28)
        XCTAssertEqual(WidgetSkin.ipod.cornerRadius, 0)
    }

    func testWindowSizeIsPositiveForEverySkin() {
        for skin in WidgetSkin.allCases {
            XCTAssertGreaterThan(skin.windowSize.width, 0, "\(skin) width")
            XCTAssertGreaterThan(skin.windowSize.height, 0, "\(skin) height")
        }
    }

    func testPillWidthBoundsAreOrdered() {
        XCTAssertLessThan(WidgetSkin.pillMinWidth, WidgetSkin.pillMaxWidth)
        XCTAssertGreaterThanOrEqual(WidgetSkin.pill.windowSize.width, WidgetSkin.pillMinWidth)
        XCTAssertLessThanOrEqual(WidgetSkin.pill.windowSize.width, WidgetSkin.pillMaxWidth)
    }

    func testDisplayNamesAreUnique() {
        let names = Set(WidgetSkin.allCases.map(\.displayName))
        XCTAssertEqual(names.count, WidgetSkin.allCases.count)
    }
}
