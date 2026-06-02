// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BannerPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "BannerPlugin", targets: ["BannerPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/BannerCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/MagicAlert"),
        .package(path: "../../Packages/GitOKSupportKit"),
        .package(path: "../../Packages/ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "BannerPlugin",
            dependencies: [
                "BannerCoreKit",
                "GitOKCoreKit",
                "MagicAlert",
                "GitOKSupportKit",
                "ProjectRulesKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "BannerPluginTests",
            dependencies: ["BannerPlugin"],
            path: "Tests"
        ),
    ]
)
