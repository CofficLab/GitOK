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
        .package(path: "../ProviderGit"),
        .package(
            url: "https://github.com/nookery/LibGit2Swift.git",
            revision: "7005a7383c4b29a91da418bf24a534992ff5cf27"
        ),
    ],
    targets: [
        .target(
            name: "PluginGitLibGit2",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "LibGit2Swift", package: "libgit2swift"),
            ],
            path: "Sources/PluginGitLibGit2"
        ),
        .testTarget(
            name: "PluginGitLibGit2Tests",
            dependencies: ["PluginGitLibGit2"],
            path: "Tests/PluginGitLibGit2Tests"
        ),
    ]
)
