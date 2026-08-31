// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitBranch",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitBranch", targets: ["GitBranchPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitCore"),
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/GitOKAppCore"),
        .package(path: "../../Packages/KitProjectRules"),
    ],
    targets: [
        .target(
            name: "GitBranchPlugin",
            dependencies: [
                "KitGitCore",
                "KitGitOKCore",
                "KitProjectRules",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitBranchPluginTests",
            dependencies: [
                "GitBranchPlugin",
                "GitOKAppCore",
            ],
            path: "Tests"
        ),
    ]
)
