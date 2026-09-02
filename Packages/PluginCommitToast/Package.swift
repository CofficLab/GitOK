// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginCommitToast",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.library(name: "PluginCommitToast", targets: ["PluginCommitToast"])],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitSuperLog"),
        .package(path: "../ProviderCommit"),
        .package(path: "../ProviderToast"),
    ],
    targets: [
        .target(
            name: "PluginCommitToast",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                "KitSuperLog",
                .product(name: "ProviderCommit", package: "ProviderCommit"),
                .product(name: "ProviderToast", package: "ProviderToast"),
            ],
            path: "Sources/PluginCommitToast"
        ),
        .testTarget(
            name: "PluginCommitToastTests",
            dependencies: [
                "PluginCommitToast",
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "ProviderCommit", package: "ProviderCommit"),
                .product(name: "ProviderToast", package: "ProviderToast"),
            ],
            path: "Tests/PluginCommitToastTests"
        ),
    ]
)
