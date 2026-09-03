// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginDiagnosticsSettings",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginDiagnosticsSettings",
            targets: ["PluginDiagnosticsSettings"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", branch: "main"),
        .package(path: "../ProviderSettingView"),
    ],
    targets: [
        .target(
            name: "PluginDiagnosticsSettings",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderSettingView", package: "ProviderSettingView"),
            ],
            path: "Sources/PluginDiagnosticsSettings"
        ),
        .testTarget(
            name: "PluginDiagnosticsSettingsTests",
            dependencies: ["PluginDiagnosticsSettings"],
            path: "Tests/PluginDiagnosticsSettingsTests"
        ),
    ]
)
