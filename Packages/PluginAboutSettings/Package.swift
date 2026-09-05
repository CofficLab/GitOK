// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginAboutSettings",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginAboutSettings",
            targets: ["PluginAboutSettings"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
        .package(path: "../ProviderSettingView"),
    ],
    targets: [
        .target(
            name: "PluginAboutSettings",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderSettingView", package: "ProviderSettingView"),
            ],
            path: "Sources/PluginAboutSettings"
        ),
        .testTarget(
            name: "PluginAboutSettingsTests",
            dependencies: ["PluginAboutSettings"],
            path: "Tests/PluginAboutSettingsTests"
        ),
    ]
)
