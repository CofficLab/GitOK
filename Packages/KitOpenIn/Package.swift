// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KitOpenIn",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "KitOpenIn",
            targets: ["KitOpenIn"]
        ),
    ],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/CofficLab/LumiKernel.git", from: "1.1.0"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.12.0"),
        .package(path: "../ProviderProjects"),
        .package(path: "../KitGit"),
        .package(url: "https://github.com/nookery/LibGit2Swift.git", exact: "1.0.7"),
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.21.0")
    ],
    targets: [
        .target(
            name: "KitOpenIn",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderToolbar", package: "LumiProviders"),
                .product(name: "LibGit2Swift", package: "libgit2swift"),
            ],
            path: "Sources/KitOpenIn",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "KitOpenInTests",
            dependencies: [
                "KitOpenIn",
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderToolbar", package: "LumiProviders"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
            ],
            path: "Tests/KitOpenInTests"
        ),
    ]
)
