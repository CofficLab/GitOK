// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginCloneRepository",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "PluginCloneRepository",
            targets: ["PluginCloneRepository"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitGit"),
        .package(path: "../KitLocalization"),
        .package(path: "../KitSuperLog"),
        .package(path: "../ProviderActivity"),
        .package(path: "../ProviderCloneRepository"),
        .package(path: "../ProviderContentView"),
        .package(path: "../ProviderGit"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderStorage"),
        .package(path: "../ProviderToast"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
    ],
    targets: [
        .target(
            name: "PluginCloneRepository",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderActivity", package: "ProviderActivity"),
                .product(name: "ProviderCloneRepository", package: "ProviderCloneRepository"),
                .product(name: "ProviderContentView", package: "ProviderContentView"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderStorage", package: "ProviderStorage"),
                .product(name: "ProviderToast", package: "ProviderToast"),
            ],
            path: "Sources/PluginCloneRepository",
            resources: [.process("../../Resources/Localizable.xcstrings")]
        ),
        .testTarget(
            name: "PluginCloneRepositoryTests",
            dependencies: [
                "PluginCloneRepository",
                .product(name: "ProviderCloneRepository", package: "ProviderCloneRepository"),
            ],
            path: "Tests/PluginCloneRepositoryTests"
        ),
    ]
)
