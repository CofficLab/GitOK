// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeXcodeLight",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginThemeXcodeLight",
            targets: ["PluginThemeXcodeLight"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginThemeXcodeLight",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeXcodeLightTests",
            dependencies: ["PluginThemeXcodeLight"],
            path: "Tests"
        ),
    ]
)

