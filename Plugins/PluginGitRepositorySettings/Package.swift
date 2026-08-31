// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitRepositorySettings",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitRepositorySettings", targets: ["GitRepositorySettingsPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitCore"),
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/GitOKAppCore"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/KitGitOKSupport"),
        .package(path: "../../Packages/KitProjectRules"),
    ],
    targets: [
        .target(
            name: "GitRepositorySettingsPlugin",
            dependencies: [
                "KitGitCore",
                "KitGitOKCore",
                "GitOKAppCore",
                "GitOKUI",
                "KitGitOKSupport",
                "KitProjectRules",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "GitRepositorySettingsPluginTests",
            dependencies: ["GitRepositorySettingsPlugin"],
            path: "Tests"
        ),
    ]
)
