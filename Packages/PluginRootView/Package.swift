// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginRootView",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.library(name: "PluginRootView", targets: ["PluginRootView"])],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/CofficLab/LumiLogging.git", from: "1.0.1"),
        .package(url: "https://github.com/CofficLab/LumiKernel.git", from: "1.1.0"),
        .package(path: "../ProviderRootView"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderCloneRepository"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.12.0"),
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.21.0")
    ],
    targets: [
        .target(
            name: "PluginRootView",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderRootView", package: "ProviderRootView"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderCloneRepository", package: "ProviderCloneRepository"),
                .product(name: "ProviderToolbar", package: "LumiProviders"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
            ],
            path: "Sources/PluginRootView",
            resources: [.process("../../Resources/Localizable.xcstrings")]
        ),
        .testTarget(
            name: "PluginRootViewTests",
            dependencies: [
                "PluginRootView",
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderRootView", package: "ProviderRootView"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderCloneRepository", package: "ProviderCloneRepository"),
            ],
            path: "Tests/PluginRootViewTests"
        ),
    ]
)
