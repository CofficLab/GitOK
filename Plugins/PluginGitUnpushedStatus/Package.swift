// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitUnpushedStatus",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitUnpushedStatus", targets: ["GitUnpushedStatusPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitCore"),
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "GitUnpushedStatusPlugin",
            dependencies: [
                "KitGitCore",
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitUnpushedStatusPluginTests",
            dependencies: ["GitUnpushedStatusPlugin"],
            path: "Tests"
        ),
    ]
)
