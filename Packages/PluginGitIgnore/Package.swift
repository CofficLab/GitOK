// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitIgnore",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginGitIgnore",
            targets: ["PluginGitIgnore"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderStatusBar"),
    ],
    targets: [
        .target(
            name: "PluginGitIgnore",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderStatusBar", package: "ProviderStatusBar"),
            ],
            path: "Sources/PluginGitIgnore"
        ),
        .testTarget(
            name: "PluginGitIgnoreTests",
            dependencies: ["PluginGitIgnore"],
            path: "Tests/PluginGitIgnoreTests"
        ),
    ]
)
