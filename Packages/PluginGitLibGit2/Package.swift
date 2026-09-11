// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitLibGit2",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitLibGit2", targets: ["PluginGitLibGit2"]),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitLocalization"),
        .package(path: "../ProviderDocsView"),
        .package(path: "../ProviderGit"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
        .package(
            url: "https://github.com/nookery/LibGit2Swift.git",
            revision: "64b21cf6bbcf0fe4ab20382a5e7138f58283bb16"
        ),
    ],
    targets: [
        .target(
            name: "PluginGitLibGit2",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "ProviderDocsView", package: "ProviderDocsView"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "LibGit2Swift", package: "libgit2swift"),
            ],
            path: "Sources/PluginGitLibGit2",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginGitLibGit2Tests",
            dependencies: ["PluginGitLibGit2"],
            path: "Tests/PluginGitLibGit2Tests"
        ),
    ]
)
