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
        .package(path: "../../Packages/GitOKPluginKit"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "PluginThemeGitHubLight",
            dependencies: [
                "GitOKPluginKit",
                "GitOKUI",
            ],
            path: "Sources/PluginThemeGitHubLight",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeGitHubLightTests",
            dependencies: ["PluginThemeGitHubLight"],
            path: "Tests/PluginThemeGitHubLightTests"
        ),
    ]
)
