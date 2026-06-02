// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SmartMergePlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "SmartMergePlugin", targets: ["SmartMergePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "SmartMergePlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SmartMergePluginTests",
            dependencies: ["SmartMergePlugin"],
            path: "Tests"
        ),
    ]
)
