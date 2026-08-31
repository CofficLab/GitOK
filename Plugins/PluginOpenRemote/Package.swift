// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenRemote",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "PluginOpenRemote", targets: ["OpenRemotePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/KitGitOKSupport"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/KitProjectRules"),
    ],
    targets: [
        .target(
            name: "OpenRemotePlugin",
            dependencies: [
                "KitGitOKCore",
                .product(name: "KitGitOKDesign", package: "KitGitOKSupport"),
                "GitOKUI",
                "KitProjectRules",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "OpenRemotePluginTests",
            dependencies: ["OpenRemotePlugin"],
            path: "Tests"
        ),
    ]
)
