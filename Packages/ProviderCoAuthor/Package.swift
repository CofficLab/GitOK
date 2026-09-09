// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderCoAuthor",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProviderCoAuthor",
            targets: ["ProviderCoAuthor"]
        ),
    ],
    targets: [
        .target(
            name: "ProviderCoAuthor",
            path: "Sources/ProviderCoAuthor"
        ),
        .testTarget(
            name: "ProviderCoAuthorTests",
            dependencies: ["ProviderCoAuthor"],
            path: "Tests/ProviderCoAuthorTests"
        ),
    ]
)
