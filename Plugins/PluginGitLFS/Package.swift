// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitLFS",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitLFS", targets: ["GitLFSPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitCore"),
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "GitLFSPlugin",
            dependencies: [
                "KitGitCore",
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitLFSPluginTests",
            dependencies: ["GitLFSPlugin"],
            path: "Tests"
        ),
    ]
)
