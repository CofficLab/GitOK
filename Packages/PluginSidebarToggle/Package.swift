// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginSidebarToggle",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginSidebarToggle",
            targets: ["PluginSidebarToggle"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", branch: "main"),
        .package(path: "../ProviderRootView"),
        .package(path: "../ProviderToolbar"),
    ],
    targets: [
        .target(
            name: "PluginSidebarToggle",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderRootView", package: "ProviderRootView"),
                .product(name: "ProviderToolbar", package: "ProviderToolbar"),
            ],
            path: "Sources/PluginSidebarToggle"
        ),
        .testTarget(
            name: "PluginSidebarToggleTests",
            dependencies: [
                "PluginSidebarToggle",
                .product(name: "ProviderToolbar", package: "ProviderToolbar"),
            ],
            path: "Tests/PluginSidebarToggleTests"
        ),
    ]
)
