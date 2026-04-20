// swift-tools-version: 5.10

// This package is intentionally empty. The LookInside macOS client depends on
// the LookInsideServer package (MIT) for the shared runtime surface. The
// SwiftPM dependency declared below is consumed by Scripts/sync-derived-source.sh,
// which runs `swift package resolve` to populate
// `.build/checkouts/LookInsideServer/Sources` and then mirrors the shared
// Objective-C code into `LookInside/DerivedSource/` for the Xcode build.
//
// The Xcode project (LookInside.xcodeproj) also consumes the `LookinServer`
// SwiftPM product from the same remote package.

import PackageDescription

let package = Package(
    name: "LookInside",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(url: "https://github.com/LookInsideApp/LookInsideServer.git", from: "1.0.0"),
    ]
)
