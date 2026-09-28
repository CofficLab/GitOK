// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginCommitToast",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.library(name: "PluginCommitToast", targets: ["PluginCommitToast"])],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(path: "../KitGit"),
        .package(url: "https://github.com/CofficLab/LumiLogging.git", from: "1.0.1"),
        .package(url: "https://github.com/CofficLab/LumiLocalization.git", from: "1.0.0"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderToast"),
        .package(path: "../ProviderDocsView"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.7.0"),
    ],
    targets: [
        .target(
            name: "PluginCommitToast",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "LumiLocalizationKit", package: "LumiLocalization"),
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
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderToast", package: "ProviderToast"),
            ],
            path: "Tests/PluginCommitToastTests"
        ),
    ]
)
