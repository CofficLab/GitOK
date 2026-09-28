// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginActivityHeatmap",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginActivityHeatmap", targets: ["PluginActivityHeatmap"]),
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.1.0"),
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(path: "../KitGit"),
        .package(url: "https://github.com/CofficLab/LumiLogging.git", from: "1.0.1"),
        .package(path: "../ProviderActivityHeatmap"),
        .package(path: "../ProviderGit"),
        .package(path: "../ProviderGitRepositoryWatch"),
        .package(path: "../ProviderProjects"),
    ],
    targets: [
        .target(
            name: "PluginActivityHeatmap",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "ProviderActivityHeatmap", package: "ProviderActivityHeatmap"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderStorage", package: "LumiProviders"),
            ],
            path: "Sources/PluginActivityHeatmap"
        ),
        .testTarget(
            name: "PluginActivityHeatmapTests",
            dependencies: [
                "PluginActivityHeatmap",
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "ProviderActivityHeatmap", package: "ProviderActivityHeatmap"),
            ],
            path: "Tests/PluginActivityHeatmapTests"
        ),
    ]
)
