// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitUserSettings",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginGitUserSettings",
            targets: ["PluginGitUserSettings"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitSuperLog"),
        .package(path: "../KitLocalization"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
        .package(path: "../ProviderGit"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderSettingView"),
        .package(path: "../ProviderStorage"),
        .package(path: "../ProviderToast"),
    ],
    targets: [
        .target(
            name: "PluginGitUserSettings",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderSettingView", package: "ProviderSettingView"),
                .product(name: "ProviderStorage", package: "ProviderStorage"),
                .product(name: "ProviderToast", package: "ProviderToast"),
            ],
            path: "Sources/PluginGitUserSettings",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginGitUserSettingsTests",
            dependencies: ["PluginGitUserSettings"],
            path: "Tests/PluginGitUserSettingsTests"
        ),
    ]
)
