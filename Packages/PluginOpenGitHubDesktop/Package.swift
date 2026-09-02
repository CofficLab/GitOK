// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenGitHubDesktop",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginOpenGitHubDesktop",
            targets: ["PluginOpenGitHubDesktop"]
        ),
    ],
    dependencies: [
        .package(path: "../KitOpenIn"),
    ],
    targets: [
        .target(
            name: "PluginOpenGitHubDesktop",
            dependencies: [
                .product(name: "KitOpenIn", package: "KitOpenIn"),
            ],
            path: "Sources/PluginOpenGitHubDesktop"
        ),
    ]
)
