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
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(path: "../KitLocalization"),
        .package(path: "../ProviderDocsView"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.7.0"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderToolbar"),
        .package(
            url: "https://github.com/nookery/LibGit2Swift.git",
            revision: "8a80b9e33c7e45a3123d0b98c9e0f29e70b30433"
        ),
    ],
    targets: [
        .target(
            name: "KitOpenIn",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "ProviderDocsView", package: "ProviderDocsView"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderToolbar", package: "ProviderToolbar"),
                .product(name: "LibGit2Swift", package: "libgit2swift"),
            ],
            path: "Sources/KitOpenIn",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "KitOpenInTests",
            dependencies: ["KitOpenIn"],
            path: "Tests/KitOpenInTests"
        ),
    ]
)
