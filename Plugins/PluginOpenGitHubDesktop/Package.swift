// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenGitHubDesktop",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginOpenGitHubDesktop",
            targets: ["OpenGitHubDesktopPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/KitGitOKSupport"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "OpenGitHubDesktopPlugin",
            dependencies: [
                "KitGitOKCore",
                .product(name: "KitGitOKDesign", package: "KitGitOKSupport"),
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
