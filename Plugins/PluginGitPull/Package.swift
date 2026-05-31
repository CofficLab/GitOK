// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitPull",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginGitPull", targets: ["PluginGitPull"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginGitPull",
            dependencies: [
                "GitOKCoreKit",
                "GitCoreKit",
            ],
            path: "Sources/PluginGitPull",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginGitPullTests",
            dependencies: ["PluginGitPull"],
            path: "Tests"
        ),
    ]
)
