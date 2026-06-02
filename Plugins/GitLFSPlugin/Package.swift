// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitLFSPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "GitLFSPlugin", targets: ["GitLFSPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "GitLFSPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "GitLFSPluginTests",
            dependencies: ["GitLFSPlugin"],
            path: "Tests"
        ),
    ]
)
