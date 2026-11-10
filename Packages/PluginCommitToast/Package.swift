// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginCommitToast",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.library(name: "PluginCommitToast", targets: ["PluginCommitToast"])],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/CofficLab/LumiKernel.git", from: "1.1.0"),
        .package(path: "../KitGit"),
        .package(url: "https://github.com/CofficLab/LumiLogging.git", from: "1.0.1"),
        .package(path: "../ProviderProjects"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.12.0"),
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.21.0")
    ],
    targets: [
        .target(
            name: "PluginCommitToast",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderToast", package: "LumiProviders"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
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
                .product(name: "ProviderToast", package: "LumiProviders"),
            ],
            path: "Tests/PluginCommitToastTests"
        ),
    ]
)
