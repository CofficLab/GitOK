// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginPluginManager",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginPluginManager",
            targets: ["PluginPluginManager"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitSuperLog"),
        .package(path: "../LumiUI"),
        .package(path: "../ProviderSettingView"),
    ],
    targets: [
        .target(
            name: "PluginPluginManager",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderSettingView", package: "ProviderSettingView"),
            ],
            path: "Sources/PluginPluginManager"
        ),
        .testTarget(
            name: "PluginPluginManagerTests",
            dependencies: ["PluginPluginManager"],
            path: "Tests/PluginPluginManagerTests"
        ),
    ]
)
