// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginFileInfo",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginFileInfo",
            targets: ["PluginFileInfo"]
        ),
    ],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/CofficLab/LumiKernel.git", from: "1.1.0"),
        .package(url: "https://github.com/CofficLab/LumiLogging.git", from: "1.0.1"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.13.1"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderWorkspaceScene"),
        .package(path: "../KitGit"),
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.22.0")
    ],
    targets: [
        .target(
            name: "PluginFileInfo",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderStatusBar", package: "LumiProviders"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
            ],
            path: "Sources/PluginFileInfo",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginFileInfoTests",
            dependencies: [
                "PluginFileInfo",
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderStatusBar", package: "LumiProviders"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
            ],
            path: "Tests/PluginFileInfoTests"
        ),
    ]
)
