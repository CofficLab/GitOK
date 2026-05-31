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
        .package(path: "../../Packages/GitOKPluginKit"),
    ],
    targets: [
        .target(
            name: "PluginIconTab",
            dependencies: ["GitOKPluginKit"],
            path: "Sources/PluginIconTab",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginIconTabTests",
            dependencies: ["PluginIconTab"],
            path: "Tests"
        ),
    ]
)
