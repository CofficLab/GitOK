// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitCommitStyleSettings",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginGitCommitStyleSettings",
            targets: ["PluginGitCommitStyleSettings"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", branch: "main"),
        .package(path: "../ProviderCommitForm"),
        .package(path: "../ProviderSettingView"),
    ],
    targets: [
        .target(
            name: "PluginGitCommitStyleSettings",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderCommitForm", package: "ProviderCommitForm"),
                .product(name: "ProviderSettingView", package: "ProviderSettingView"),
            ],
            path: "Sources/PluginGitCommitStyleSettings"
        ),
        .testTarget(
            name: "PluginGitCommitStyleSettingsTests",
            dependencies: ["PluginGitCommitStyleSettings"],
            path: "Tests/PluginGitCommitStyleSettingsTests"
        ),
    ]
)
