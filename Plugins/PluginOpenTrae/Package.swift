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
        .package(path: "../../Packages/GitOKPluginKit"),
    ],
    targets: [
        .target(
            name: "PluginOpenTrae",
            dependencies: ["GitOKPluginKit"],
            path: "Sources/PluginOpenTrae",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginOpenTraeTests",
            dependencies: ["PluginOpenTrae"],
            path: "Tests/PluginOpenTraeTests"
        ),
    ]
)
