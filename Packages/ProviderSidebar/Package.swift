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
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.7.0"),
        .package(url: "https://github.com/CofficLab/LumiLocalization.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ProviderSidebar",
            dependencies: [
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "LumiLocalizationKit", package: "LumiLocalization"),
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
