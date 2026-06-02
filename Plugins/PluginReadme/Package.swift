// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginReadme",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginReadme", targets: ["PluginReadme"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginReadme",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginReadmeTests",
            dependencies: ["PluginReadme"],
            path: "Tests"
        ),
    ]
)
