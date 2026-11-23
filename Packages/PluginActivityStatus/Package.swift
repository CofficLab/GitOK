// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginActivityStatus",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginActivityStatus",
            targets: ["PluginActivityStatus"]
        ),
    ],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/lumi-softworks/LumiKernel.git", from: "1.1.2"),
        .package(url: "https://github.com/lumi-softworks/LumiLogging.git", from: "1.0.3"),
        .package(path: "../ProviderActivity"),
        .package(url: "https://github.com/lumi-softworks/LumiUI.git", from: "1.19.3"),
        .package(url: "https://github.com/lumi-softworks/LumiProviders.git", from: "1.27.0")
    ],
    targets: [
        .target(
            name: "PluginActivityStatus",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "ProviderActivity", package: "ProviderActivity"),
                .product(name: "ProviderStatusBar", package: "LumiProviders"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
                .product(name: "LumiUI", package: "LumiUI"),
            ],
            path: "Sources/PluginActivityStatus",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginActivityStatusTests",
            dependencies: [
                "PluginActivityStatus",
                .product(name: "ProviderActivity", package: "ProviderActivity"),
                .product(name: "ProviderStatusBar", package: "LumiProviders"),
            ],
            path: "Tests/PluginActivityStatusTests"
        ),
    ]
)
