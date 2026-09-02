// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginSidebar",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginSidebar",
            targets: ["PluginSidebar"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitLocalization"),
        .package(path: "../KitSuperLog"),
        .package(path: "../LumiUI"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderSettingView"),
        .package(path: "../ProviderSidebar"),
    ],
    targets: [
        .target(
            name: "PluginSidebar",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderSettingView", package: "ProviderSettingView"),
                .product(name: "ProviderSidebar", package: "ProviderSidebar"),
            ],
            path: "Sources/PluginSidebar",
            resources: [.process("../../Resources/Localizable.xcstrings")]
        ),
        .testTarget(
            name: "PluginSidebarTests",
            dependencies: [
                "PluginSidebar",
                .product(name: "ProviderProjects", package: "ProviderProjects"),
            ],
            path: "Tests/PluginSidebarTests"
        ),
    ]
)
