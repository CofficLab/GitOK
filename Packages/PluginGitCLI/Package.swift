// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitCLI",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginGitCLI",
            targets: ["PluginGitCLI"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../ProviderGit"),
    ],
    targets: [
        .target(
            name: "PluginGitCLI",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "ProviderGit", package: "ProviderGit"),
            ],
            path: "Sources/PluginGitCLI"
        ),
        .testTarget(
            name: "PluginGitCLITests",
            dependencies: ["PluginGitCLI"],
            path: "Tests/PluginGitCLITests"
        ),
    ]
)
