// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenKiro",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "PluginOpenKiro", targets: ["PluginOpenKiro"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginOpenKiro",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginOpenKiroTests",
            dependencies: ["PluginOpenKiro"],
            path: "Tests"
        ),
    ]
)
