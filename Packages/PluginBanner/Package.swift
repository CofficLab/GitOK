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
        .package(path: "../ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "PluginBanner",
            dependencies: [
                .product(name: "BannerCoreKit", package: "BannerCoreKit"),
                .product(name: "ProjectRulesKit", package: "ProjectRulesKit"),
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
