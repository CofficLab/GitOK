// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenRemote",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginOpenRemote",
            targets: ["PluginOpenRemote"]
        ),
    ],
    dependencies: [
        .package(path: "../KitOpenIn"),
    ],
    targets: [
        .target(
            name: "PluginOpenRemote",
            dependencies: [
                .product(name: "KitOpenIn", package: "KitOpenIn"),
            ],
            path: "Sources/PluginOpenRemote"
        ),
    ]
)
