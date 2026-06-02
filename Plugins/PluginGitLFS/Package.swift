// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitLFS",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginGitLFS", targets: ["PluginGitLFS"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginGitLFS",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources/PluginGitLFS",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginGitLFSTests",
            dependencies: ["PluginGitLFS"],
            path: "Tests"
        ),
    ]
)
