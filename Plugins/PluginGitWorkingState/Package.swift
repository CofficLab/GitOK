// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitWorkingState",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitWorkingState", targets: ["GitWorkingStatePlugin"]),
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
    ],
    targets: [
        .target(
            name: "GitWorkingStatePlugin",
            dependencies: [
                "KitGitCore",
                "GitOKAppCore",
                "KitGitOKCore",
                "KitGitOKSupport",
                "GitOKUI",
                "MagicAlert",
                "KitProjectRules",
                "KitProjectSupport",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "GitWorkingStatePluginTests",
            dependencies: ["GitWorkingStatePlugin"],
            path: "Tests"
        ),
    ]
)
