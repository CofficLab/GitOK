// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginCommitStatusBar",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.library(name: "PluginCommitStatusBar", targets: ["PluginCommitStatusBar"])],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderStatusBar"),
    ],
    targets: [
        .target(
            name: "PluginCommitStatusBar",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                "KitSuperLog",
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderStatusBar", package: "ProviderStatusBar"),
            ],
            path: "Sources/PluginCommitStatusBar"
        ),
        .testTarget(
            name: "PluginCommitStatusBarTests",
            dependencies: [
                "PluginCommitStatusBar",
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderStatusBar", package: "ProviderStatusBar"),
            ],
            path: "Tests/PluginCommitStatusBarTests"
        ),
    ]
)
