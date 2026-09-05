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
        .package(path: "../KitLocalization"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
        .package(path: "../ProviderRootView"),
        .package(path: "../ProviderToolbar"),
    ],
    targets: [
        .target(
            name: "PluginSidebarToggle",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderRootView", package: "ProviderRootView"),
                .product(name: "ProviderToolbar", package: "ProviderToolbar"),
            ],
            path: "Sources/PluginSidebarToggle",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
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
