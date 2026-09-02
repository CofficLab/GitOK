// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenVSCode",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginOpenVSCode",
            targets: ["PluginOpenVSCode"]
        ),
    ],
    dependencies: [
        .package(path: "../KitOpenIn"),
    ],
    targets: [
        .target(
            name: "PluginOpenVSCode",
            dependencies: [
                .product(name: "KitOpenIn", package: "KitOpenIn"),
            ],
            path: "Sources/PluginOpenVSCode"
        ),
    ]
)
