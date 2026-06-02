// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CleanStatusPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "CleanStatusPlugin", targets: ["CleanStatusPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "CleanStatusPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "CleanStatusPluginTests",
            dependencies: ["CleanStatusPlugin"],
            path: "Tests"
        ),
    ]
)
