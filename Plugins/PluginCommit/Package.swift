// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginCommit",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginCommit", targets: ["PluginCommit"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKPluginKit"),
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/ProjectSupportKit"),
        .package(path: "../../Packages/ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "PluginCommit",
            dependencies: ["GitOKPluginKit", "GitCoreKit", "ProjectSupportKit", "ProjectRulesKit"],
            path: "Sources/PluginCommit",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginCommitTests",
            dependencies: ["PluginCommit"],
            path: "Tests/PluginCommitTests"
        ),
    ]
)
