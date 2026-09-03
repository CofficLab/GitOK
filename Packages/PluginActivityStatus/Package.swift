// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginActivityStatus",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginActivityStatus",
            targets: ["PluginActivityStatus"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitSuperLog"),
        .package(path: "../ProviderActivity"),
        .package(path: "../ProviderStatusBar"),
    ],
    targets: [
        .target(
            name: "PluginActivityStatus",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "ProviderActivity", package: "ProviderActivity"),
                .product(name: "ProviderStatusBar", package: "ProviderStatusBar"),
            ],
            path: "Sources/PluginActivityStatus"
        ),
        .testTarget(
            name: "PluginActivityStatusTests",
            dependencies: ["PluginActivityStatus"],
            path: "Tests/PluginActivityStatusTests"
        ),
    ]
)
