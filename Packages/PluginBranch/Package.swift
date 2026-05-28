// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginBranch",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginBranch", targets: ["PluginBranch"]),
    ],
    dependencies: [
        .package(path: "../GitOKPluginKit"),
    ],
    targets: [
        .target(
            name: "PluginBranch",
            dependencies: ["GitOKPluginKit"],
            path: "Sources/PluginBranch",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginBranchTests",
            dependencies: ["PluginBranch"],
            path: "Tests/PluginBranchTests"
        ),
    ]
)
