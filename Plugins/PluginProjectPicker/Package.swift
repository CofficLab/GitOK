// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginProjectPicker",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginProjectPicker", targets: ["ProjectPickerPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/KitProjectRules"),
    ],
    targets: [
        .target(
            name: "ProjectPickerPlugin",
            dependencies: [
                "KitGitOKCore",
                "KitProjectRules",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "ProjectPickerPluginTests",
            dependencies: ["ProjectPickerPlugin"],
            path: "Tests"
        ),
    ]
)
