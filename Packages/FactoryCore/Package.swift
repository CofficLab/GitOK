// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FactoryCore",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "FactoryCore",
            targets: ["FactoryCore"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../GitOKAppCore"),
        .package(path: "../KitGitOKCore"),
        .package(path: "../GitOKUI"),
        .package(path: "../KitGitOKSupport"),
        .package(path: "../MagicAlert"),
        .package(path: "../ProviderProject"),
        .package(path: "../KitProjectSupport"),
        .package(path: "../KitGitCore"),
    ],
    targets: [
        .target(
            name: "FactoryCore",
            dependencies: [
                "KernelCore",
                "GitOKAppCore",
                "KitGitOKCore",
                "GitOKUI",
                "KitGitOKSupport",
                "MagicAlert",
                "ProviderProject",
                "KitProjectSupport",
                "KitGitCore",
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "FactoryCoreTests",
            dependencies: ["FactoryCore"],
            path: "Tests"
        ),
    ]
)
