// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeMidnight",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginThemeMidnight",
            targets: ["PluginThemeMidnight"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "PluginThemeMidnight",
            dependencies: [
                "GitOKCoreKit",
                "GitOKUI",
            ],
            path: "Sources/PluginThemeMidnight",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeMidnightTests",
            dependencies: ["PluginThemeMidnight"],
            path: "Tests"
        ),
    ]
)
