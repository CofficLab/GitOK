// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenLumi",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginOpenLumi",
            targets: ["PluginOpenLumi"]
        ),
    ],
    dependencies: [
        .package(path: "../KitOpenIn"),
    ],
    targets: [
        .target(
            name: "PluginOpenLumi",
            dependencies: [
                .product(name: "KitOpenIn", package: "KitOpenIn"),
            ],
            path: "Sources/PluginOpenLumi"
        ),
    ]
)
