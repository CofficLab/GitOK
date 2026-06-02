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
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginGitPush",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginGitPushTests",
            dependencies: ["PluginGitPush"],
            path: "Tests"
        ),
    ]
)
