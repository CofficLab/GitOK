// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenCursor",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginOpenCursor",
            targets: ["PluginOpenCursor"]
        ),
    ],
    dependencies: [
        .package(path: "../KitOpenIn"),
    ],
    targets: [
        .target(
            name: "PluginOpenCursor",
            dependencies: [
                .product(name: "KitOpenIn", package: "KitOpenIn"),
            ],
            path: "Sources/PluginOpenCursor"
        ),
    ]
)
