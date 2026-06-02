// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginProjectPicker",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginProjectPicker", targets: ["PluginProjectPicker"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "PluginProjectPicker",
            dependencies: [
                "GitOKCoreKit",
                "ProjectRulesKit",
            ],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginProjectPickerTests",
            dependencies: ["PluginProjectPicker"],
            path: "Tests"
        ),
    ]
)
