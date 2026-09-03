// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderCommitForm",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProviderCommitForm",
            targets: ["ProviderCommitForm"]
        ),
    ],
    dependencies: [
        .package(path: "../KitGit"),
    ],
    targets: [
        .target(
            name: "ProviderCommitForm",
            dependencies: [
                .product(name: "KitGit", package: "KitGit"),
            ],
            path: "Sources/ProviderCommitForm"
        ),
        .testTarget(
            name: "ProviderCommitFormTests",
            dependencies: ["ProviderCommitForm"],
            path: "Tests/ProviderCommitFormTests"
        ),
    ]
)
