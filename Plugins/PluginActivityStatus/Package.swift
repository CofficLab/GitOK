// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginActivityStatus",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginActivityStatus", targets: ["ActivityStatusPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "ActivityStatusPlugin",
            dependencies: ["KitGitOKCore"],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "ActivityStatusPluginTests",
            dependencies: ["ActivityStatusPlugin"],
            path: "Tests"
        ),
    ]
)
