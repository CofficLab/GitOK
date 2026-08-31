// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitStash",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitStash", targets: ["GitStashPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitCore"),
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "GitStashPlugin",
            dependencies: [
                "KitGitCore",
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitStashPluginTests",
            dependencies: [
                "KitGitCore",
                "GitStashPlugin",
            ],
            path: "Tests"
        ),
    ]
)
