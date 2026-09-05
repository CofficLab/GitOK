// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitConflictResolver",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginGitConflictResolver",
            targets: ["PluginGitConflictResolver"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitSuperLog"),
        .package(path: "../KitLocalization"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
        .package(path: "../ProviderGitRepositoryWatch"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderRootView"),
        .package(path: "../ProviderStatusBar"),
        .package(path: "../ProviderWorkspaceScene"),
    ],
    targets: [
        .target(
            name: "PluginGitConflictResolver",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderRootView", package: "ProviderRootView"),
                .product(name: "ProviderStatusBar", package: "ProviderStatusBar"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
            ],
            path: "Sources/PluginGitConflictResolver",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginGitConflictResolverTests",
            dependencies: ["PluginGitConflictResolver"],
            path: "Tests/PluginGitConflictResolverTests"
        ),
    ]
)
