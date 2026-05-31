// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginSmartMerge",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginSmartMerge", targets: ["PluginSmartMerge"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKPluginKit"),
        .package(path: "../../Packages/GitCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginSmartMerge",
            dependencies: ["GitOKPluginKit", "GitCoreKit"],
            path: "Sources/PluginSmartMerge",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginSmartMergeTests",
            dependencies: ["PluginSmartMerge"],
            path: "Tests/PluginSmartMergeTests"
        ),
    ]
)
