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
        .package(path: "../GitOKPluginKit"),
        .package(path: "../GitCoreKit"),
        .package(path: "../ProjectSupportKit"),
        .package(path: "../ProjectRulesKit"),
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
