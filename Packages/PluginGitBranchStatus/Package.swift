// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitBranchStatus",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginGitBranchStatus",
            targets: ["PluginGitBranchStatus"]
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
            name: "PluginGitBranchStatus",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderStatusBar", package: "ProviderStatusBar"),
            ],
            path: "Sources/PluginGitBranchStatus"
        ),
        .testTarget(
            name: "PluginGitBranchStatusTests",
            dependencies: ["PluginGitBranchStatus"],
            path: "Tests/PluginGitBranchStatusTests"
        ),
    ]
)
