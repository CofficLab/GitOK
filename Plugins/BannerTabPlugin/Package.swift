// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BannerTabPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "BannerTabPlugin", targets: ["BannerTabPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "BannerTabPlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "BannerTabPluginTests",
            dependencies: ["BannerTabPlugin"],
            path: "Tests"
        ),
    ]
)
