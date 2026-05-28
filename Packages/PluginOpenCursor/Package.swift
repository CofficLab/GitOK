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
        .package(path: "../GitOKPluginKit"),
    ],
    targets: [
        .target(
            name: "PluginOpenCursor",
            dependencies: ["GitOKPluginKit"],
            path: "Sources/PluginOpenCursor",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginOpenCursorTests",
            dependencies: ["PluginOpenCursor"],
            path: "Tests/PluginOpenCursorTests"
        ),
    ]
)
