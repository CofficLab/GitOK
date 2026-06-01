// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeAurora",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginThemeAurora",
            targets: ["PluginThemeAurora"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginThemeAurora",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources/PluginThemeAurora",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeAuroraTests",
            dependencies: ["PluginThemeAurora"],
            path: "Tests"
        ),
    ]
)
