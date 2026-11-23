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
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/lumi-softworks/LumiKernel.git", from: "1.1.2"),
        .package(url: "https://github.com/lumi-softworks/LumiLogging.git", from: "1.0.3"),
        .package(url: "https://github.com/lumi-softworks/LumiUI.git", from: "1.19.3"),
        .package(url: "https://github.com/lumi-softworks/LumiSettings.git", from: "1.1.2"),
        .package(url: "https://github.com/lumi-softworks/LumiProviders.git", from: "1.27.0")
    ],
    targets: [
        .target(
            name: "PluginDiagnosticsSettings",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderSettingView", package: "LumiSettings"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
            ],
            path: "Sources/PluginDiagnosticsSettings",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginDiagnosticsSettingsTests",
            dependencies: [
                "PluginDiagnosticsSettings",
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderSettingView", package: "LumiSettings"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
            ],
            path: "Tests/PluginDiagnosticsSettingsTests"
        ),
    ]
)
