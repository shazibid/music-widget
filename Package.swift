// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MusicWidget",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "MusicWidget",
            path: "Sources/MusicWidget"
        ),
        .testTarget(
            name: "MusicWidgetTests",
            dependencies: ["MusicWidget"],
            path: "Tests/MusicWidgetTests"
        )
        // No SwiftPM target for Tests/MusicWidgetUITests: XCUIApplication
        // cannot run inside a plain `swift test` bundle at all (macOS
        // refuses it — "Device is not configured for UI testing" — no
        // matter what permissions are granted). Those UI tests are built
        // and run via MusicWidgetUITests.xcodeproj / `xcodebuild test`
        // instead — see that project and the README's Testing section.
    ]
)
