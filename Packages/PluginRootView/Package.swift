// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginRootView",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.library(name: "GitOKPluginRootView", targets: ["GitOKPluginRootView"])],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/lumi-softworks/LumiLogging.git", from: "1.0.1"),
        .package(url: "https://github.com/lumi-softworks/LumiKernel.git", from: "1.1.0"),
        .package(path: "../ProviderRootView"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderCloneRepository"),
        .package(path: "../ProviderProjectReadme"),
        .package(path: "../ProviderProjectLanguages"),
        .package(url: "https://github.com/lumi-softworks/LumiUI.git", from: "1.13.1"),
        .package(url: "https://github.com/lumi-softworks/LumiProviders.git", from: "1.26.0")
    ],
    targets: [
        .target(
            name: "GitOKPluginRootView",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "GitOKProviderRootView", package: "ProviderRootView"),
                .product(name: "ProviderRootView", package: "LumiProviders"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderCloneRepository", package: "ProviderCloneRepository"),
                .product(name: "ProviderProjectReadme", package: "ProviderProjectReadme"),
                .product(name: "ProviderProjectLanguages", package: "ProviderProjectLanguages"),
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
                "GitOKPluginRootView",
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "GitOKProviderRootView", package: "ProviderRootView"),
                .product(name: "ProviderRootView", package: "LumiProviders"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderCloneRepository", package: "ProviderCloneRepository"),
            ],
            path: "Tests/PluginRootViewTests"
        ),
    ]
)
