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
        .package(path: "../ProviderGit"),
        .package(path: "../KitSuperLog"),
        .package(path: "../KitLocalization"),
        .package(path: "../ProviderGitRepositoryWatch"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderStatusBar"),
        .package(path: "../ProviderToolbar"),
        .package(path: "../ProviderWorkspaceScene"),
        .package(path: "../ProviderDocsView"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
    ],
    targets: [
        .target(
            name: "PluginGitBranchStatus",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderStatusBar", package: "ProviderStatusBar"),
                .product(name: "ProviderToolbar", package: "ProviderToolbar"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
                .product(name: "ProviderDocsView", package: "ProviderDocsView"),
                .product(name: "LumiUI", package: "LumiUI"),
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
