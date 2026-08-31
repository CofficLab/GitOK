// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KitGitOKCore",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "KitGitOKCore",
            targets: ["KitGitOKCore"]
        ),
    ],
    dependencies: [
        .package(path: "../GitOKUI"),
        .package(path: "../KernelCore"),
        .package(path: "../ProviderGit"),
        .package(path: "../ProviderNavigation"),
        .package(path: "../ProviderTheme"),
    ],
    targets: [
        .target(
            name: "KitGitOKCore",
            dependencies: [
                "GitOKUI",
                "KernelCore",
                "ProviderGit",
                "ProviderNavigation",
                "ProviderTheme",
            ],
            path: "Sources/KitGitOKCore",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "KitGitOKCoreTests",
            dependencies: ["KitGitOKCore"],
            path: "Tests"
        ),
    ]
)
