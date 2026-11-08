// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderWorkspaceScene",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "ProviderWorkspaceScene",
            targets: ["ProviderWorkspaceScene"]
        ),
    ],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
    ],
    targets: [
        .target(
            name: "ProviderWorkspaceScene",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
            ],
            path: "Sources/ProviderWorkspaceScene",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "ProviderWorkspaceSceneTests",
            dependencies: ["ProviderWorkspaceScene"]
        ),
    ]
)
