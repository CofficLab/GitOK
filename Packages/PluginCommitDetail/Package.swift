// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginCommitDetail",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "PluginCommitDetail", targets: ["PluginCommitDetail"]),
    ],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/lumi-softworks/LumiKernel.git", from: "1.1.2"),
        .package(path: "../KitGit"),
        .package(url: "https://github.com/lumi-softworks/LumiLogging.git", from: "1.0.3"),
        .package(url: "https://github.com/lumi-softworks/LumiUI.git", from: "1.19.3"),
        .package(path: "../ProviderGit"),
        .package(path: "../ProviderGitRepositoryWatch"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderWorkspaceScene"),
        .package(url: "https://github.com/lumi-softworks/LumiProviders.git", from: "1.27.0")
    ],
    targets: [
        .target(
            name: "PluginCommitDetail",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderContentView", package: "LumiProviders"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
            ],
            path: "Sources/PluginCommitDetail",
            resources: [
                .process("../../Resources/Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "PluginCommitDetailTests",
            dependencies: [
                "PluginCommitDetail",
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
            ],
            path: "Tests/PluginCommitDetailTests"
        ),
    ]
)
