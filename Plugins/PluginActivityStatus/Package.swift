// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginActivityStatus",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginActivityStatus", targets: ["PluginActivityStatus"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginActivityStatus",
            dependencies: ["GitOKCoreKit"],
            path: "Sources/PluginActivityStatus",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginActivityStatusTests",
            dependencies: ["PluginActivityStatus"],
            path: "Tests"
        ),
    ]
)
