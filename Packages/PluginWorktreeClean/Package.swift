// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginWorktreeClean",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "PluginWorktreeClean", targets: ["PluginWorktreeClean"]),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitLocalization"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
        .package(path: "../ProviderContentView"),
        .package(path: "../ProviderGit"),
        .package(path: "../ProviderGitUser"),
        .package(path: "../ProviderGitRepositoryWatch"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderSettingView"),
        .package(path: "../ProviderWorkspaceScene"),
    ],
    targets: [
        .target(
            name: "PluginWorktreeClean",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderContentView", package: "ProviderContentView"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderGitUser", package: "ProviderGitUser"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderSettingView", package: "ProviderSettingView"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
            ],
            path: "Sources/PluginWorktreeClean",
            resources: [
                .process("../../Resources/Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "PluginWorktreeCleanTests",
            dependencies: [
                "PluginWorktreeClean",
                .product(name: "ProviderGitUser", package: "ProviderGitUser"),
            ],
            path: "Tests/PluginWorktreeCleanTests"
        ),
    ]
)
