// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MiraiStreakKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v2),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "MiraiStreakKit",
            targets: ["MiraiStreakKit"]
        ),
        .library(
            name: "MiraiStreakKitUI",
            targets: ["MiraiStreakKitUI"]
        )
    ],
    targets: [
        .target(
            name: "MiraiStreakKit"
        ),
        .target(
            name: "MiraiStreakKitUI",
            dependencies: ["MiraiStreakKit"]
        ),
        .testTarget(
            name: "MiraiStreakKitTests",
            dependencies: ["MiraiStreakKit"]
        ),
        .testTarget(
            name: "MiraiStreakKitUITests",
            dependencies: ["MiraiStreakKitUI"]
        )
    ]
)
