// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitConflictResolverPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitConflictResolverPlugin", targets: ["GitConflictResolverPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "GitConflictResolverPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitConflictResolverPluginTests",
            dependencies: ["GitConflictResolverPlugin"],
            path: "Tests"
        ),
    ]
)
