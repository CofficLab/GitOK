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
        .package(path: "../../Packages/GitOKPluginKit"),
        .package(path: "../../Packages/BannerCoreKit"),
        .package(path: "../../Packages/MagicAlert"),
        .package(path: "../../Packages/MagicKit"),
        .package(path: "../../Packages/ProjectRulesKit"),
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
            path: "Tests"
        ),
    ]
)
