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
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(path: "../KitGit"),
        .package(path: "../ProviderGit"),
        .package(url: "https://github.com/CofficLab/LumiLocalization.git", from: "1.0.0"),
        .package(url: "https://github.com/CofficLab/LumiLogging.git", from: "1.0.1"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.7.0"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderGitRepositoryWatch"),
        .package(path: "../ProviderGitConflictResolver"),
        .package(path: "../ProviderWorkspaceScene"),
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.2.6")
    ],
    targets: [
        .target(
            name: "PluginWorktreeStatus",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "LumiLocalizationKit", package: "LumiLocalization"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderRailView", package: "LumiProviders"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
                .product(name: "ProviderToast", package: "LumiProviders"),
                .product(name: "ProviderGitConflictResolver", package: "ProviderGitConflictResolver"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
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
