// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitIgnore",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitIgnore", targets: ["GitIgnorePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "GitIgnorePlugin",
            dependencies: ["KitGitOKCore"],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitIgnorePluginTests",
            dependencies: ["GitIgnorePlugin"],
            path: "Tests"
        ),
    ]
)
