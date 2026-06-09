// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProjectPickerPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ProjectPickerPlugin", targets: ["ProjectPickerPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "ProjectPickerPlugin",
            dependencies: [
                "GitOKCoreKit",
                "ProjectRulesKit",
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
