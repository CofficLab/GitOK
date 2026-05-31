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
        .package(path: "../../Packages/GitOKPluginKit"),
    ],
    targets: [
        .target(
            name: "PluginOpenAntigravity",
            dependencies: ["GitOKPluginKit"],
            path: "Sources/PluginOpenAntigravity",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginOpenAntigravityTests",
            dependencies: ["PluginOpenAntigravity"],
            path: "Tests/PluginOpenAntigravityTests"
        ),
    ]
)
