// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitRepositorySettings",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginGitRepositorySettings",
            targets: ["PluginGitRepositorySettings"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", branch: "main"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderSettingView"),
    ],
    targets: [
        .target(
            name: "PluginGitRepositorySettings",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderSettingView", package: "ProviderSettingView"),
            ],
            path: "Sources/PluginGitRepositorySettings"
        ),
        .testTarget(
            name: "PluginGitRepositorySettingsTests",
            dependencies: ["PluginGitRepositorySettings"],
            path: "Tests/PluginGitRepositorySettingsTests"
        ),
    ]
)
