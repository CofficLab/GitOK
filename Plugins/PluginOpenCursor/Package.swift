// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenCursor",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginOpenCursor",
            targets: ["PluginOpenCursor"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginOpenCursor",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginOpenCursorTests",
            dependencies: ["PluginOpenCursor"],
            path: "Tests"
        ),
    ]
)
