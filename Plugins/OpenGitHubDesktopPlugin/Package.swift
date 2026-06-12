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
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "OpenGitHubDesktopPlugin",
            dependencies: [
                "GitOKCoreKit",
                .product(name: "GitOKDesignKit", package: "GitOKSupportKit"),
                "GitOKUI",
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
