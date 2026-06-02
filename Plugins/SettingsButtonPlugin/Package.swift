// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SettingsButtonPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "SettingsButtonPlugin",
            targets: ["SettingsButtonPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "SettingsButtonPlugin",
            dependencies: ["GitOKCoreKit"],
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
