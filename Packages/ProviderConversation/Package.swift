// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderConversation",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ProviderConversation",
            targets: ["ProviderConversation"]
        ),
    ],
    dependencies: [
        .package(path: "../KitSuperLog"),
        .package(path: "../KitLocalization"),
    ],
    targets: [
        .target(
            name: "ProviderConversation",
            dependencies: [
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "KitLocalization", package: "KitLocalization"),
            ],
            path: "Sources/ProviderConversation",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "ProviderConversationTests",
            dependencies: ["ProviderConversation"]
        )
    ]
)
