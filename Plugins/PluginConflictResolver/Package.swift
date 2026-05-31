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
        .package(path: "../../Packages/GitOKPluginKit"),
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/ProjectSupportKit"),
    ],
    targets: [
        .target(
            name: "PluginConflictResolver",
            dependencies: ["GitOKPluginKit", "GitCoreKit", "GitOKUI", "ProjectSupportKit"],
            path: "Sources/PluginConflictResolver",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginConflictResolverTests",
            dependencies: ["PluginConflictResolver"],
            path: "Tests/PluginConflictResolverTests"
        ),
    ]
)
