// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitCoreKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "GitCoreKit",
            targets: ["GitCoreKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/nookery/LibGit2Swift.git", revision: "34bf2854d385bab71518bfd527a4dd72f010b21d"),
    ],
    targets: [
        .target(
            name: "GitCoreKit",
            dependencies: [
                .product(name: "LibGit2Swift", package: "LibGit2Swift"),
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitCoreKitTests",
            dependencies: ["GitCoreKit"],
            path: "Tests"
        ),
    ]
)
