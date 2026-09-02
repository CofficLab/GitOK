// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenKiro",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginOpenKiro",
            targets: ["PluginOpenKiro"]
        ),
    ],
    dependencies: [
        .package(path: "../KitOpenIn"),
    ],
    targets: [
        .target(
            name: "PluginOpenKiro",
            dependencies: [
                .product(name: "KitOpenIn", package: "KitOpenIn"),
            ],
            path: "Sources/PluginOpenKiro"
        ),
    ]
)
