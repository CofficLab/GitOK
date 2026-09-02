// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenTrae",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginOpenTrae",
            targets: ["PluginOpenTrae"]
        ),
    ],
    dependencies: [
        .package(path: "../KitOpenIn"),
    ],
    targets: [
        .target(
            name: "PluginOpenTrae",
            dependencies: [
                .product(name: "KitOpenIn", package: "KitOpenIn"),
            ],
            path: "Sources/PluginOpenTrae"
        ),
    ]
)
