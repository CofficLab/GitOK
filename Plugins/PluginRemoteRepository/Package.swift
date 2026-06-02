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
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "PluginRemoteRepository",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
                "ProjectRulesKit",
            ],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginRemoteRepositoryTests",
            dependencies: ["PluginRemoteRepository"],
            path: "Tests"
        ),
    ]
)
