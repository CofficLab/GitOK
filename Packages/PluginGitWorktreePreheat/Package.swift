// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitWorktreePreheat",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginGitWorktreePreheat",
            targets: ["PluginGitWorktreePreheat"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(path: "../KitGit"),
        .package(path: "../KitSuperLog"),
        .package(path: "../ProviderGit"),
        .package(path: "../ProviderGitRepositoryWatch"),
        .package(path: "../ProviderProjects"),
    ],
    targets: [
        .target(
            name: "PluginGitWorktreePreheat",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
            ],
            path: "Sources/PluginGitWorktreePreheat"
        ),
        .testTarget(
            name: "PluginGitWorktreePreheatTests",
            dependencies: [
                "PluginGitWorktreePreheat",
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
            ],
            path: "Tests/PluginGitWorktreePreheatTests"
        ),
    ]
)
