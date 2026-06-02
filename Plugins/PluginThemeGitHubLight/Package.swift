// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeGitHubLight",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginThemeGitHubLight",
            targets: ["PluginThemeGitHubLight"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginThemeGitHubLight",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeGitHubLightTests",
            dependencies: ["PluginThemeGitHubLight"],
            path: "Tests"
        ),
    ]
)
