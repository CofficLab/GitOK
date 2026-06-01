// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginAutoPush",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginAutoPush", targets: ["PluginAutoPush"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginAutoPush",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources/PluginAutoPush",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginAutoPushTests",
            dependencies: ["PluginAutoPush"],
            path: "Tests"
        ),
    ]
)
