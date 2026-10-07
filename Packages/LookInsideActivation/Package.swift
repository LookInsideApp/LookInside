// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LookInsideActivation",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LookInsideActivation", targets: ["LookInsideActivation"]),
        .library(name: "LookInsideActivationUI", targets: ["LookInsideActivationUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/simibac/ConfettiSwiftUI.git", from: "2.0.0"),
        .package(url: "https://github.com/Lakr233/WindowAnimation.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "LookInsideActivation",
            resources: [.process("Resources")]
        ),
        .target(
            name: "LookInsideActivationUI",
            dependencies: [
                "LookInsideActivation",
                .product(name: "ConfettiSwiftUI", package: "ConfettiSwiftUI"),
                .product(name: "WindowAnimation", package: "WindowAnimation"),
            ]
        ),
        .testTarget(
            name: "LookInsideActivationTests",
            dependencies: ["LookInsideActivation", "LookInsideActivationUI"],
            resources: [.copy("Fixtures")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
