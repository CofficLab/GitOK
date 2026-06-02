// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitSyncPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "GitSyncPlugin", targets: ["GitSyncPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "GitSyncPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "GitSyncPluginTests",
            dependencies: ["GitSyncPlugin"],
            path: "Tests"
        ),
    ]
)
