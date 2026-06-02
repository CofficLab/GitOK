// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginConflictResolver",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginConflictResolver", targets: ["PluginConflictResolver"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginConflictResolver",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginConflictResolverTests",
            dependencies: ["PluginConflictResolver"],
            path: "Tests"
        ),
    ]
)
