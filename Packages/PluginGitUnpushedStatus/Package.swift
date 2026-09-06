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
        .package(path: "../KitLocalization"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderGit"),
        .package(path: "../ProviderStatusBar"),
        .package(path: "../ProviderWorkspaceScene"),
        .package(path: "../ProviderDocsView"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
    ],
    targets: [
        .target(
            name: "PluginGitUnpushedStatus",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderStatusBar", package: "ProviderStatusBar"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
                .product(name: "ProviderDocsView", package: "ProviderDocsView"),
                .product(name: "LumiUI", package: "LumiUI"),
            ],
            path: "Sources/PluginGitUnpushedStatus",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginGitUnpushedStatusTests",
            dependencies: ["PluginGitUnpushedStatus"],
            path: "Tests/PluginGitUnpushedStatusTests"
        ),
    ]
)
