// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginStatusBar",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginStatusBar",
            targets: ["PluginStatusBar"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderStatusBar"),
        .package(path: "../ProviderTheme"),
    ],
    targets: [
        .target(
            name: "PluginStatusBar",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderStatusBar", package: "ProviderStatusBar"),
                .product(name: "ProviderTheme", package: "ProviderTheme"),
            ],
            path: "Sources/PluginStatusBar"
        ),
        .testTarget(
            name: "PluginStatusBarTests",
            dependencies: [
                "PluginStatusBar",
                .product(name: "ProviderStatusBar", package: "ProviderStatusBar"),
            ],
            path: "Tests/PluginStatusBarTests"
        ),
    ]
)
