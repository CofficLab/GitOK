// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenTrae",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "PluginOpenTrae", targets: ["PluginOpenTrae"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginOpenTrae",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginOpenTraeTests",
            dependencies: ["PluginOpenTrae"],
            path: "Tests"
        ),
    ]
)
