// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenIn",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginOpenIn",
            targets: ["PluginOpenIn"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitSuperLog"),
        .package(path: "../LumiUI"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderToolbar"),
    ],
    targets: [
        .target(
            name: "PluginOpenIn",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderToolbar", package: "ProviderToolbar"),
            ],
            path: "Sources/PluginOpenIn"
        ),
        .testTarget(
            name: "PluginOpenInTests",
            dependencies: [
                "PluginOpenIn",
                .product(name: "ProviderToolbar", package: "ProviderToolbar"),
            ],
            path: "Tests/PluginOpenInTests"
        ),
    ]
)
