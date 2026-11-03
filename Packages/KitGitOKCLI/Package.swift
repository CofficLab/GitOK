// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KitGitOKCLI",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "KitGitOKCLI",
            targets: ["KitGitOKCLI"]
        ),
    ],
    targets: [
        .target(
            name: "KitGitOKCLI",
            path: "Sources/KitGitOKCLI"
        ),
        .testTarget(
            name: "KitGitOKCLITests",
            dependencies: ["KitGitOKCLI"],
            path: "Tests/KitGitOKCLITests"
        ),
    ]
)
