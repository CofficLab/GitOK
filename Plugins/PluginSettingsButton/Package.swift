// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginSettingsButton",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginSettingsButton",
            targets: ["SettingsButtonPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "SettingsButtonPlugin",
            dependencies: ["KitGitOKCore"],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "SettingsButtonPluginTests",
            dependencies: ["SettingsButtonPlugin"],
            path: "Tests"
        ),
    ]
)
