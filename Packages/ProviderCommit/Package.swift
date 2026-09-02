// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderCommit",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "ProviderCommit", targets: ["ProviderCommit"]),
    ],
    dependencies: [
        .package(path: "../KitGit"),
    ],
    targets: [
        .target(
            name: "ProviderCommit",
            dependencies: [
                .product(name: "KitGit", package: "KitGit"),
            ],
            path: "Sources/ProviderCommit"
        ),
        .testTarget(
            name: "ProviderCommitTests",
            dependencies: ["ProviderCommit"],
            path: "Tests/ProviderCommitTests"
        ),
    ]
)
