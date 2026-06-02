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
        .package(path: "../../Packages/GitOKSupportKit"),
    ],
    targets: [
        .target(
            name: "OpenGitHubDesktopPlugin",
            dependencies: [
                "GitOKCoreKit",
                .product(name: "GitOKDesignKit", package: "GitOKSupportKit"),
            ],
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
