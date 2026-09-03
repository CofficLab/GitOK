// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginFileInfo",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginFileInfo",
            targets: ["PluginFileInfo"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", branch: "main"),
        .package(path: "../ProviderCommit"),
        .package(path: "../ProviderStatusBar"),
    ],
    targets: [
        .target(
            name: "PluginFileInfo",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderCommit", package: "ProviderCommit"),
                .product(name: "ProviderStatusBar", package: "ProviderStatusBar"),
            ],
            path: "Sources/PluginFileInfo"
        ),
        .testTarget(
            name: "PluginFileInfoTests",
            dependencies: ["PluginFileInfo"],
            path: "Tests/PluginFileInfoTests"
        ),
    ]
)
