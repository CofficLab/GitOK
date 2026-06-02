// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginUnpushedStatus",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginUnpushedStatus", targets: ["PluginUnpushedStatus"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginUnpushedStatus",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginUnpushedStatusTests",
            dependencies: ["PluginUnpushedStatus"],
            path: "Tests"
        ),
    ]
)
