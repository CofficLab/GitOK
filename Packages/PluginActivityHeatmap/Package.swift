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
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitSuperLog"),
        .package(path: "../ProviderActivityHeatmap"),
        .package(path: "../ProviderGit"),
        .package(path: "../ProviderGitRepositoryWatch"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderStorage"),
    ],
    targets: [
        .target(
            name: "PluginActivityHeatmap",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "ProviderActivityHeatmap", package: "ProviderActivityHeatmap"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderStorage", package: "ProviderStorage"),
            ],
            path: "Sources/PluginActivityHeatmap"
        ),
        .testTarget(
            name: "PluginActivityHeatmapTests",
            dependencies: [
                "PluginActivityHeatmap",
                .product(name: "KitGit", package: "KitGit"),
            ],
            path: "Tests/PluginActivityHeatmapTests"
        ),
    ]
)
