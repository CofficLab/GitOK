// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginProjects",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginProjects",
            targets: ["PluginProjects"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.1.0"),
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(path: "../KitGit"),
        .package(url: "https://github.com/CofficLab/LumiLocalization.git", from: "1.0.0"),
        .package(url: "https://github.com/CofficLab/LumiLogging.git", from: "1.0.1"),
        .package(path: "../ProviderActivity"),
        .package(path: "../ProviderCloneRepository"),
        .package(path: "../ProviderGit"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.7.0"),
        .package(path: "../ProviderProjects"),
        .package(url: "https://github.com/CofficLab/LumiSettings.git", from: "1.0.1"),
        .package(path: "../ProviderSidebar"),
        .package(path: "../ProviderToast"),
        .package(path: "../ProviderToolbar"),
        .package(path: "../ProviderDocsView"),
    ],
    targets: [
        .target(
            name: "PluginProjects",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "LumiLocalizationKit", package: "LumiLocalization"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderActivity", package: "ProviderActivity"),
                .product(name: "ProviderCloneRepository", package: "ProviderCloneRepository"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderSettingView", package: "LumiSettings"),
                .product(name: "ProviderSidebar", package: "ProviderSidebar"),
                .product(name: "ProviderStorage", package: "LumiProviders"),
                .product(name: "ProviderToast", package: "ProviderToast"),
                .product(name: "ProviderToolbar", package: "ProviderToolbar"),
                .product(name: "ProviderDocsView", package: "ProviderDocsView"),
            ],
            path: "Sources/PluginProjects",
            resources: [.process("../../Resources/Localizable.xcstrings")]
        ),
        .testTarget(
            name: "PluginProjectsTests",
            dependencies: [
                "PluginProjects",
                .product(name: "ProviderProjects", package: "ProviderProjects"),
            ],
            path: "Tests/PluginProjectsTests"
        ),
    ]
)
