// swift-tools-version: 6.0

// Host building blocks that do not need AppKit or the LookinCore model:
// the multi-subscriber AsyncStream broadcaster and the pure decisions of the
// Connection layer (response frame accounting, Server version check, license
// handshake gate and retry policy). The LookInside app target links the
// library; `swift test` runs the tests without building the app.

import PackageDescription

let package = Package(
    name: "LookInsideHostCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LookInsideHostCore", targets: ["LookInsideHostCore"]),
    ],
    targets: [
        .target(name: "LookInsideHostCore"),
        .testTarget(
            name: "LookInsideHostCoreTests",
            dependencies: ["LookInsideHostCore"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
