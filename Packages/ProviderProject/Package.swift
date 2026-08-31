// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderProject",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProviderProject",
            targets: ["ProviderProject"]
        ),
    ],
    dependencies: [
        .package(path: "../KitGitCore"),
        .package(path: "../KitProjectRules"),
        .package(path: "../KitGitOKCore"),
        .package(path: "../KitGitOKSupport"),
    ],
    targets: [
        .target(
            name: "ProviderProject",
            dependencies: [
                "KitGitCore",
                "KitProjectRules",
                "KitGitOKCore",
                "KitGitOKSupport",
            ],
            path: "Sources"
        ),
    ]
)
