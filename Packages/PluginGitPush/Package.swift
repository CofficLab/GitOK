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
        .package(path: "../GitOKPluginKit"),
        .package(path: "../GitCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginGitPush",
            dependencies: ["GitOKPluginKit", "GitCoreKit"],
            path: "Sources/PluginGitPush",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginGitPushTests",
            dependencies: ["PluginGitPush"],
            path: "Tests/PluginGitPushTests"
        ),
    ]
)
