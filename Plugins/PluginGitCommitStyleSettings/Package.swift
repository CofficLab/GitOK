// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitCommitStyleSettings",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitCommitStyleSettings", targets: ["GitCommitStyleSettingsPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/GitOKAppCore"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/KitGitOKSupport"),
    ],
    targets: [
        .target(
            name: "GitCommitStyleSettingsPlugin",
            dependencies: [
                "KitGitOKCore",
                "GitOKAppCore",
                "GitOKUI",
                "KitGitOKSupport",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "GitCommitStyleSettingsPluginTests",
            dependencies: ["GitCommitStyleSettingsPlugin"],
            path: "Tests"
        ),
    ]
)
