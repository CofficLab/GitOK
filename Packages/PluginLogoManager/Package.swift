// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginLogoManager",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PluginLogoManager",
            targets: ["PluginLogoManager"]
        ),
    ],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/CofficLab/LumiKernel.git", from: "1.1.0"),
        .package(url: "https://github.com/CofficLab/LumiLogging.git", from: "1.0.1"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.12.0"),
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.21.0")
    ],
    targets: [
        .target(
            name: "PluginLogoManager",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
                .product(name: "ProviderLogo", package: "LumiProviders"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "LumiUI", package: "LumiUI"),
            ],
            path: "Sources/PluginLogoManager",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginLogoManagerTests",
            dependencies: ["PluginLogoManager"]
        ),
    ]
)
