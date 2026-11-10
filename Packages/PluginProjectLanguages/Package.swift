// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginProjectLanguages",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginProjectLanguages", targets: ["PluginProjectLanguages"]),
    ],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/CofficLab/LumiKernel.git", from: "1.1.0"),
        .package(path: "../KitGit"),
        .package(url: "https://github.com/CofficLab/LumiLogging.git", from: "1.0.1"),
        .package(path: "../ProviderProjectLanguages"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderGit"),
        .package(path: "../ProviderGitRepositoryWatch"),
        .package(url: "https://github.com/nookery/LibGit2Swift.git", exact: "1.0.4"),
    ],
    targets: [
        .target(
            name: "PluginProjectLanguages",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "ProviderProjectLanguages", package: "ProviderProjectLanguages"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
                .product(name: "LibGit2Swift", package: "libgit2swift"),
            ],
            path: "Sources/PluginProjectLanguages",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginProjectLanguagesTests",
            dependencies: [
                "PluginProjectLanguages",
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "ProviderProjectLanguages", package: "ProviderProjectLanguages"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
            ],
            path: "Tests/PluginProjectLanguagesTests"
        ),
    ]
)
