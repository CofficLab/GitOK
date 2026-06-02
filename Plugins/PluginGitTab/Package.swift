// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitTab",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginGitTab", targets: ["PluginGitTab"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginGitTab",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginGitTabTests",
            dependencies: ["PluginGitTab"],
            path: "Tests"
        ),
    ]
)
