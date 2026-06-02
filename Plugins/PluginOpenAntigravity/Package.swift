// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenAntigravity",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "PluginOpenAntigravity", targets: ["PluginOpenAntigravity"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginOpenAntigravity",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginOpenAntigravityTests",
            dependencies: ["PluginOpenAntigravity"],
            path: "Tests"
        ),
    ]
)
