// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginIcon",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginIcon", targets: ["PluginIcon"]),
    ],
    dependencies: [
        .package(path: "../GitOKPluginKit"),
        .package(path: "../MagicAlert"),
        .package(path: "../MagicKit"),
        .package(path: "../ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "PluginIcon",
            dependencies: [
                "GitOKPluginKit",
                "MagicAlert",
                "MagicKit",
                "ProjectRulesKit",
            ],
            path: "Sources/PluginIcon",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginIconTests",
            dependencies: ["PluginIcon"],
            path: "Tests/PluginIconTests"
        ),
    ]
)
