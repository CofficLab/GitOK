// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitDetail",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitDetail", targets: ["GitDetailPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitCore"),
        .package(path: "../../Packages/GitOKAppCore"),
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/KitGitOKSupport"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/MagicAlert"),
        .package(path: "../../Packages/KitProjectRules"),
        .package(path: "../../Packages/KitProjectSupport"),
        .package(url: "https://github.com/nookery/MagicDiffView", branch: "main"),
    ],
    targets: [
        .target(
            name: "GitDetailPlugin",
            dependencies: [
                "KitGitCore",
                "GitOKAppCore",
                "KitGitOKCore",
                "KitGitOKSupport",
                "GitOKUI",
                "MagicAlert",
                "KitProjectRules",
                "KitProjectSupport",
                "MagicDiffView",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "GitDetailPluginTests",
            dependencies: ["GitDetailPlugin"],
            path: "Tests"
        ),
    ]
)
