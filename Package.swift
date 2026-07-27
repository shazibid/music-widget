// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Miniplayer",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "Miniplayer",
            path: "Sources/Miniplayer"
        ),
        .testTarget(
            name: "MiniplayerTests",
            dependencies: ["Miniplayer"],
            path: "Tests/MiniplayerTests"
        )
        // No SwiftPM target for Tests/MiniplayerUITests: XCUIApplication
        // cannot run inside a plain `swift test` bundle at all (macOS
        // refuses it — "Device is not configured for UI testing" — no
        // matter what permissions are granted). Those UI tests are built
        // and run via MiniplayerUITests.xcodeproj / `xcodebuild test`
        // instead — see that project and the README's Testing section.
    ]
)
