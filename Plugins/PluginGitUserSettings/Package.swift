// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitUserSettings",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitUserSettings", targets: ["GitUserSettingsPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/GitOKAppCore"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/KitGitOKSupport"),
    ],
    targets: [
        .target(
            name: "GitUserSettingsPlugin",
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
            name: "GitUserSettingsPluginTests",
            dependencies: ["GitUserSettingsPlugin"],
            path: "Tests"
        ),
    ]
)
