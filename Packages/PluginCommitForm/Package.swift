// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginCommitForm",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginCommitForm",
            targets: ["PluginCommitForm"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(path: "../KitGit"),
        .package(url: "https://github.com/CofficLab/LumiLocalization.git", from: "1.0.0"),
        .package(url: "https://github.com/CofficLab/LumiLogging.git", from: "1.0.1"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.7.0"),
        .package(path: "../ProviderCommitForm"),
        .package(path: "../ProviderCoAuthor"),
        .package(path: "../ProviderGit"),
        .package(path: "../ProviderContentView"),
        .package(path: "../ProviderGitRepositoryWatch"),
        .package(path: "../ProviderGitUser"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderRootView"),
        .package(path: "../ProviderWorkspaceScene"),
        .package(path: "../ProviderDocsView"),
    ],
    targets: [
        .target(
            name: "PluginCommitForm",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "LumiLocalizationKit", package: "LumiLocalization"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderCommitForm", package: "ProviderCommitForm"),
                .product(name: "ProviderCoAuthor", package: "ProviderCoAuthor"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderContentView", package: "ProviderContentView"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
                .product(name: "ProviderGitUser", package: "ProviderGitUser"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderRootView", package: "ProviderRootView"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
                .product(name: "ProviderDocsView", package: "ProviderDocsView"),
            ],
            path: "Sources/PluginCommitForm",
            resources: [
                .process("../../Resources/Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "PluginCommitFormTests",
            dependencies: [
                "PluginCommitForm",
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
            ],
            path: "Tests/PluginCommitFormTests"
        ),
    ]
)
