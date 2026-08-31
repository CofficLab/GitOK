// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitSmartMerge",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitSmartMerge", targets: ["GitSmartMergePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitCore"),
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "GitSmartMergePlugin",
            dependencies: [
                "KitGitCore",
                "KitGitOKCore",
                "GitOKUI",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitSmartMergePluginTests",
            dependencies: ["GitSmartMergePlugin"],
            path: "Tests"
        ),
    ]
)
