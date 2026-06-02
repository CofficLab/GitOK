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
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginOpenVSCode",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginOpenVSCodeTests",
            dependencies: ["PluginOpenVSCode"],
            path: "Tests"
        ),
    ]
)
