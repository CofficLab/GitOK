// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginCloneRepository",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginCloneRepository",
            targets: ["PluginCloneRepository"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitSuperLog"),
        .package(path: "../KitLocalization"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", branch: "main"),
        .package(path: "../ProviderActivity"),
        .package(path: "../ProviderCloneRepository"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderToast"),
    ],
    targets: [
        .target(
            name: "PluginCloneRepository",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderActivity", package: "ProviderActivity"),
                .product(name: "ProviderCloneRepository", package: "ProviderCloneRepository"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderToast", package: "ProviderToast"),
            ],
            path: "Sources/PluginCloneRepository",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginCloneRepositoryTests",
            dependencies: ["PluginCloneRepository"],
            path: "Tests/PluginCloneRepositoryTests"
        ),
    ]
)
