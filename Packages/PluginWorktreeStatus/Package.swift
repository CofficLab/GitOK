// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginWorktreeStatus",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginWorktreeStatus",
            targets: ["PluginWorktreeStatus"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitLocalization"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", branch: "main"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderRailView"),
        .package(path: "../ProviderGitRepositoryWatch"),
    ],
    targets: [
        .target(
            name: "PluginWorktreeStatus",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderRailView", package: "ProviderRailView"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
            ],
            path: "Sources/PluginWorktreeStatus",
            resources: [
                .process("../../Resources/Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "PluginWorktreeStatusTests",
            dependencies: ["PluginWorktreeStatus"],
            path: "Tests/PluginWorktreeStatusTests"
        ),
    ]
)
