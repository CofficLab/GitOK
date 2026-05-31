// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitPush",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginGitPush", targets: ["PluginGitPush"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginGitPush",
            dependencies: ["GitOKCoreKit", "GitCoreKit"],
            path: "Sources/PluginGitPush",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginGitPushTests",
            dependencies: ["PluginGitPush"],
            path: "Tests"
        ),
    ]
)
