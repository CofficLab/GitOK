// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeGitHubLightPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "ThemeGitHubLightPlugin",
            targets: ["ThemeGitHubLightPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ThemeGitHubLightPlugin",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "ThemeGitHubLightPluginTests",
            dependencies: ["ThemeGitHubLightPlugin"],
            path: "Tests"
        ),
    ]
)
