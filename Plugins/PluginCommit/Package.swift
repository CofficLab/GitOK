// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginCommit",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginCommit", targets: ["PluginCommit"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginCommit",
            dependencies: ["GitOKCoreKit"],
            path: "Sources"
        ),
        .testTarget(
            name: "PluginCommitTests",
            dependencies: ["PluginCommit"],
            path: "Tests"
        ),
    ]
)
