// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenFinder",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginOpenFinder",
            targets: ["PluginOpenFinder"]
        ),
    ],
    dependencies: [
        .package(path: "../KitOpenIn"),
    ],
    targets: [
        .target(
            name: "PluginOpenFinder",
            dependencies: [
                .product(name: "KitOpenIn", package: "KitOpenIn"),
            ],
            path: "Sources/PluginOpenFinder"
        ),
    ]
)
