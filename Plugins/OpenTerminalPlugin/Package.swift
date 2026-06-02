// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenTerminalPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "OpenTerminalPlugin",
            targets: ["OpenTerminalPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "OpenTerminalPlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "OpenTerminalPluginTests",
            dependencies: ["OpenTerminalPlugin"],
            path: "Tests"
        ),
    ]
)
