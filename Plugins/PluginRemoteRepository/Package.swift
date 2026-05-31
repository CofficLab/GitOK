// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginRemoteRepository",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginRemoteRepository", targets: ["PluginRemoteRepository"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKPluginKit"),
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "PluginRemoteRepository",
            dependencies: ["GitOKPluginKit", "GitCoreKit", "ProjectRulesKit"],
            path: "Sources/PluginRemoteRepository",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginRemoteRepositoryTests",
            dependencies: ["PluginRemoteRepository"],
            path: "Tests/PluginRemoteRepositoryTests"
        ),
    ]
)
