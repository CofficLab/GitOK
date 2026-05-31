// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenVSCode",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginOpenVSCode",
            targets: ["PluginOpenVSCode"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKPluginKit"),
    ],
    targets: [
        .target(
            name: "PluginOpenVSCode",
            dependencies: ["GitOKPluginKit"],
            path: "Sources/PluginOpenVSCode",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginOpenVSCodeTests",
            dependencies: ["PluginOpenVSCode"],
            path: "Tests/PluginOpenVSCodeTests"
        ),
    ]
)
