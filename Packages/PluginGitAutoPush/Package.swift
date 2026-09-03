// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitAutoPush",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginGitAutoPush",
            targets: ["PluginGitAutoPush"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", branch: "main"),
        .package(path: "../ProviderAutoPush"),
        .package(path: "../ProviderCommitForm"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderStatusBar"),
        .package(path: "../ProviderStorage"),
    ],
    targets: [
        .target(
            name: "PluginGitAutoPush",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderAutoPush", package: "ProviderAutoPush"),
                .product(name: "ProviderCommitForm", package: "ProviderCommitForm"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderStatusBar", package: "ProviderStatusBar"),
                .product(name: "ProviderStorage", package: "ProviderStorage"),
            ],
            path: "Sources/PluginGitAutoPush"
        ),
        .testTarget(
            name: "PluginGitAutoPushTests",
            dependencies: ["PluginGitAutoPush"],
            path: "Tests/PluginGitAutoPushTests"
        ),
    ]
)
