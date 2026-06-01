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
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginBanner",
            dependencies: [
                "GitOKCoreKit",
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
