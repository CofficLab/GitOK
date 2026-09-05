// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginIcon",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginIcon", targets: ["PluginIcon"]),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGitOKSupport"),
        .package(path: "../KitLocalization"),
        .package(path: "../ProjectRulesKit"),
        .package(path: "../ProviderContentView"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderWorkspaceScene"),
    ],
    targets: [
        .target(
            name: "PluginIcon",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGitOKSupport", package: "KitGitOKSupport"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "ProjectRulesKit", package: "ProjectRulesKit"),
                .product(name: "ProviderContentView", package: "ProviderContentView"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
            ],
            path: "Sources/PluginIcon",
            resources: [
                .process("../../Resources/Localizable.xcstrings"),
                .process("../../Resources/Icons")
            ]
        ),
        .testTarget(
            name: "PluginIconTests",
            dependencies: ["PluginIcon"],
            path: "Tests/PluginIconTests"
        ),
    ]
)
