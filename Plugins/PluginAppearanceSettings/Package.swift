// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginAppearanceSettings",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginAppearanceSettings", targets: ["AppearanceSettingsPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/GitOKAppCore"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/KitGitOKSupport"),
    ],
    targets: [
        .target(
            name: "AppearanceSettingsPlugin",
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
            name: "AppearanceSettingsPluginTests",
            dependencies: ["AppearanceSettingsPlugin"],
            path: "Tests"
        ),
    ]
)
