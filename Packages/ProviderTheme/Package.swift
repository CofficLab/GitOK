// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderTheme",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ProviderTheme",
            targets: ["ProviderTheme"]
        ),
    ],
    dependencies: [
        .package(path: "../KitLocalization"),
    ],
    targets: [
        .target(
            name: "ProviderTheme",
            dependencies: [
                .product(name: "KitLocalization", package: "KitLocalization"),
            ],
            path: "Sources/ProviderTheme",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "ProviderThemeTests",
            dependencies: ["ProviderTheme"]
        )
    ]
)
