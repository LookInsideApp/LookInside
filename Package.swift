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
        .iOS(.v12),
        .tvOS(.v12),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "LookinCore",
            targets: ["LookinCore"]
        ),
        .library(
            name: "LookinShared",
            targets: ["LookinCore", "LookinServerBase"]
        ),
        .library(
            name: "LookinServer",
            targets: ["LookinServer"]
        ),
        .library(
            name: "LookinServerDynamic",
            type: .dynamic,
            targets: ["LookinServer"]
        ),
        .library(
            name: "LookinServerInjected",
            type: .dynamic,
            targets: ["LookinServerInjected"]
        ),
        .library(
            name: "LookinMCPCore",
            targets: ["LookinMCPCore"]
        ),
        .executable(
            name: "lookinside-mcp",
            targets: ["LookinMCPServer"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.11.0"),
    ],
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
            cSettings: sharedCDefines + [
                .headerSearchPath("."),
                .headerSearchPath("Category"),
                .headerSearchPath("Peertalk"),
            ],
            cxxSettings: sharedCXXDefines
        ),
        .target(
            name: "LookinServerSwift",
            dependencies: ["LookinServerBase"],
            path: "Sources/LookinServerSwift",
            cxxSettings: sharedCXXDefines,
            swiftSettings: [
                .define("SHOULD_COMPILE_LOOKIN_SERVER"),
                .define("SPM_LOOKIN_SERVER_ENABLED"),
            ]
        ),
        .target(
            name: "LookinServer",
            dependencies: ["LookinCore", "LookinServerBase", "LookinServerSwift"],
            path: "Sources/LookinServer",
            exclude: ["Shared"],
            publicHeadersPath: "include",
            cSettings: sharedCDefines + [
                .headerSearchPath("Server"),
                .headerSearchPath("Server/Category"),
                .headerSearchPath("Server/Connection"),
                .headerSearchPath("Server/Connection/RequestHandler"),
                .headerSearchPath("Server/Others"),
                .headerSearchPath("../LookinCore"),
                .headerSearchPath("../LookinCore/include"),
                .headerSearchPath("../LookinCore/Category"),
                .headerSearchPath("../LookinCore/Peertalk"),
            ],
            cxxSettings: sharedCXXDefines
        ),
        .target(
            name: "LookinServerInjected",
            dependencies: ["LookinServer"],
            path: "Sources/LookinServerInjected",
            publicHeadersPath: "",
            cSettings: sharedCDefines,
            cxxSettings: sharedCXXDefines,
            linkerSettings: [
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
                .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS])),
            ]
        ),
        .target(
            name: "LookinMCPCore",
            dependencies: ["LookinCore"],
            path: "Sources/LookinMCPCore",
            swiftSettings: [
                .define("SHOULD_COMPILE_LOOKIN_SERVER"),
                .define("SPM_LOOKIN_SERVER_ENABLED"),
            ]
        ),
        .executableTarget(
            name: "LookinMCPServer",
            dependencies: [
                "LookinMCPCore",
                .product(name: "MCP", package: "swift-sdk"),
            ],
            path: "Sources/LookinMCPServer",
            swiftSettings: [
                .define("SHOULD_COMPILE_LOOKIN_SERVER"),
                .define("SPM_LOOKIN_SERVER_ENABLED"),
            ]
        ),
        .testTarget(
            name: "LookinMCPCoreTests",
            dependencies: ["LookinMCPCore"],
            path: "Tests/LookinMCPCoreTests",
            resources: [.process("Fixtures")],
            swiftSettings: [
                .define("SHOULD_COMPILE_LOOKIN_SERVER"),
                .define("SPM_LOOKIN_SERVER_ENABLED"),
            ]
        ),
    ]
)
