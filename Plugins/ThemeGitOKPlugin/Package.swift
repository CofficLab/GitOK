// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeGitOKPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "ThemeGitOKPlugin",
            targets: ["ThemeGitOKPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ThemeGitOKPlugin",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "ThemeGitOKPluginTests",
            dependencies: ["ThemeGitOKPlugin"],
            path: "Tests"
        ),
    ]
)
