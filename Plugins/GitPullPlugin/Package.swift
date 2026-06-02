// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitPullPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "GitPullPlugin", targets: ["GitPullPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "GitPullPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "GitPullPluginTests",
            dependencies: ["GitPullPlugin"],
            path: "Tests"
        ),
    ]
)
