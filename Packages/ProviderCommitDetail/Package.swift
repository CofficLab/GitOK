// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderCommitDetail",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "ProviderCommitDetail", targets: ["ProviderCommitDetail"]),
    ],
    dependencies: [
        .package(path: "../KitGit"),
    ],
    targets: [
        .target(
            name: "ProviderCommitDetail",
            dependencies: [
                .product(name: "KitGit", package: "KitGit"),
            ],
            path: "Sources/ProviderCommitDetail"
        ),
        .testTarget(
            name: "ProviderCommitDetailTests",
            dependencies: ["ProviderCommitDetail"],
            path: "Tests/ProviderCommitDetailTests"
        ),
    ]
)
