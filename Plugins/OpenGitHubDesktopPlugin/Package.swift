// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenGitHubDesktopPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "OpenGitHubDesktopPlugin",
            targets: ["OpenGitHubDesktopPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "OpenGitHubDesktopPlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "OpenGitHubDesktopPluginTests",
            dependencies: ["OpenGitHubDesktopPlugin"],
            path: "Tests"
        ),
    ]
)
