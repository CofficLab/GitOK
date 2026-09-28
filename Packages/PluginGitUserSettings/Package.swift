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
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.1.0"),
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(path: "../KitGit"),
        .package(url: "https://github.com/CofficLab/LumiLogging.git", from: "1.0.1"),
        .package(url: "https://github.com/CofficLab/LumiLocalization.git", from: "1.0.0"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.7.0"),
        .package(path: "../ProviderGitUser"),
        .package(path: "../ProviderProjects"),
        .package(url: "https://github.com/CofficLab/LumiSettings.git", from: "1.0.1"),
        .package(path: "../ProviderToast"),
        .package(path: "../ProviderDocsView"),
    ],
    targets: [
        .target(
            name: "PluginGitUserSettings",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "LumiLocalizationKit", package: "LumiLocalization"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderGitUser", package: "ProviderGitUser"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderSettingView", package: "LumiSettings"),
                .product(name: "ProviderStorage", package: "LumiProviders"),
                .product(name: "ProviderToast", package: "ProviderToast"),
                .product(name: "ProviderDocsView", package: "ProviderDocsView"),
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
