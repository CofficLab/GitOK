// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitAutoPush",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitAutoPush", targets: ["GitAutoPushPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitCore"),
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/KitProjectRules"),
        .package(path: "../../Packages/KitProjectSupport"),
    ],
    targets: [
        .target(
            name: "GitAutoPushPlugin",
            dependencies: [
                "KitGitCore",
                "KitGitOKCore",
                "KitProjectRules",
                "KitProjectSupport",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitAutoPushPluginTests",
            dependencies: ["GitAutoPushPlugin"],
            path: "Tests"
        ),
    ]
)
