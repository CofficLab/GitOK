// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginSettingsButton",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginSettingsButton",
            targets: ["PluginSettingsButton"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", branch: "main"),
        .package(path: "../ProviderSettingView"),
        .package(path: "../ProviderToolbar"),
    ],
    targets: [
        .target(
            name: "PluginSettingsButton",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderSettingView", package: "ProviderSettingView"),
                .product(name: "ProviderToolbar", package: "ProviderToolbar"),
            ],
            path: "Sources/PluginSettingsButton"
        ),
        .testTarget(
            name: "PluginSettingsButtonTests",
            dependencies: [
                "PluginSettingsButton",
                .product(name: "ProviderToolbar", package: "ProviderToolbar"),
            ],
            path: "Tests/PluginSettingsButtonTests"
        ),
    ]
)
