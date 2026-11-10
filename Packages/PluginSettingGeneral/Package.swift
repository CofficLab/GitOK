// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginSettingGeneral",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PluginSettingGeneral",
            targets: ["PluginSettingGeneral"]
        ),
    ],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/CofficLab/LumiLogging.git", from: "1.0.1"),
        .package(url: "https://github.com/CofficLab/LumiKernel.git", from: "1.1.0"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.12.0"),
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.21.0"),
        .package(url: "https://github.com/CofficLab/LumiSettings.git", from: "1.1.0"),
        .package(path: "../KitGitOKCLI"),
    ],
    targets: [
        .target(
            name: "PluginSettingGeneral",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "KitGitOKCLI", package: "KitGitOKCLI"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
                .product(name: "ProviderCommand", package: "LumiProviders"),
                .product(name: "ProviderSettingView", package: "LumiSettings"),
            ],
            path: "Sources/PluginSettingGeneral",
            resources: [.process("../../Resources/Localizable.xcstrings")]
        ),
        .testTarget(
            name: "PluginSettingGeneralTests",
            dependencies: ["PluginSettingGeneral"]
        )
    ]
)
