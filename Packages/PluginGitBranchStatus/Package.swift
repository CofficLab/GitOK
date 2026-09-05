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
        .package(path: "../KitLocalization"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderStatusBar"),
        .package(path: "../ProviderToolbar"),
        .package(path: "../ProviderWorkspaceScene"),
    ],
    targets: [
        .target(
            name: "PluginGitBranchStatus",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderStatusBar", package: "ProviderStatusBar"),
                .product(name: "ProviderToolbar", package: "ProviderToolbar"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
            ],
            path: "Sources/PluginGitBranchStatus",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginGitBranchStatusTests",
            dependencies: ["PluginGitBranchStatus"],
            path: "Tests/PluginGitBranchStatusTests"
        ),
    ]
)
