// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginStash",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginStash", targets: ["PluginStash"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginStash",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources/PluginStash",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginStashTests",
            dependencies: ["PluginStash"],
            path: "Tests"
        ),
    ]
)
