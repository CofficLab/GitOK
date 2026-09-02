// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenAntigravity",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginOpenAntigravity",
            targets: ["PluginOpenAntigravity"]
        ),
    ],
    dependencies: [
        .package(path: "../KitOpenIn"),
    ],
    targets: [
        .target(
            name: "PluginOpenAntigravity",
            dependencies: [
                .product(name: "KitOpenIn", package: "KitOpenIn"),
            ],
            path: "Sources/PluginOpenAntigravity"
        ),
    ]
)
