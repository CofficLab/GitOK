// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitWatcher",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginGitWatcher", targets: ["PluginGitWatcher"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginGitWatcher",
            dependencies: ["GitOKCoreKit"],
            path: "Sources/PluginGitWatcher",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginGitWatcherTests",
            dependencies: ["PluginGitWatcher"],
            path: "Tests"
        ),
    ]
)
