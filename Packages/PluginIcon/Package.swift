// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginIcon",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginIcon", targets: ["PluginIcon"]),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../ProjectRulesKit"),
        .package(path: "../ProviderContentView"),
        .package(path: "../ProviderProjects"),
    ],
    targets: [
        .target(
            name: "PluginIcon",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "ProjectRulesKit", package: "ProjectRulesKit"),
                .product(name: "ProviderContentView", package: "ProviderContentView"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
            ],
            path: "Sources/PluginIcon",
            resources: [
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
