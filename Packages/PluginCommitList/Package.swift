// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginCommitList",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginCommitList",
            targets: ["PluginCommitList"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", branch: "main"),
        .package(path: "../ProviderGitRepositoryWatch"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderRailView"),
        .package(path: "../ProviderRootView"),
    ],
    targets: [
        .target(
            name: "PluginCommitList",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderRailView", package: "ProviderRailView"),
                .product(name: "ProviderRootView", package: "ProviderRootView"),
            ],
            path: "Sources/PluginCommitList"
        ),
        .testTarget(
            name: "PluginCommitListTests",
            dependencies: ["PluginCommitList"],
            path: "Tests/PluginCommitListTests"
        ),
    ]
)
