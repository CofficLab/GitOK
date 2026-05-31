// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeEmber",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginThemeEmber",
            targets: ["PluginThemeEmber"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "PluginThemeEmber",
            dependencies: [
                "GitOKCoreKit",
                "GitOKUI",
            ],
            path: "Sources/PluginThemeEmber",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeEmberTests",
            dependencies: ["PluginThemeEmber"],
            path: "Tests"
        ),
    ]
)
