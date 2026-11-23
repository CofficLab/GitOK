// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitDiff",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "PluginGitDiff", targets: ["PluginGitDiff"]),
    ],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/lumi-softworks/LumiKernel.git", from: "1.1.2"),
        .package(path: "../KitGit"),
        .package(url: "https://github.com/lumi-softworks/LumiLogging.git", from: "1.0.3"),
        .package(url: "https://github.com/lumi-softworks/LumiUI.git", from: "1.19.3"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderGit"),
        .package(path: "../ProviderRootView"),
        .package(url: "https://github.com/nookery/MagicDiffView", branch: "main"),
        .package(url: "https://github.com/lumi-softworks/LumiProviders.git", from: "1.27.0")
    ],
    targets: [
        .target(
            name: "PluginGitDiff",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "GitOKProviderRootView", package: "ProviderRootView"),
                .product(name: "ProviderRootView", package: "LumiProviders"),
                .product(name: "MagicDiffView", package: "MagicDiffView"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
            ],
            path: "Sources/PluginGitDiff",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginGitDiffTests",
            dependencies: [
                "PluginGitDiff",
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderRootView", package: "LumiProviders"),
            ],
            path: "Tests/PluginGitDiffTests"
        ),
    ]
)
