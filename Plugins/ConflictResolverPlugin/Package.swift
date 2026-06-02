// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ConflictResolverPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ConflictResolverPlugin", targets: ["ConflictResolverPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ConflictResolverPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ConflictResolverPluginTests",
            dependencies: ["ConflictResolverPlugin"],
            path: "Tests"
        ),
    ]
)
