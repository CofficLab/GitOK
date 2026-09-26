// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitCLI",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginGitCLI",
            targets: ["PluginGitCLI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(path: "../KitGit"),
        .package(path: "../KitLocalization"),
        .package(path: "../ProviderDocsView"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.7.0"),
        .package(path: "../ProviderGit"),
    ],
    targets: [
        .target(
            name: "PluginGitCLI",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "ProviderDocsView", package: "ProviderDocsView"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderGit", package: "ProviderGit"),
            ],
            path: "Sources/PluginGitCLI",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginGitCLITests",
            dependencies: ["PluginGitCLI"],
            path: "Tests/PluginGitCLITests"
        ),
    ]
)
