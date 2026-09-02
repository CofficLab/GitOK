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
        .package(path: "../LumiUI"),
    ],
    targets: [
        .target(
            name: "ProviderSidebar",
            dependencies: [
                .product(name: "LumiUI", package: "LumiUI"),
            ],
            path: "Sources/ProviderSidebar"
        ),
        .testTarget(
            name: "ProviderSidebarTests",
            dependencies: ["ProviderSidebar"],
            path: "Tests/ProviderSidebarTests"
        ),
    ]
)
