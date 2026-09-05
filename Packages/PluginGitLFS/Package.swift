// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitLFS",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginGitLFS",
            targets: ["PluginGitLFS"]
        ),
    ],
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
            name: "PluginGitLFS",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderStatusBar", package: "ProviderStatusBar"),
            ],
            path: "Sources/PluginGitLFS"
        ),
        .testTarget(
            name: "PluginGitLFSTests",
            dependencies: ["PluginGitLFS"],
            path: "Tests/PluginGitLFSTests"
        ),
    ]
)
