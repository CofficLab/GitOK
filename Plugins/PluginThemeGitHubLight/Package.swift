// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeGitHubLight",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginThemeGitHubLight",
            targets: ["ThemeGitHubLightPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "ThemeGitHubLightPlugin",
            dependencies: [
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeGitHubLightPluginTests",
            dependencies: ["ThemeGitHubLightPlugin"],
            path: "Tests"
        ),
    ]
)
