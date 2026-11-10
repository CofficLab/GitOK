// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginBanner",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginBanner", targets: ["PluginBanner"]),
    ],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
        .package(path: "../BannerCoreKit"),
        .package(url: "https://github.com/CofficLab/LumiKernel.git", from: "1.1.0"),
        .package(path: "../KitGitOKSupport"),
        .package(path: "../ProjectRulesKit"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderWorkspaceScene"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.12.0"),
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.21.0")
    ],
    targets: [
        .target(
            name: "PluginBanner",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "BannerCoreKit", package: "BannerCoreKit"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGitOKSupport", package: "KitGitOKSupport"),
                .product(name: "ProjectRulesKit", package: "ProjectRulesKit"),
                .product(name: "ProviderContentView", package: "LumiProviders"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
                .product(name: "LumiUI", package: "LumiUI"),
            ],
            path: "Sources/PluginBanner",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginBannerTests",
            dependencies: ["PluginBanner"],
            path: "Tests/PluginBannerTests"
        ),
    ]
)
