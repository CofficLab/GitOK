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
        .package(url: "https://github.com/CofficLab/LumiLocalization.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ProviderWorkspaceScene",
            dependencies: [
                .product(name: "LumiLocalizationKit", package: "LumiLocalization"),
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
