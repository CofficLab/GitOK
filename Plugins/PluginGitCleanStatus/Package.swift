// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitCleanStatus",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitCleanStatus", targets: ["GitCleanStatusPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitCore"),
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "GitCleanStatusPlugin",
            dependencies: [
                "KitGitCore",
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitCleanStatusPluginTests",
            dependencies: ["GitCleanStatusPlugin"],
            path: "Tests"
        ),
    ]
)
