// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitIgnore",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginGitIgnore", targets: ["PluginGitIgnore"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginGitIgnore",
            dependencies: ["GitOKCoreKit"],
            path: "Sources/PluginGitIgnore",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginGitIgnoreTests",
            dependencies: ["PluginGitIgnore"],
            path: "Tests"
        ),
    ]
)
