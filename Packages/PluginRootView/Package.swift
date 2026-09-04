// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginRootView",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.library(name: "PluginRootView", targets: ["PluginRootView"])],
    dependencies: [
        .package(path: "../KitSuperLog"),
        .package(path: "../KernelCore"),
        .package(path: "../ProviderRootView"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderCloneRepository"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "PluginRootView",
            dependencies: [
                "KitSuperLog",
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "ProviderRootView", package: "ProviderRootView"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderCloneRepository", package: "ProviderCloneRepository"),
                .product(name: "LumiUI", package: "LumiUI"),
            ],
            path: "Sources/PluginRootView"
        ),
        .testTarget(
            name: "PluginRootViewTests",
            dependencies: [
                "PluginRootView",
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "ProviderRootView", package: "ProviderRootView"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
            ],
            path: "Tests/PluginRootViewTests"
        ),
    ]
)
