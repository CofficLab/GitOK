// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginRailView",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "PluginRailView", targets: ["PluginRailView"]),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitLocalization"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
        .package(path: "../ProviderRailView"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderWorkspaceScene"),
        .package(path: "../ProviderDocsView"),
    ],
    targets: [
        .target(
            name: "PluginRailView",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderRailView", package: "ProviderRailView"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
                .product(name: "ProviderDocsView", package: "ProviderDocsView"),
            ],
            path: "Sources/PluginRailView",
            resources: [
                .process("../../Resources/Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "PluginRailViewTests",
            dependencies: [
                "PluginRailView",
            ],
            path: "Tests/PluginRailViewTests"
        ),
    ]
)
