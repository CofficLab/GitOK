// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginBranch",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginBranch", targets: ["PluginBranch"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "PluginBranch",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
                "ProjectRulesKit",
            ],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginBranchTests",
            dependencies: ["PluginBranch"],
            path: "Tests"
        ),
    ]
)
