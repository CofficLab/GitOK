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
        .package(url: "https://github.com/CofficLab/LumiUI.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "ProviderStatusBar",
            dependencies: [
                .product(name: "LumiUI", package: "LumiUI"),
            ],
            path: "Sources/ProviderStatusBar"
        ),
    ]
)
