// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitNetworkSettings",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginGitNetworkSettings", targets: ["GitNetworkSettingsPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitCore"),
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/GitOKAppCore"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/KitGitOKSupport"),
    ],
    targets: [
        .target(
            name: "GitNetworkSettingsPlugin",
            dependencies: [
                "KitGitCore",
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
            name: "GitNetworkSettingsPluginTests",
            dependencies: ["GitNetworkSettingsPlugin"],
            path: "Tests"
        ),
    ]
)
