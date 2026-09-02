// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginCommitDetail",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "PluginCommitDetail", targets: ["PluginCommitDetail"]),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitSuperLog"),
        .package(path: "../LumiUI"),
        .package(path: "../ProviderCommitDetail"),
        .package(path: "../ProviderContentView"),
    ],
    targets: [
        .target(
            name: "PluginCommitDetail",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderCommitDetail", package: "ProviderCommitDetail"),
                .product(name: "ProviderContentView", package: "ProviderContentView"),
            ],
            path: "Sources/PluginCommitDetail"
        ),
        .testTarget(
            name: "PluginCommitDetailTests",
            dependencies: ["PluginCommitDetail"],
            path: "Tests/PluginCommitDetailTests"
        ),
    ]
)
