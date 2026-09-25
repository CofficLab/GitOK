// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderGit",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProviderGit",
            targets: ["ProviderGit"]
        ),
    ],
    dependencies: [
        .package(path: "../KitGit"),
    ],
    targets: [
        .target(
            name: "ProviderGit",
            dependencies: [
                .product(name: "KitGit", package: "KitGit"),
            ],
            path: "Sources/ProviderGit"
        ),
        .testTarget(
            name: "ProviderGitTests",
            dependencies: [
                "ProviderGit",
                .product(name: "KitGit", package: "KitGit"),
            ],
            path: "Tests/ProviderGitTests"
        ),
    ]
)
