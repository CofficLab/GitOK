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
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/lumi-softworks/LumiKernel.git", from: "1.1.2"),
        .package(path: "../KitGit"),
        .package(path: "../ProviderGit"),
        .package(url: "https://github.com/lumi-softworks/LumiLogging.git", from: "1.0.3"),
        .package(url: "https://github.com/lumi-softworks/LumiUI.git", from: "1.19.3"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderGitRepositoryWatch"),
        .package(path: "../ProviderGitConflictResolver"),
        .package(path: "../ProviderWorkspaceScene"),
        .package(url: "https://github.com/lumi-softworks/LumiProviders.git", from: "1.27.0")
    ],
    targets: [
        .target(
            name: "PluginWorktreeStatus",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "ProviderGit", package: "ProviderGit"),
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
            dependencies: [
                "PluginWorktreeStatus",
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderRailView", package: "LumiProviders"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
            ],
            path: "Tests/PluginWorktreeStatusTests"
        ),
    ]
)
