// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitWatcherPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitWatcherPlugin", targets: ["GitWatcherPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "GitWatcherPlugin",
            dependencies: ["GitOKCoreKit"],
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
