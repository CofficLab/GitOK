// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitWatcher",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitWatcher", targets: ["GitWatcherPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "GitWatcherPlugin",
            dependencies: ["KitGitOKCore"],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitWatcherPluginTests",
            dependencies: ["GitWatcherPlugin"],
            path: "Tests"
        ),
    ]
)
