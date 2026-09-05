// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginBanner",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginBanner", targets: ["PluginBanner"]),
    ],
    dependencies: [
        .package(path: "../BannerCoreKit"),
        .package(path: "../KernelCore"),
        .package(path: "../ProjectRulesKit"),
        .package(path: "../ProviderContentView"),
        .package(path: "../ProviderProjects"),
    ],
    targets: [
        .target(
            name: "PluginBanner",
            dependencies: [
                .product(name: "BannerCoreKit", package: "BannerCoreKit"),
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "ProjectRulesKit", package: "ProjectRulesKit"),
                .product(name: "ProviderContentView", package: "ProviderContentView"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
            ],
            path: "Sources/PluginBanner"
        ),
        .testTarget(
            name: "PluginBannerTests",
            dependencies: ["PluginBanner"],
            path: "Tests/PluginBannerTests"
        ),
    ]
)
