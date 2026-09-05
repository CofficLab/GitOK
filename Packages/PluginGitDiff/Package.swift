// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitDiff",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "PluginGitDiff", targets: ["PluginGitDiff"]),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderRootView"),
        .package(url: "https://github.com/nookery/MagicDiffView", branch: "main"),
    ],
    targets: [
        .target(
            name: "PluginGitDiff",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderRootView", package: "ProviderRootView"),
                .product(name: "MagicDiffView", package: "MagicDiffView"),
            ],
            path: "Sources/PluginGitDiff"
        ),
        .testTarget(
            name: "PluginGitDiffTests",
            dependencies: ["PluginGitDiff"],
            path: "Tests/PluginGitDiffTests"
        ),
    ]
)
