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
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginSmartMerge",
            dependencies: ["GitOKCoreKit"],
            path: "Sources/PluginSmartMerge",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginSmartMergeTests",
            dependencies: ["PluginSmartMerge"],
            path: "Tests"
        ),
    ]
)
