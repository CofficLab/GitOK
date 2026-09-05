// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderStatusBar",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProviderStatusBar",
            targets: ["ProviderStatusBar"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
        .package(path: "../ProviderWorkspaceScene"),
    ],
    targets: [
        .target(
            name: "ProviderStatusBar",
            dependencies: [
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
            ],
            path: "Sources/ProviderStatusBar"
        ),
        .testTarget(
            name: "ProviderStatusBarTests",
            dependencies: [
                "ProviderStatusBar",
                .product(name: "ProviderWorkspaceScene", package: "ProviderWorkspaceScene"),
            ]
        ),
    ]
)
