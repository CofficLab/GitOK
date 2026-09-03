// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitUnpushedStatus",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginGitUnpushedStatus",
            targets: ["PluginGitUnpushedStatus"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitSuperLog"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderStatusBar"),
    ],
    targets: [
        .target(
            name: "PluginGitUnpushedStatus",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderStatusBar", package: "ProviderStatusBar"),
            ],
            path: "Sources/PluginGitUnpushedStatus"
        ),
        .testTarget(
            name: "PluginGitUnpushedStatusTests",
            dependencies: ["PluginGitUnpushedStatus"],
            path: "Tests/PluginGitUnpushedStatusTests"
        ),
    ]
)
