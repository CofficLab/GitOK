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
        .package(path: "../KitLocalization"),
    ],
    targets: [
        .target(
            name: "ProviderWorkspaceScene",
            dependencies: [
                .product(name: "KitLocalization", package: "KitLocalization"),
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
