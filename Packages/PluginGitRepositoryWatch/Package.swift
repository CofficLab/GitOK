// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitRepositoryWatch",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginGitRepositoryWatch",
            targets: ["PluginGitRepositoryWatch"]
        ),
    ],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/lumi-softworks/LumiKernel.git", from: "1.1.2"),
        .package(url: "https://github.com/lumi-softworks/LumiLogging.git", from: "1.0.3"),
        .package(path: "../ProviderGitRepositoryWatch"),
        .package(path: "../ProviderProjects"),
        .package(path: "../KitGit"),
        .package(url: "https://github.com/lumi-softworks/LumiUI.git", from: "1.19.3"),
        .package(url: "https://github.com/lumi-softworks/LumiProviders.git", from: "1.27.0")
    ],
    targets: [
        .target(
            name: "PluginGitRepositoryWatch",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "LumiUI", package: "LumiUI"),
            ],
            path: "Sources/PluginGitRepositoryWatch",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginGitRepositoryWatchTests",
            dependencies: [
                "PluginGitRepositoryWatch",
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
            ],
            path: "Tests/PluginGitRepositoryWatchTests"
        ),
    ]
)
