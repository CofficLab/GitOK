// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitConflictResolver",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitConflictResolver", targets: ["GitConflictResolverPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitCore"),
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "GitConflictResolverPlugin",
            dependencies: [
                "KitGitCore",
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitConflictResolverPluginTests",
            dependencies: ["GitConflictResolverPlugin"],
            path: "Tests"
        ),
    ]
)
