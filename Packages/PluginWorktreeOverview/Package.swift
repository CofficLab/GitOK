// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginWorktreeOverview",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "PluginWorktreeOverview", targets: ["PluginWorktreeOverview"]),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitLocalization"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
        .package(path: "../ProviderContentView"),
        .package(path: "../ProviderActivityHeatmap"),
        .package(path: "../ProviderProjectLanguages"),
        .package(path: "../ProviderGit"),
        .package(path: "../ProviderGitUser"),
        .package(path: "../ProviderGitRepositoryWatch"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderSettingView"),
        .package(path: "../ProviderWorkspaceScene"),
        .package(path: "../ProviderDocsView"),
    ],
    targets: [
        .target(
            name: "PluginWorktreeOverview",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderContentView", package: "ProviderContentView"),
                .product(name: "ProviderActivityHeatmap", package: "ProviderActivityHeatmap"),
                .product(name: "ProviderProjectLanguages", package: "ProviderProjectLanguages"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderGitUser", package: "ProviderGitUser"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderSettingView", package: "ProviderSettingView"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
                .product(name: "ProviderDocsView", package: "ProviderDocsView"),
            ],
            path: "Sources/PluginWorktreeOverview",
            resources: [
                .process("../../Resources/Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "PluginWorktreeOverviewTests",
            dependencies: [
                "PluginWorktreeOverview",
                .product(name: "ProviderActivityHeatmap", package: "ProviderActivityHeatmap"),
                .product(name: "ProviderGitUser", package: "ProviderGitUser"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
            ],
            path: "Tests/PluginWorktreeOverviewTests"
        ),
    ]
)
