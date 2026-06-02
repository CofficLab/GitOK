// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginIconTab",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginIconTab", targets: ["PluginIconTab"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginIconTab",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginIconTabTests",
            dependencies: ["PluginIconTab"],
            path: "Tests"
        ),
    ]
)
