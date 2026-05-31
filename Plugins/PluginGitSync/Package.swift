// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitSync",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginGitSync", targets: ["PluginGitSync"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKPluginKit"),
        .package(path: "../../Packages/GitCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginGitSync",
            dependencies: [
                "GitOKPluginKit",
                "GitCoreKit",
            ],
            path: "Sources/PluginGitSync",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginGitSyncTests",
            dependencies: ["PluginGitSync"],
            path: "Tests/PluginGitSyncTests"
        ),
    ]
)
