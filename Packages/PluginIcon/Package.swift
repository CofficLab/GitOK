// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginIcon",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginIcon", targets: ["PluginIcon"]),
    ],
    dependencies: [
        .package(path: "../ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "PluginIcon",
            dependencies: [
                .product(name: "ProjectRulesKit", package: "ProjectRulesKit"),
            ],
            path: "Sources/PluginIcon"
        ),
        .testTarget(
            name: "PluginIconTests",
            dependencies: ["PluginIcon"],
            path: "Tests/PluginIconTests"
        ),
    ]
)
