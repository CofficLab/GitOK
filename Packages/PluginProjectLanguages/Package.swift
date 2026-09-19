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
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitSuperLog"),
        .package(path: "../ProviderProjectLanguages"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderGit"),
        .package(path: "../ProviderGitRepositoryWatch"),
        .package(
            url: "https://github.com/nookery/LibGit2Swift.git",
            revision: "3d6aca124991b9f4282c589991bcdb0264d29777"
        ),
    ],
    targets: [
        .target(
            name: "PluginProjectLanguages",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "ProviderProjectLanguages", package: "ProviderProjectLanguages"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderGitRepositoryWatch", package: "ProviderGitRepositoryWatch"),
                .product(name: "LibGit2Swift", package: "libgit2swift"),
            ],
            path: "Sources/PluginProjectLanguages"
        ),
        .testTarget(
            name: "PluginProjectLanguagesTests",
            dependencies: ["PluginProjectLanguages"],
            path: "Tests/PluginProjectLanguagesTests"
        ),
    ]
)
