// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitSubmodule",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitSubmodule", targets: ["GitSubmodulePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitCore"),
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "GitSubmodulePlugin",
            dependencies: [
                "KitGitCore",
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitSubmodulePluginTests",
            dependencies: [
                "KitGitCore",
                "GitSubmodulePlugin",
            ],
            path: "Tests"
        ),
    ]
)
