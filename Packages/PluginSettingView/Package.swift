// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginSettingView",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PluginSettingView",
            targets: ["PluginSettingView"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.1.0"),
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.7.0"),
        .package(url: "https://github.com/CofficLab/LumiSettings.git", from: "1.0.1"),
        .package(url: "https://github.com/CofficLab/LumiLogging.git", from: "1.0.1"),
        .package(url: "https://github.com/CofficLab/LumiLocalization.git", from: "1.0.0"),
        .package(path: "../ProviderDocsView"),
    ],
    targets: [
        .target(
            name: "PluginSettingView",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderSettingView", package: "LumiSettings"),
                .product(name: "ProviderStorage", package: "LumiProviders"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "LumiLocalizationKit", package: "LumiLocalization"),
                .product(name: "ProviderDocsView", package: "ProviderDocsView"),
            ],
            resources: [.process("../../Resources/Localizable.xcstrings")]
        ),
        .testTarget(
            name: "PluginSettingViewTests",
            dependencies: ["PluginSettingView"]
        ),
    ]
)
