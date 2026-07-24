// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MusicWidget",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "MusicWidget",
            path: "Sources/MusicWidget"
        )
    ]
)
