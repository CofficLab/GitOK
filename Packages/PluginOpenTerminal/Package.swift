// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenTerminal",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginOpenTerminal",
            targets: ["PluginOpenTerminal"]
        ),
    ],
    dependencies: [
        .package(path: "../KitOpenIn"),
    ],
    targets: [
        .target(
            name: "PluginOpenTerminal",
            dependencies: [
                .product(name: "KitOpenIn", package: "KitOpenIn"),
            ],
            path: "Sources/PluginOpenTerminal"
        ),
    ]
)
