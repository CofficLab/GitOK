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
        .package(path: "../KitLocalization"),
    ],
    targets: [
        .target(
            name: "ProviderCommitForm",
            dependencies: [
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitLocalization", package: "KitLocalization"),
            ],
            path: "Sources/ProviderCommitForm",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "ProviderCommitFormTests",
            dependencies: ["ProviderCommitForm"],
            path: "Tests/ProviderCommitFormTests"
        ),
    ]
)
