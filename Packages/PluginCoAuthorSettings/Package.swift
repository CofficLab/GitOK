// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginCoAuthorSettings",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginCoAuthorSettings",
            targets: ["PluginCoAuthorSettings"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
        .package(path: "../ProviderCoAuthor"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderSettingView"),
        .package(path: "../ProviderStorage"),
        .package(path: "../ProviderToast"),
        .package(path: "../ProviderDocsView"),
    ],
    targets: [
        .target(
            name: "PluginCoAuthorSettings",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderCoAuthor", package: "ProviderCoAuthor"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderSettingView", package: "ProviderSettingView"),
                .product(name: "ProviderStorage", package: "ProviderStorage"),
                .product(name: "ProviderToast", package: "ProviderToast"),
                .product(name: "ProviderDocsView", package: "ProviderDocsView"),
            ],
            path: "Sources/PluginCoAuthorSettings",
            resources: [
                .process("../../Resources/Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "PluginCoAuthorSettingsTests",
            dependencies: ["PluginCoAuthorSettings"],
            path: "Tests/PluginCoAuthorSettingsTests"
        ),
    ]
)
