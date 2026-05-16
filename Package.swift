// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "togglenotch",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "togglenotch", targets: ["togglenotch"]),
        .library(name: "ToggleNotchCore", targets: ["ToggleNotchCore"])
    ],
    targets: [
        .target(name: "ToggleNotchCore"),
        .executableTarget(
            name: "togglenotch",
            dependencies: ["ToggleNotchCore"]
        ),
        .testTarget(
            name: "ToggleNotchCoreTests",
            dependencies: ["ToggleNotchCore"]
        )
    ]
)
