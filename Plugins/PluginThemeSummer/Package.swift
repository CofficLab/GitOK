// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeSummer",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginThemeSummer",
            targets: ["PluginThemeSummer"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginThemeSummer",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeSummerTests",
            dependencies: ["PluginThemeSummer"],
            path: "Tests"
        ),
    ]
)

