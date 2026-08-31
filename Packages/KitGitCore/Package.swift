// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KitGitCore",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "KitGitCore",
            targets: ["KitGitCore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/nookery/LibGit2Swift.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "KitGitCore",
            dependencies: [
                .product(name: "LibGit2Swift", package: "LibGit2Swift"),
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "KitGitCoreTests",
            dependencies: ["KitGitCore"],
            path: "Tests"
        ),
    ]
)
