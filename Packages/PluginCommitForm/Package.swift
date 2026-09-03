// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginCommitForm",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginCommitForm",
            targets: ["PluginCommitForm"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", branch: "main"),
        .package(path: "../ProviderCommitForm"),
        .package(path: "../ProviderProjects"),
    ],
    targets: [
        .target(
            name: "PluginCommitForm",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderCommitForm", package: "ProviderCommitForm"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
            ],
            path: "Sources/PluginCommitForm"
        ),
        .testTarget(
            name: "PluginCommitFormTests",
            dependencies: ["PluginCommitForm"],
            path: "Tests/PluginCommitFormTests"
        ),
    ]
)
