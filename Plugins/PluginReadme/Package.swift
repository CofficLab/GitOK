// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginReadme",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginReadme", targets: ["ReadmePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/KitProjectSupport"),
    ],
    targets: [
        .target(
            name: "ReadmePlugin",
            dependencies: [
                "KitGitOKCore",
                "KitProjectSupport",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "ReadmePluginTests",
            dependencies: [
                "ReadmePlugin",
                "KitProjectSupport",
            ],
            path: "Tests"
        ),
    ]
)
