// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenTerminal",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginOpenTerminal",
            targets: ["PluginOpenTerminal"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKPluginKit"),
    ],
    targets: [
        .target(
            name: "PluginOpenTerminal",
            dependencies: ["GitOKPluginKit"],
            path: "Sources/PluginOpenTerminal",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginOpenTerminalTests",
            dependencies: ["PluginOpenTerminal"],
            path: "Tests/PluginOpenTerminalTests"
        ),
    ]
)
