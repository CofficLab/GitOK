// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitClone",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginGitClone", targets: ["PluginGitClone"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginGitClone",
            dependencies: ["GitOKCoreKit"],
            path: "Sources/PluginGitClone",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginGitCloneTests",
            dependencies: ["PluginGitClone"],
            path: "Tests"
        ),
    ]
)
