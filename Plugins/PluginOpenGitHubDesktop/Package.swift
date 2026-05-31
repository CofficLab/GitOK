// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenGitHubDesktop",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginOpenGitHubDesktop",
            targets: ["PluginOpenGitHubDesktop"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKPluginKit"),
    ],
    targets: [
        .target(
            name: "PluginOpenGitHubDesktop",
            dependencies: ["GitOKPluginKit"],
            path: "Sources/PluginOpenGitHubDesktop",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginOpenGitHubDesktopTests",
            dependencies: ["PluginOpenGitHubDesktop"],
            path: "Tests/PluginOpenGitHubDesktopTests"
        ),
    ]
)
