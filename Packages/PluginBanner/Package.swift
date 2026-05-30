// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginBanner",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginBanner", targets: ["PluginBanner"]),
    ],
    dependencies: [
        .package(path: "../GitOKPluginKit"),
        .package(path: "../BannerCoreKit"),
        .package(path: "../MagicAlert"),
        .package(path: "../MagicKit"),
        .package(path: "../ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "PluginBanner",
            dependencies: [
                "GitOKPluginKit",
                "BannerCoreKit",
                "MagicAlert",
                "MagicKit",
                "ProjectRulesKit",
            ],
            path: "Sources/PluginBanner",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginBannerTests",
            dependencies: ["PluginBanner"],
            path: "Tests/PluginBannerTests"
        ),
    ]
)
