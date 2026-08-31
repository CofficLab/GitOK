// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GitOKAppCore",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "GitOKAppCore",
            targets: ["GitOKAppCore"]
        ),
    ],
    dependencies: [
        .package(path: "../KitGitCore"),
        .package(path: "../KitGitOKCore"),
        .package(path: "../KitGitOKSupport"),
        .package(path: "../KitProjectRules"),
        .package(path: "../KitProjectSupport"),
        .package(path: "../GitOKUI"),
        .package(path: "../ProviderProject"),
    ],
    targets: [
        .target(
            name: "GitOKAppCore",
            dependencies: [
                "KitGitCore",
                "KitGitOKCore",
                "GitOKUI",
                "KitGitOKSupport",
                "KitProjectRules",
                "KitProjectSupport",
                "ProviderProject",
            ],
            path: "Sources/GitOKAppCore",
            resources: [
                .process("Localizable.xcstrings")
            ]
        ),
    ]
)
