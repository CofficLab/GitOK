// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginBannerTab",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginBannerTab", targets: ["PluginBannerTab"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKPluginKit"),
    ],
    targets: [
        .target(
            name: "PluginBannerTab",
            dependencies: ["GitOKPluginKit"],
            path: "Sources/PluginBannerTab",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginBannerTabTests",
            dependencies: ["PluginBannerTab"],
            path: "Tests/PluginBannerTabTests"
        ),
    ]
)
