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
        .package(path: "../BannerCoreKit"),
        .package(path: "../KernelCore"),
        .package(path: "../KitGitOKSupport"),
        .package(path: "../KitLocalization"),
        .package(path: "../ProjectRulesKit"),
        .package(path: "../ProviderContentView"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderWorkspaceScene"),
    ],
    targets: [
        .target(
            name: "PluginBanner",
            dependencies: [
                .product(name: "BannerCoreKit", package: "BannerCoreKit"),
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGitOKSupport", package: "KitGitOKSupport"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "ProjectRulesKit", package: "ProjectRulesKit"),
                .product(name: "ProviderContentView", package: "ProviderContentView"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
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
