// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitCoreKit",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "GitCoreKit",
            targets: ["GitCoreKit"]
        ),
    ],
    dependencies: [
        .package(path: "../../../LibGit2Swift"),
    ],
    targets: [
        .target(
            name: "GitCoreKit",
            dependencies: [
                .product(name: "LibGit2Swift", package: "LibGit2Swift"),
            ]
        ),
        .testTarget(
            name: "GitCoreKitTests",
            dependencies: ["GitCoreKit"]
        ),
    ]
)
