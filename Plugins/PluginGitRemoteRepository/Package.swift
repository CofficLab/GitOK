// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitRemoteRepository",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitRemoteRepository", targets: ["GitRemoteRepositoryPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitCore"),
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/KitProjectRules"),
    ],
    targets: [
        .target(
            name: "GitRemoteRepositoryPlugin",
            dependencies: [
                "KitGitCore",
                "KitGitOKCore",
                "KitProjectRules",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitRemoteRepositoryPluginTests",
            dependencies: ["GitRemoteRepositoryPlugin"],
            path: "Tests"
        ),
    ]
)
