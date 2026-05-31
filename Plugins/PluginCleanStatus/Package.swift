// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginCleanStatus",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginCleanStatus", targets: ["PluginCleanStatus"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKPluginKit"),
    ],
    targets: [
        .target(
            name: "PluginCleanStatus",
            dependencies: [
                "GitCoreKit",
                "GitOKPluginKit",
            ],
            path: "Sources/PluginCleanStatus",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginCleanStatusTests",
            dependencies: ["PluginCleanStatus"],
            path: "Tests"
        ),
    ]
)
