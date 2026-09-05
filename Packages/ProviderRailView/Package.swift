// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderRailView",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ProviderRailView",
            targets: ["ProviderRailView"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
        .package(path: "../ProviderWorkspaceScene"),
    ],
    targets: [
        .target(
            name: "ProviderRailView",
            dependencies: [
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
            ],
            path: "Sources/ProviderRailView"
        ),
        .testTarget(
            name: "ProviderRailViewTests",
            dependencies: [
                "ProviderRailView",
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
            ]
        )
    ]
)
