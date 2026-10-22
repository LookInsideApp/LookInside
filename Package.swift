// swift-tools-version: 5.10

import PackageDescription

let sharedCDefines: [CSetting] = [
    .define("SHOULD_COMPILE_LOOKIN_SERVER", to: "1"),
    .define("SPM_LOOKIN_SERVER_ENABLED", to: "1"),
]

let sharedCXXDefines: [CXXSetting] = [
    .define("SHOULD_COMPILE_LOOKIN_SERVER", to: "1"),
    .define("SPM_LOOKIN_SERVER_ENABLED", to: "1"),
]

let package = Package(
    name: "LookInside",
    platforms: [
        .iOS(.v15),
        .tvOS(.v12),
        .macOS(.v11),
    ],
    products: [
        .library(
            name: "LookinCore",
            targets: ["LookinCore", "LookinCoreImpl"]
        ),
        .library(
            name: "LookinShared",
            targets: ["LookinCore", "LookinCoreImpl", "LookinServerBase"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LookinServerBase",
            path: "Sources/LookinServerBase",
            publicHeadersPath: "",
            cSettings: [
                .define("SHOULD_COMPILE_LOOKIN_SERVER", to: "1"),
            ],
            cxxSettings: [
                .define("SHOULD_COMPILE_LOOKIN_SERVER", to: "1"),
            ]
        ),
        .target(
            name: "LookinCore",
            dependencies: ["LookinServerBase"],
            path: "Sources/LookinCore",
            publicHeadersPath: "include",
            cSettings: sharedCDefines,
            cxxSettings: sharedCXXDefines
        ),
        // The LookinCore model classes (plain Swift, `@objc(OriginalName)`), mirrored
        // from LookInside-Server (Scripts/sync-lookin-core.sh).
        .target(
            name: "LookinCoreImpl",
            dependencies: ["LookinCore", "LookinServerBase"],
            path: "Sources/LookinCoreImpl",
            swiftSettings: [
                .define("SHOULD_COMPILE_LOOKIN_SERVER"),
                .define("SPM_LOOKIN_SERVER_ENABLED"),
            ]
        ),
    ]
)
