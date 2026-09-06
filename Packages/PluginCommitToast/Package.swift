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
        .package(path: "../KitLocalization"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderToast"),
        .package(path: "../ProviderDocsView"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
    ],
    targets: [
        .target(
            name: "PluginCommitToast",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                "KitSuperLog",
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderToast", package: "ProviderToast"),
                .product(name: "ProviderDocsView", package: "ProviderDocsView"),
                .product(name: "LumiUI", package: "LumiUI"),
            ],
            path: "Sources/PluginCommitToast",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginCommitToastTests",
            dependencies: [
                "PluginCommitToast",
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderToast", package: "ProviderToast"),
            ],
            path: "Tests/PluginCommitToastTests"
        ),
    ]
)
