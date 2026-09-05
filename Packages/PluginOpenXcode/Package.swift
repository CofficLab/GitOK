// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenXcode",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginOpenXcode",
            targets: ["PluginOpenXcode"]
        ),
    ],
    dependencies: [
        .package(path: "../KitOpenIn"),
    ],
    targets: [
        .target(
            name: "PluginOpenXcode",
            dependencies: [
                .product(name: "KitOpenIn", package: "KitOpenIn"),
            ],
            path: "Sources/PluginOpenXcode"
        ),
    ]
)
