// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginSettingsButton",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginSettingsButton",
            targets: ["PluginSettingsButton"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginSettingsButton",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginSettingsButtonTests",
            dependencies: ["PluginSettingsButton"],
            path: "Tests"
        ),
    ]
)
