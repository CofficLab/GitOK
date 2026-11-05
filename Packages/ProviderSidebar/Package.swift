// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderSidebar",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProviderSidebar",
            targets: ["ProviderSidebar"]
        ),
    ],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.11.1"),
    ],
    targets: [
        .target(
            name: "ProviderSidebar",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "LumiUI", package: "LumiUI"),
            ],
            path: "Sources/ProviderSidebar",
            resources: [
                .process("../../Resources/Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ProviderSidebarTests",
            dependencies: [
                "ProviderSidebar",
            ],
            path: "Tests/ProviderSidebarTests"
        ),
    ]
)
