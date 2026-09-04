// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderProjects",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProviderProjects",
            targets: ["ProviderProjects"]
        ),
    ],
    dependencies: [
        .package(path: "../KitGit"),
    ],
    targets: [
        .target(
            name: "ProviderProjects",
            dependencies: [
                .product(name: "KitGit", package: "KitGit"),
            ],
            path: "Sources/ProviderProjects"
        ),
        .testTarget(
            name: "ProviderProjectsTests",
            dependencies: ["ProviderProjects"],
            path: "Tests/ProviderProjectsTests"
        ),
    ]
)
