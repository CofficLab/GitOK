// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderContentView",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ProviderContentView",
            targets: ["ProviderContentView"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
        .package(path: "../KitLocalization"),
        .package(path: "../ProviderWorkspaceScene"),
    ],
    targets: [
        .target(
            name: "ProviderContentView",
            dependencies: [
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
            ],
            path: "Sources/ProviderContentView",
            resources: [.process("../../Resources/Localizable.xcstrings")]
        ),
        .testTarget(
            name: "ProviderContentViewTests",
            dependencies: [
                "ProviderContentView",
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
            ]
        )
    ]
)
