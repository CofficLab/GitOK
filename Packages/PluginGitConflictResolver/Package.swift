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
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(path: "../KitGit"),
        .package(path: "../KitOpenIn"),
        .package(url: "https://github.com/CofficLab/LumiLogging.git", from: "1.0.1"),
        .package(url: "https://github.com/CofficLab/LumiLocalization.git", from: "1.0.0"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.7.0"),
        .package(path: "../ProviderGitRepositoryWatch"),
        .package(path: "../ProviderGit"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderRootView"),
        .package(path: "../ProviderWorkspaceScene"),
        .package(path: "../ProviderGitConflictResolver"),
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.3.7")
    ],
    targets: [
        .target(
            name: "PluginGitConflictResolver",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitOpenIn", package: "KitOpenIn"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "LumiLocalizationKit", package: "LumiLocalization"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderRootView", package: "ProviderRootView"),
                .product(name: "ProviderStatusBar", package: "LumiProviders"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
                .product(name: "ProviderGitConflictResolver", package: "ProviderGitConflictResolver"),
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
